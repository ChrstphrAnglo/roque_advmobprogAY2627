import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'chat_detail_screen.dart';
import '../services/chat_service.dart';
import '../services/user_service.dart';
import '../widgets/custom_text.dart';
import '../widgets/user_avatar.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _searchController = TextEditingController();
  final _chatService = ChatService();
  late final Future<_Me> _meFuture = _loadMe();
  String _searchText = '';

  Future<_Me> _loadMe() async {
    final profile = await userService.value.getUserData();
    return _Me(
      // Same chat id for Firebase and DummyJSON accounts.
      uid: profile.chatId,
      email: profile.email ?? '',
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _nameOf(Map<String, dynamic> user) {
    final full = [user['firstName'], user['lastName']]
        .where((s) => s != null && s.toString().isNotEmpty)
        .join(' ');
    if (full.isNotEmpty) return full;
    final username = (user['username'] ?? '').toString();
    return username.isNotEmpty ? username : (user['email'] ?? 'Unknown').toString();
  }

  bool _matches(Map<String, dynamic> user) {
    final query = _searchText.trim().toLowerCase();
    if (query.isEmpty) return true;
    return _nameOf(user).toLowerCase().contains(query) ||
        (user['username'] ?? '').toString().toLowerCase().contains(query) ||
        (user['email'] ?? '').toString().toLowerCase().contains(query);
  }

  Widget _message(String text) => Center(
        child: Padding(
          padding: EdgeInsets.all(16.sp),
          child: CustomText(
            text: text,
            fontSize: 16.sp,
            textAlign: TextAlign.center,
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_Me>(
      future: _meFuture,
      builder: (context, meSnap) {
        if (meSnap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator.adaptive());
        }
        if (meSnap.hasError || !meSnap.hasData) {
          return _message('Could not load your account.');
        }
        final me = meSnap.data!;
        return Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 8.h),
              child: TextField(
                controller: _searchController,
                textInputAction: TextInputAction.search,
                onChanged: (value) => setState(() => _searchText = value),
                decoration: InputDecoration(
                  hintText: 'Search by name or email...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchText.isNotEmpty
                      ? IconButton(
                          tooltip: 'Clear',
                          icon: const Icon(Icons.cancel),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchText = '');
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                      width: 2,
                    ),
                  ),
                  contentPadding: EdgeInsets.symmetric(vertical: 0.h),
                ),
              ),
            ),
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: _chatService.getUsersStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator.adaptive(),
                    );
                  }
                  if (snapshot.hasError) return _message('Error loading users');

                  final users = (snapshot.data ?? [])
                      .where((u) => u['uid'] != me.uid)
                      .where(_matches)
                      .toList();
                  if (users.isEmpty) {
                    return _message(
                      _searchText.isEmpty ? 'No users found' : 'No matches found',
                    );
                  }

                  return ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 12.w),
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final user = users[index];
                      final name = _nameOf(user);
                      return Card(
                        child: ListTile(
                          onTap: () => Navigator.push(
                            context,
                            ChatDetailScreen.route(
                              currentUserEmail: me.email,
                              tappedUser: user,
                            ),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          leading: UserAvatar(
                            name: name,
                            seed: (user['uid'] ?? name).toString(),
                            heroTag: 'avatar_${user['uid']}',
                          ),
                          title: CustomText(
                            text: name,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: CustomText(
                            text: (user['email'] ?? 'No email').toString(),
                            fontSize: 12.sp,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: const Icon(Icons.chevron_right),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Me {
  final String uid;
  final String email;
  const _Me({required this.uid, required this.email});
}

/// The chat list as its own page, opened from the chat floating action button.
class ChatPage extends StatelessWidget {
  const ChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: CustomText(
          text: 'Chat',
          fontSize: 20.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
      body: const ChatScreen(),
    );
  }
}
