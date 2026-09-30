import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart';
import '../models/user.dart';
import '../utils/login_type.dart';

ValueNotifier<UserService> userService = ValueNotifier(UserService());

class UserServiceException implements Exception {
  final String message;
  const UserServiceException(this.message);

  @override
  String toString() => message;
}

class UserService {
  static const _accessTokenKey = 'dummyjson_access_token';
  static const _refreshTokenKey = 'dummyjson_refresh_token';
  static const _savedUserKey = 'dummyjson_user';
  static const _profileKeyPrefix = 'firebase_profile_';

  /// Chat directory entries already written during this run.
  static final _syncedToDirectory = <String>{};

  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;

  User? get currentUser => firebaseAuth.currentUser;

  Stream<User?> get authStateChanges => firebaseAuth.authStateChanges();

  // ---- Firebase account actions ----

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    return await firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<UserCredential> createAccount({
    required String email,
    required String password,
  }) async {
    return await firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await firebaseAuth.signOut();
  }

  Future<void> updateUsername({required String username}) async {
    await currentUser!.updateDisplayName(username);
    // Profile reads are served from the device now, so refresh it here.
    await currentUser!.reload();
  }

  Future<void> deleteAccount({
    required String email,
    required String password,
  }) async {
    AuthCredential credential = EmailAuthProvider.credential(
      email: email,
      password: password,
    );

    await currentUser!.reauthenticateWithCredential(credential);
    await currentUser!.delete();
    await firebaseAuth.signOut();
  }

  Future<void> resetPasswordFromCurrentPassword({
    required String currentPassword,
    required String newPassword,
    required String email,
  }) async {
    AuthCredential credential = EmailAuthProvider.credential(
      email: email,
      password: currentPassword,
    );
    await currentUser!.reauthenticateWithCredential(credential);
    await currentUser!.updatePassword(newPassword);
  }

  // ---- DummyJSON login (token based) ----

  /// Enhancement 2: logs in with DummyJSON, then saves the user data on the device.
  Future<Map<String, dynamic>> loginUser(String username, String password) async {
    final response = await http.post(
      Uri.parse('$host/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'password': password,
        'expiresInMins': 30,
      }),
    );
    final body = _decode(response.body);
    if (response.statusCode != 200) {
      throw UserServiceException(body['message']?.toString() ?? 'Login failed');
    }
    // Only one kind of session at a time.
    await firebaseAuth.signOut();
    await saveUserData(body);
    return body;
  }

  /// Enhancement 2: saves the login response (tokens and user fields) to
  /// SharedPreferences, so the user stays signed in and the profile and cart
  /// can be built from it later, even offline.
  Future<void> saveUserData(Map<String, dynamic> userData) async {
    await _saveTokens(userData);
    await _saveProfileFields(userData);
  }

  // ---- Session helpers shared by both login types ----

  /// Which kind of account is signed in, or null when logged out.
  Future<LoginType?> getLoginType() async {
    // authStateChanges emits once Firebase has restored any saved session.
    final firebaseUser = await firebaseAuth.authStateChanges().first;
    if (firebaseUser != null) return LoginType.firebase;
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString(_accessTokenKey) != null) return LoginType.dummyJson;
    return null;
  }

  /// Enhancement 1: the splash screen asks this to decide where to go.
  Future<bool> isLoggedIn() async => await getLoginType() != null;

  /// Clears the Firebase session and the saved DummyJSON tokens and user data.
  /// Carts saved per user are kept, so they are there at the next login.
  Future<void> logout() async {
    await firebaseAuth.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_savedUserKey);
  }

  /// The signed-in user, from the data saved on the device. Pass [refresh] to
  /// reload it from the server (pull to refresh).
  Future<UserProfile> getUserData({bool refresh = false}) async {
    final UserProfile profile;
    switch (await getLoginType()) {
      case LoginType.firebase:
        profile = await _getFirebaseProfile(refresh: refresh);
      case LoginType.dummyJson:
        profile = await _getDummyJsonProfile(refresh: refresh);
      case null:
        throw const UserServiceException('You are not logged in.');
    }
    _addToChatDirectory(profile);
    return profile;
  }

  // ---- Chat directory (Firestore "Users") ----

  /// Public directory entry the chat list reads. Merged so reruns are safe.
  Future<void> syncUserToFirestore({
    required String uid,
    required String? email,
    String? firstName,
    String? lastName,
    String? username,
  }) async {
    await FirebaseFirestore.instance.collection('Users').doc(uid).set({
      'uid': uid,
      'email': email ?? '',
      'firstName': ?firstName,
      'lastName': ?lastName,
      'username': ?username,
    }, SetOptions(merge: true));
  }

  /// Puts the user in the chat directory once per run, for either login type,
  /// so both kinds of account can be found and messaged. Never blocks the caller.
  void _addToChatDirectory(UserProfile profile) {
    if (!_syncedToDirectory.add(profile.chatId)) return;
    syncUserToFirestore(
      uid: profile.chatId,
      email: profile.email,
      firstName: profile.firstName,
      lastName: profile.lastName,
      username: profile.username,
    ).catchError((_) => _syncedToDirectory.remove(profile.chatId));
  }

  // ---- Firebase profile: Auth holds email/username, the rest is kept locally ----

  Future<void> saveFirebaseProfileDetails({
    required String uid,
    required String firstName,
    required String lastName,
    required int age,
    required String contactNo,
    String? gender,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '$_profileKeyPrefix$uid',
      jsonEncode({
        'firstName': firstName,
        'lastName': lastName,
        'age': age,
        'contactNo': contactNo,
        'gender': ?gender,
      }),
    );
  }

  Future<void> clearFirebaseProfileDetails(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_profileKeyPrefix$uid');
  }

  Future<UserProfile> _getFirebaseProfile({bool refresh = false}) async {
    // Firebase keeps the signed-in user on the device, so a failed reload
    // (for example while offline) is not an error.
    if (refresh) {
      try {
        await currentUser!.reload();
      } catch (_) {}
    }
    final user = currentUser!;
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('$_profileKeyPrefix${user.uid}');
    final details = saved == null ? <String, dynamic>{} : _decode(saved);

    return UserProfile(
      loginType: LoginType.firebase,
      id: user.uid,
      firstName: details['firstName'],
      lastName: details['lastName'],
      age: details['age'],
      phone: details['contactNo'],
      gender: details['gender'],
      username: user.displayName,
      email: user.email,
      imageUrl: user.photoURL,
      emailVerified: user.emailVerified,
      createdAt: user.metadata.creationTime,
    );
  }

  // ---- DummyJSON profile: the saved copy, or /auth/me when there is none ----

  Future<UserProfile> _getDummyJsonProfile({bool refresh = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_savedUserKey);
    if (saved != null && !refresh) {
      return UserProfile.fromDummyJson(_decode(saved));
    }

    var response = await _fetchMe();
    if (response.statusCode == 401 || response.statusCode == 403) {
      await _refreshTokens();
      response = await _fetchMe();
    }
    if (response.statusCode != 200) {
      throw const UserServiceException('Could not load your profile.');
    }
    final body = _decode(response.body);
    await _saveProfileFields(body);
    return UserProfile.fromDummyJson(body);
  }

  Future<http.Response> _fetchMe() async {
    final prefs = await SharedPreferences.getInstance();
    return http.get(
      Uri.parse('$host/auth/me'),
      headers: {'Authorization': 'Bearer ${prefs.getString(_accessTokenKey)}'},
    );
  }

  Future<void> _refreshTokens() async {
    final prefs = await SharedPreferences.getInstance();
    final response = await http.post(
      Uri.parse('$host/auth/refresh'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'refreshToken': prefs.getString(_refreshTokenKey),
        'expiresInMins': 30,
      }),
    );
    if (response.statusCode != 200) {
      await logout();
      throw const UserServiceException('Session expired. Please log in again.');
    }
    await _saveTokens(_decode(response.body));
  }

  Future<void> _saveTokens(Map<String, dynamic> body) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessTokenKey, body['accessToken'] ?? body['token']);
    await prefs.setString(_refreshTokenKey, body['refreshToken']);
  }

  /// Keeps only the user fields, under the same keys the API uses.
  Future<void> _saveProfileFields(Map<String, dynamic> body) async {
    const fields = [
      'id', 'username', 'email', 'firstName', 'lastName',
      'gender', 'image', 'age', 'phone', 'role',
    ];
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _savedUserKey,
      jsonEncode({
        for (final key in fields)
          if (body[key] != null) key: body[key],
      }),
    );
  }

  Map<String, dynamic> _decode(String source) {
    try {
      return jsonDecode(source) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }
}
