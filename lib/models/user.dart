import '../utils/login_type.dart';

// Enhancement 3: our own user model. It is built from a DummyJSON response, from
// the copy of it saved on the device, or from a Firebase account, so every
// screen reads the same fields whichever way the user signed in.
// (Named UserProfile because "User" is already a FirebaseAuth class.)
class UserProfile {
  final LoginType loginType;
  final String id;
  final String? firstName;
  final String? lastName;
  final String? username;
  final String? email;
  final String? phone;
  final String? gender;
  final String? role;
  final String? imageUrl;
  final int? age;
  final bool? emailVerified;
  final DateTime? createdAt;

  const UserProfile({
    required this.loginType,
    required this.id,
    this.firstName,
    this.lastName,
    this.username,
    this.email,
    this.phone,
    this.gender,
    this.role,
    this.imageUrl,
    this.age,
    this.emailVerified,
    this.createdAt,
  });

  UserProfile copyWith({String? username}) {
    return UserProfile(
      loginType: loginType,
      id: id,
      firstName: firstName,
      lastName: lastName,
      username: username ?? this.username,
      email: email,
      phone: phone,
      gender: gender,
      role: role,
      imageUrl: imageUrl,
      age: age,
      emailVerified: emailVerified,
      createdAt: createdAt,
    );
  }

  String get fullName =>
      [firstName, lastName].where((s) => s != null && s.isNotEmpty).join(' ');

  /// The name to show for this user, from most to least specific.
  String get displayName {
    if (fullName.isNotEmpty) return fullName;
    if (username != null && username!.isNotEmpty) return username!;
    return email ?? 'User';
  }

  /// Id used for this user in the chat directory. Prefixed for DummyJSON so it
  /// can never collide with a Firebase uid.
  String get chatId => loginType == LoginType.dummyJson ? 'dummyjson_$id' : id;

  /// Numeric DummyJSON user id used for the cart (DummyJSON users are 1-208).
  /// A DummyJSON login uses its own id. A Firebase uid is mapped to a stable
  /// number in the same range, so the same account always gets the same one.
  int get cartUserId {
    if (loginType == LoginType.dummyJson) return int.tryParse(id) ?? 1;
    return id.codeUnits.fold<int>(0, (h, c) => (h * 31 + c) % 208) + 1;
  }

  /// Also reads the copy saved on the device, which uses the same keys.
  factory UserProfile.fromDummyJson(Map<String, dynamic> json) {
    return UserProfile(
      loginType: LoginType.dummyJson,
      id: '${json['id']}',
      firstName: json['firstName'],
      lastName: json['lastName'],
      username: json['username'],
      email: json['email'],
      phone: json['phone'],
      gender: json['gender'],
      role: json['role'],
      imageUrl: json['image'],
      age: json['age'],
    );
  }
}
