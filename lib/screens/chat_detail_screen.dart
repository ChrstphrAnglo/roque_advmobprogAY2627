import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../models/message_model.dart';
import '../services/chat_service.dart';
import '../services/user_service.dart';
import '../theme/app_colors.dart';
import '../widgets/custom_text.dart';
import '../widgets/user_avatar.dart';

class ChatDetailScreen extends StatefulWidget {
  final String currentUserEmail;
  final Map<String, dynamic> tappedUser;

  const ChatDetailScreen({
    super.key,
    required this.currentUserEmail,
    required this.tappedUser,
  });

  /// Fades and eases in from the right while the avatar flies up from the list.
  static Route<void> route({
    required String currentUserEmail,
    required Map<String, dynamic> tappedUser,
  }) {
    return PageRouteBuilder<void>(
      transitionDuration: const Duration(milliseconds: 380),
      reverseTransitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (_, _, _) => ChatDetailScreen(
        currentUserEmail: currentUserEmail,
        tappedUser: tappedUser,
      ),
      transitionsBuilder: (_, animation, _, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween(
              begin: const Offset(0.08, 0),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final _chatService = ChatService();
  final _msgCtrl = TextEditingController();
  final _msgFocus = FocusNode();
  final _scrollCtrl = ScrollController();

  /// Message IDs that already played their entrance animation.
  final _animated = <String>{};
  late final Future<String> _currentUserIdFuture = _getCurrentUserId();
  bool _initialLoadDone = false;
  bool _hasText = false;
  bool _showJump = false;
  bool _markingRead = false;

  String get _tappedUserId => (widget.tappedUser['uid'] ?? '').toString();

  String get _tappedUserName {
    final full = [
      widget.tappedUser['firstName'],
      widget.tappedUser['lastName'],
    ].where((s) => s != null && s.toString().isNotEmpty).join(' ');
    if (full.isNotEmpty) return full;
    final username = (widget.tappedUser['username'] ?? '').toString();
    return username.isNotEmpty
        ? username
        : (widget.tappedUser['email'] ?? '').toString();
  }

  Future<String> _getCurrentUserId() async =>
      (await userService.value.getUserData()).chatId;

  @override
  void initState() {
    super.initState();
    _msgCtrl.addListener(() {
      final hasText = _msgCtrl.text.trim().isNotEmpty;
      if (hasText != _hasText) setState(() => _hasText = hasText);
    });
    _scrollCtrl.addListener(() {
      final show = _scrollCtrl.hasClients && _scrollCtrl.offset > 240;
      if (show != _showJump) setState(() => _showJump = show);
    });
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _msgFocus.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToLatest() {
    if (!_scrollCtrl.hasClients) return;
    _scrollCtrl.animateTo(
      0,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _send() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;

    // Firestore queues the write locally, so the bubble appears at once as "Sending…".
    _msgCtrl.clear();
    _msgFocus.requestFocus();
    if (_scrollCtrl.hasClients && _scrollCtrl.offset > 0) _scrollToLatest();
    try {
      await _chatService.sendMessage(
        senderId: await _currentUserIdFuture,
        senderEmail: widget.currentUserEmail,
        receiverId: _tappedUserId,
        message: text,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to send: $e')));
    }
  }

  void _markIncomingAsRead(
    String currentUserId,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final hasUnread = docs.any((d) {
      final data = d.data();
      return data['receiverId'] == currentUserId && data['isRead'] != true;
    });
    if (!hasUnread || _markingRead) return;
    _markingRead = true;
    _chatService
        .markAsRead(currentUserId, _tappedUserId)
        .catchError((_) {})
        .whenComplete(() => _markingRead = false);
  }

  bool _sameDay(Timestamp a, Timestamp b) {
    final x = a.toDate();
    final y = b.toDate();
    return x.year == y.year && x.month == y.month && x.day == y.day;
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return FutureBuilder<String>(
      future: _currentUserIdFuture,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snap.hasError || !snap.hasData || snap.data!.isEmpty) {
          return const Scaffold(
            body: Center(child: Text('Could not load your account.')),
          );
        }
        final currentUserId = snap.data!;

        return Scaffold(
          appBar: AppBar(
            titleSpacing: 0,
            title: Row(
              children: [
                UserAvatar(
                  name: _tappedUserName,
                  seed: _tappedUserId,
                  radius: 18.r,
                  heroTag: 'avatar_$_tappedUserId',
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        text: _tappedUserName,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      CustomText(
                        text: (widget.tappedUser['email'] ?? '').toString(),
                        fontSize: 11.sp,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          body: DecoratedBox(
            decoration: BoxDecoration(
              gradient: AppColors.chatCanvas(brightness),
            ),
            child: Column(
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      Positioned.fill(child: _buildMessages(currentUserId)),
                      Positioned(
                        right: 16.w,
                        bottom: 8.h,
                        child: IgnorePointer(
                          ignoring: !_showJump,
                          child: AnimatedScale(
                            scale: _showJump ? 1 : 0,
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeOutBack,
                            child: FloatingActionButton.small(
                              heroTag: null,
                              elevation: 2,
                              onPressed: _scrollToLatest,
                              child: const Icon(
                                Icons.keyboard_arrow_down_rounded,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                _buildComposer(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMessages(String currentUserId) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _chatService.getMessage(currentUserId, _tappedUserId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text('Error loading messages: ${snapshot.error}'),
          );
        }
        final docs = snapshot.data?.docs ?? [];

        // Messages already in the chat when it opens stay still; only new ones animate.
        if (!_initialLoadDone) {
          _initialLoadDone = true;
          _animated.addAll(docs.map((d) => d.id));
        }
        if (docs.isEmpty) return _EmptyChat(name: _tappedUserName);
        _markIncomingAsRead(currentUserId, docs);

        final messages = [for (final d in docs) MessageModel.fromMap(d.data())];

        return ListView.builder(
          controller: _scrollCtrl,
          reverse: true,
          padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 10.w),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final message = messages[index];
            // The list is newest-first, so "newer" sits at a lower index.
            final newer = index > 0 ? messages[index - 1] : null;
            final older = index < messages.length - 1
                ? messages[index + 1]
                : null;

            final isMe = message.senderId == currentUserId;
            final endsGroup =
                newer == null ||
                newer.senderId != message.senderId ||
                !_sameDay(newer.timestamp, message.timestamp);
            final startsGroup =
                older == null ||
                older.senderId != message.senderId ||
                !_sameDay(older.timestamp, message.timestamp);
            final startsDay =
                older == null || !_sameDay(older.timestamp, message.timestamp);

            return Column(
              key: ValueKey(doc.id),
              children: [
                if (startsDay) _DaySeparator(timestamp: message.timestamp),
                Padding(
                  padding: EdgeInsets.only(top: startsGroup ? 8.h : 2.h),
                  child: _BubbleEntrance(
                    isMe: isMe,
                    animate: _animated.add(doc.id),
                    child: _MessageBubble(
                      message: message,
                      isMe: isMe,
                      isPending: doc.metadata.hasPendingWrites,
                      hasTail: endsGroup,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildComposer() {
    final scheme = Theme.of(context).colorScheme;
    final isLight = scheme.brightness == Brightness.light;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(12.w, 6.h, 12.w, 10.h),
        child: Material(
          color: isLight ? Colors.white : AppColors.nightRaised,
          elevation: 3,
          shadowColor: AppColors.indigo.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(28),
          child: Padding(
            padding: EdgeInsets.fromLTRB(18.w, 4.h, 5.w, 4.h),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: _msgCtrl,
                    focusNode: _msgFocus,
                    minLines: 1,
                    maxLines: 4,
                    textCapitalization: TextCapitalization.sentences,
                    style: TextStyle(fontFamily: 'Poppins', fontSize: 15.sp),
                    decoration: InputDecoration(
                      hintText: 'Message ${_tappedUserName.split(' ').first}',
                      isDense: true,
                      filled: false,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 12.h),
                    ),
                  ),
                ),
                SizedBox(width: 6.w),
                Padding(
                  padding: EdgeInsets.only(bottom: 2.h),
                  child: _SendButton(enabled: _hasText, onPressed: _send),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Sent bubbles spring out from the composer (bottom right); received ones
/// settle in from the left. Only plays once, and only when [animate] is true.
class _BubbleEntrance extends StatefulWidget {
  final bool isMe;
  final bool animate;
  final Widget child;
  const _BubbleEntrance({
    required this.isMe,
    required this.animate,
    required this.child,
  });

  @override
  State<_BubbleEntrance> createState() => _BubbleEntranceState();
}

class _BubbleEntranceState extends State<_BubbleEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: widget.isMe ? 480 : 380),
    value: widget.animate ? 0 : 1,
  );

  @override
  void initState() {
    super.initState();
    if (widget.animate) _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMe = widget.isMe;
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        final t = _controller.value;
        final fade = Curves.easeOut.transform((t * 2).clamp(0.0, 1.0));
        final spring = (isMe ? Curves.easeOutBack : Curves.easeOutCubic)
            .transform(t);
        return Opacity(
          opacity: fade,
          child: Transform.translate(
            offset: Offset(isMe ? 0 : -22 * (1 - spring), 20 * (1 - spring)),
            child: Transform.scale(
              scale: 0.72 + 0.28 * spring,
              alignment: isMe ? Alignment.bottomRight : Alignment.bottomLeft,
              child: child,
            ),
          ),
        );
      },
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;
  final bool isPending;
  final bool hasTail;

  const _MessageBubble({
    required this.message,
    required this.isMe,
    required this.isPending,
    required this.hasTail,
  });

  String _time(Timestamp ts) {
    final d = ts.toDate();
    final hour = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final minute = d.minute.toString().padLeft(2, '0');
    return '$hour:$minute ${d.hour >= 12 ? 'PM' : 'AM'}';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isLight = scheme.brightness == Brightness.light;

    final textColor = isMe
        ? Colors.white
        : (isLight ? AppColors.ink : AppColors.mist);
    final metaColor = textColor.withValues(alpha: isMe ? 0.75 : 0.6);

    const radius = Radius.circular(20);
    const tail = Radius.circular(5);
    final ownTail = hasTail ? tail : radius;

    final decoration = BoxDecoration(
      gradient: isMe ? AppColors.sentGradient : null,
      color: isMe ? null : (isLight ? Colors.white : AppColors.nightRaised),
      border: isMe || !isLight ? null : Border.all(color: AppColors.sage),
      borderRadius: BorderRadius.only(
        topLeft: radius,
        topRight: radius,
        bottomLeft: isMe ? radius : ownTail,
        bottomRight: isMe ? ownTail : radius,
      ),
      boxShadow: [
        BoxShadow(
          color: (isMe ? AppColors.indigo : AppColors.ink).withValues(
            alpha: isMe ? 0.28 : 0.08,
          ),
          blurRadius: 8,
          offset: const Offset(0, 3),
        ),
      ],
    );

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      // A message that is still being written to the server sits slightly faded.
      child: AnimatedOpacity(
        opacity: isMe && isPending ? 0.72 : 1,
        duration: const Duration(milliseconds: 300),
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 2.w),
          padding: EdgeInsets.fromLTRB(14.w, 9.h, 12.w, 6.h),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.76,
          ),
          decoration: decoration,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  message.message.isNotEmpty ? message.message : '[empty]',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 15.sp,
                    height: 1.35,
                    color: textColor,
                  ),
                ),
              ),
              SizedBox(height: 3.h),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: Text(
                      isMe && isPending ? 'Sending…' : _time(message.timestamp),
                      key: ValueKey(isMe && isPending),
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 10.sp,
                        color: metaColor,
                      ),
                    ),
                  ),
                  if (isMe) ...[
                    SizedBox(width: 4.w),
                    _StatusIcon(
                      isPending: isPending,
                      isRead: message.isRead,
                      color: metaColor,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Clock while sending, one check once delivered, aqua double check once seen.
/// Each change pops in so the state change is noticed.
class _StatusIcon extends StatelessWidget {
  final bool isPending;
  final bool isRead;
  final Color color;
  const _StatusIcon({
    required this.isPending,
    required this.isRead,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final IconData icon;
    final Color iconColor;
    if (isPending) {
      icon = Icons.schedule_rounded;
      iconColor = color;
    } else if (isRead) {
      icon = Icons.done_all_rounded;
      iconColor = AppColors.aqua;
    } else {
      icon = Icons.done_rounded;
      iconColor = color;
    }
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      switchInCurve: Curves.easeOutBack,
      transitionBuilder: (child, animation) => ScaleTransition(
        scale: animation,
        child: FadeTransition(opacity: animation, child: child),
      ),
      child: Icon(icon, key: ValueKey(icon), size: 15.sp, color: iconColor),
    );
  }
}

class _DaySeparator extends StatelessWidget {
  final Timestamp timestamp;
  const _DaySeparator({required this.timestamp});

  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  String get _label {
    final date = timestamp.toDate();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(date.year, date.month, date.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    final base = '${_months[date.month - 1]} ${date.day}';
    return date.year == now.year ? base : '$base, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10.h),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: isLight ? AppColors.sage : AppColors.nightRaised,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
          child: CustomText(
            text: _label,
            fontSize: 11.sp,
            fontWeight: FontWeight.w500,
            color: isLight ? AppColors.ink : AppColors.mist,
          ),
        ),
      ),
    );
  }
}

class _EmptyChat extends StatelessWidget {
  final String name;
  const _EmptyChat({required this.name});

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final color = isLight ? AppColors.ink : AppColors.mist;

    return Center(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 700),
        curve: Curves.elasticOut,
        builder: (context, t, child) => Transform.scale(scale: t, child: child),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 32.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(20.r),
                decoration: const BoxDecoration(
                  color: AppColors.aqua,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.waving_hand_rounded,
                  size: 34.sp,
                  color: AppColors.ink,
                ),
              ),
              SizedBox(height: 16.h),
              CustomText(
                text: 'No messages yet',
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              SizedBox(height: 4.h),
              CustomText(
                text: 'Send the first message to $name.',
                fontSize: 13.sp,
                textAlign: TextAlign.center,
                color: color.withValues(alpha: 0.75),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Gradient send button. Pressing it launches the paper plane up and to the
/// right, and a fresh one slides back in from the opposite corner.
class _SendButton extends StatefulWidget {
  final bool enabled;
  final VoidCallback onPressed;
  const _SendButton({required this.enabled, required this.onPressed});

  @override
  State<_SendButton> createState() => _SendButtonState();
}

class _SendButtonState extends State<_SendButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _launch = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 460),
  );

  @override
  void dispose() {
    _launch.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (!widget.enabled) return;
    widget.onPressed();
    _launch.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final size = 44.r;
    return AnimatedScale(
      scale: widget.enabled ? 1 : 0.88,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutBack,
      child: AnimatedOpacity(
        opacity: widget.enabled ? 1 : 0.45,
        duration: const Duration(milliseconds: 200),
        child: Semantics(
          button: true,
          label: 'Send message',
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: widget.enabled ? _handleTap : null,
              child: Container(
                width: size,
                height: size,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.sentGradient,
                ),
                child: AnimatedBuilder(
                  animation: _launch,
                  builder: (context, _) {
                    final t = _launch.value;
                    double dx, dy, opacity;
                    if (t < 0.5) {
                      final p = Curves.easeIn.transform(t * 2);
                      dx = 18 * p;
                      dy = -18 * p;
                      opacity = 1 - p;
                    } else {
                      final p = Curves.easeOut.transform((t - 0.5) * 2);
                      dx = -18 * (1 - p);
                      dy = 18 * (1 - p);
                      opacity = p;
                    }
                    return Transform.translate(
                      offset: Offset(dx, dy),
                      child: Opacity(
                        opacity: opacity,
                        child: const Icon(
                          Icons.send_rounded,
                          size: 20,
                          color: Colors.white,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
