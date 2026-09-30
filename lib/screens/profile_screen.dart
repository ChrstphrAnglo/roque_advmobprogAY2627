import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../models/user.dart';
import '../services/user_service.dart';
import '../utils/login_type.dart';
import '../utils/logout.dart';
import '../utils/validators.dart';
import '../widgets/custom_text.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/user_avatar.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<UserProfile> _profile = UserService().getUserData();

  // Pull to refresh reloads the profile from the server.
  void _reload() => setState(() => _profile = UserService().getUserData(refresh: true));

  String _messageFor(Object error) {
    if (error is FirebaseAuthException) return error.message ?? error.code;
    if (error is UserServiceException) return error.message;
    return 'Something went wrong. Check your connection and try again.';
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _updateUsername(UserProfile profile) async {
    final values = await showDialog<List<String>>(
      context: context,
      builder: (_) => _FormDialog(
        title: 'Update username',
        confirmLabel: 'Save',
        fields: [
          _DialogField(
            label: 'Username',
            initial: profile.username ?? '',
            validator: Validators.username,
          ),
        ],
        onSubmit: (values) => UserService().updateUsername(username: values[0].trim()),
        messageFor: _messageFor,
      ),
    );
    if (values == null || !mounted) return;
    // Show the new name right away instead of waiting for a reload from Firebase.
    setState(() {
      _profile = Future.value(profile.copyWith(username: values[0].trim()));
    });
    _snack('Username updated');
  }

  Future<void> _changePassword(UserProfile profile) async {
    final values = await showDialog<List<String>>(
      context: context,
      builder: (_) => _FormDialog(
        title: 'Change password',
        confirmLabel: 'Change',
        fields: [
          _DialogField(
            label: 'Current password',
            obscure: true,
            validator: (v) => (v == null || v.isEmpty) ? 'Password is required' : null,
          ),
          _DialogField(
            label: 'New password',
            obscure: true,
            validator: Validators.password,
          ),
        ],
        onSubmit: (values) => UserService().resetPasswordFromCurrentPassword(
          currentPassword: values[0],
          newPassword: values[1],
          email: profile.email!,
        ),
        messageFor: _messageFor,
      ),
    );
    if (values == null) return;
    _snack('Password changed');
  }

  Future<void> _deleteAccount(UserProfile profile) async {
    final values = await showDialog<List<String>>(
      context: context,
      builder: (_) => _FormDialog(
        title: 'Delete account',
        message: 'This permanently deletes your account. Enter your password to confirm.',
        confirmLabel: 'Delete',
        destructive: true,
        fields: [
          _DialogField(
            label: 'Password',
            obscure: true,
            validator: (v) => (v == null || v.isEmpty) ? 'Password is required' : null,
          ),
        ],
        onSubmit: (values) async {
          await UserService().deleteAccount(
            email: profile.email!,
            password: values[0],
          );
          await UserService().clearFirebaseProfileDetails(profile.id);
        },
        messageFor: _messageFor,
      ),
    );
    if (values == null || !mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/signin', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserProfile>(
      future: _profile,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomText(text: _messageFor(snapshot.error!), fontSize: 14.sp),
                SizedBox(height: 8.h),
                TextButton(onPressed: _reload, child: const Text('Retry')),
              ],
            ),
          );
        }
        return _buildProfile(snapshot.data!);
      },
    );
  }

  Widget _buildProfile(UserProfile profile) {
    final isFirebase = profile.loginType == LoginType.firebase;
    final scheme = Theme.of(context).colorScheme;

    // Enhancement 3: rows built from the saved user data. Firebase and DummyJSON
    // accounts fill in the same rows; a row is skipped when the account has no value.
    final rows = <_InfoRow>[
      _InfoRow(Icons.mail_outline, 'Email', profile.email),
      _InfoRow(Icons.wc, 'Gender', profile.gender),
      _InfoRow(Icons.cake_outlined, 'Age', profile.age?.toString()),
      _InfoRow(Icons.phone_outlined, 'Phone', profile.phone),
      _InfoRow(Icons.work_outline, 'Role', profile.role),
      if (isFirebase) ...[
        _InfoRow(
          Icons.verified_outlined,
          'Email verified',
          profile.emailVerified == true ? 'Yes' : 'No',
        ),
        _InfoRow(
          Icons.event_outlined,
          'Member since',
          profile.createdAt?.toLocal().toString().split(' ').first,
        ),
      ],
      _InfoRow(Icons.badge_outlined, 'User ID', isFirebase ? profile.id : '#${profile.id}'),
      // The user id the cart is read and saved under.
      _InfoRow(Icons.shopping_cart_outlined, 'Cart user', '#${profile.cartUserId}'),
    ].where((r) => r.value != null && r.value!.isNotEmpty).toList();

    return RefreshIndicator(
      onRefresh: () async {
        _reload();
        try {
          await _profile;
        } catch (_) {} // the FutureBuilder shows the error
      },
      child: ListView(
        padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 96.h),
        children: [
          Card(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24.h, horizontal: 16.w),
              child: Column(
                children: [
                  profile.imageUrl == null
                      ? UserAvatar(
                          name: profile.displayName,
                          seed: profile.chatId,
                          radius: 44.r,
                        )
                      : CircleAvatar(
                          radius: 44.r,
                          backgroundColor: scheme.surfaceContainerHighest,
                          backgroundImage: NetworkImage(profile.imageUrl!),
                        ),
                  SizedBox(height: 14.h),
                  CustomText(
                    text: profile.displayName,
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w600,
                    textAlign: TextAlign.center,
                  ),
                  if (profile.username != null && profile.username!.isNotEmpty)
                    CustomText(
                      text: '@${profile.username}',
                      fontSize: 13.sp,
                      color: scheme.primary,
                    ),
                  SizedBox(height: 10.h),
                  Chip(
                    visualDensity: VisualDensity.compact,
                    avatar: Icon(
                      isFirebase ? Icons.local_fire_department_outlined : Icons.cloud_outlined,
                      size: 16.sp,
                    ),
                    label: Text('Signed in with ${profile.loginType.label}'),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 8.h),
          Card(
            child: Column(
              children: [
                for (var i = 0; i < rows.length; i++) ...[
                  ListTile(
                    dense: true,
                    leading: Icon(rows[i].icon, color: scheme.primary),
                    title: CustomText(text: rows[i].label, fontSize: 13.sp),
                    trailing: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: 190.w),
                      child: CustomText(
                        text: rows[i].value!,
                        fontSize: 13.sp,
                        color: scheme.onSurfaceVariant,
                        textAlign: TextAlign.right,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  if (i < rows.length - 1) const Divider(height: 1, indent: 16, endIndent: 16),
                ],
              ],
            ),
          ),
          SizedBox(height: 8.h),
          if (isFirebase)
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.edit_outlined),
                    title: const Text('Update username'),
                    onTap: () => _updateUsername(profile),
                  ),
                  ListTile(
                    leading: const Icon(Icons.lock_reset),
                    title: const Text('Change password'),
                    onTap: () => _changePassword(profile),
                  ),
                  ListTile(
                    leading: Icon(Icons.delete_forever, color: scheme.error),
                    title: Text('Delete account', style: TextStyle(color: scheme.error)),
                    onTap: () => _deleteAccount(profile),
                  ),
                ],
              ),
            )
          else
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.w),
              child: CustomText(
                text: 'DummyJSON accounts are read-only, so username, password and account changes are only available for Firebase accounts.',
                fontSize: 12.sp,
                textAlign: TextAlign.center,
                color: scheme.onSurfaceVariant,
              ),
            ),
          SizedBox(height: 16.h),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFC9463D),
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.logout),
            label: const Text('Log out'),
            onPressed: () => confirmLogout(context),
          ),
        ],
      ),
    );
  }
}

class _InfoRow {
  const _InfoRow(this.icon, this.label, this.value);

  final IconData icon;
  final String label;
  final String? value;
}

class _DialogField {
  const _DialogField({
    required this.label,
    this.initial = '',
    this.obscure = false,
    this.validator,
  });

  final String label;
  final String initial;
  final bool obscure;
  final String? Function(String?)? validator;
}

/// A form in a dialog that runs [onSubmit] and shows any error inline.
/// Pops with the entered values once [onSubmit] succeeds.
class _FormDialog extends StatefulWidget {
  const _FormDialog({
    required this.title,
    required this.confirmLabel,
    required this.fields,
    required this.onSubmit,
    required this.messageFor,
    this.message,
    this.destructive = false,
  });

  final String title;
  final String confirmLabel;
  final String? message;
  final bool destructive;
  final List<_DialogField> fields;
  final Future<void> Function(List<String> values) onSubmit;
  final String Function(Object error) messageFor;

  @override
  State<_FormDialog> createState() => _FormDialogState();
}

class _FormDialogState extends State<_FormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _controllers = [
    for (final f in widget.fields) TextEditingController(text: f.initial),
  ];
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final values = [for (final c in _controllers) c.text];
    try {
      await widget.onSubmit(values);
      if (mounted) Navigator.pop(context, values);
    } catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = widget.messageFor(e);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AlertDialog(
      title: Text(widget.title),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.message != null)
                Padding(
                  padding: EdgeInsets.only(bottom: 12.h),
                  child: Text(widget.message!),
                ),
              for (var i = 0; i < widget.fields.length; i++)
                CustomTextField(
                  controller: _controllers[i],
                  label: widget.fields[i].label,
                  obscure: widget.fields[i].obscure,
                  validator: widget.fields[i].validator,
                ),
              if (_error != null)
                Text(_error!, style: TextStyle(color: scheme.error)),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: widget.destructive
              ? FilledButton.styleFrom(backgroundColor: scheme.error, foregroundColor: scheme.onError)
              : null,
          onPressed: _busy ? null : _submit,
          child: _busy
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(widget.confirmLabel),
        ),
      ],
    );
  }
}
