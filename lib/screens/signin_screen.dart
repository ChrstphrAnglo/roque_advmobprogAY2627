import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../services/user_service.dart';
import '../theme/app_colors.dart';
import '../utils/login_type.dart';
import '../utils/validators.dart';
import '../widgets/custom_text.dart';
import '../widgets/custom_text_field.dart';

class SigninScreen extends StatefulWidget {
  const SigninScreen({super.key});

  @override
  State<SigninScreen> createState() => _SigninScreenState();
}

class _SigninScreenState extends State<SigninScreen> {
  final _formKey = GlobalKey<FormState>();
  final _idController = TextEditingController();
  final _passwordController = TextEditingController();
  LoginType _loginType = LoginType.firebase;
  bool _loading = false;

  bool get _isFirebase => _loginType == LoginType.firebase;

  @override
  void dispose() {
    _idController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final service = userService.value;
    final id = _idController.text.trim();
    final password = _passwordController.text;

    try {
      if (_isFirebase) {
        await service.signIn(email: id, password: password);
      } else {
        // Enhancement 2: DummyJSON login through UserService; it saves the user data.
        await service.loginUser(id, password);
      }
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home');
    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? e.code);
    } on UserServiceException catch (e) {
      _showError(e.message);
    } catch (_) {
      _showError('Something went wrong. Check your connection and try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isLight = scheme.brightness == Brightness.light;

    return Scaffold(
      body: DecoratedBox(
        // The palette's own wash: blue at the top, through aqua, into sage.
        decoration: BoxDecoration(
          gradient: isLight
              ? const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppColors.blue, AppColors.aqua, AppColors.sage],
                )
              : const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.indigo,
                    AppColors.nightSurface,
                    AppColors.night,
                  ],
                ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
              child: Container(
                padding: EdgeInsets.all(24.w),
                decoration: BoxDecoration(
                  color: scheme.surface,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.ink.withValues(alpha: 0.18),
                      blurRadius: 32,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          padding: EdgeInsets.all(14.r),
                          decoration: BoxDecoration(
                            gradient: AppColors.sentGradient,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.storefront,
                            size: 34.sp,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      SizedBox(height: 12.h),
                      CustomText(
                        text: 'NubDExchange',
                        fontSize: 24.sp,
                        fontWeight: FontWeight.w600,
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 24.h),
                      SegmentedButton<LoginType>(
                        segments: [
                          for (final type in LoginType.values.reversed)
                            ButtonSegment(value: type, label: Text(type.label)),
                        ],
                        selected: {_loginType},
                        onSelectionChanged: (selection) => setState(() {
                          _loginType = selection.first;
                          _idController.clear();
                          _passwordController.clear();
                          _formKey.currentState?.reset();
                        }),
                      ),
                      SizedBox(height: 16.h),
                      CustomTextField(
                        // A new key rebuilds the field so its validator matches the login type.
                        key: ValueKey(_loginType),
                        controller: _idController,
                        label: _isFirebase ? 'Email address' : 'Username',
                        icon: _isFirebase ? Icons.email : Icons.person,
                        keyboardType: _isFirebase
                            ? TextInputType.emailAddress
                            : TextInputType.text,
                        validator: _isFirebase
                            ? Validators.email
                            : (v) => Validators.required(v, 'Username'),
                      ),
                      CustomTextField(
                        controller: _passwordController,
                        label: 'Password',
                        icon: Icons.lock,
                        obscure: true,
                        textInputAction: TextInputAction.done,
                        // Only require a value here; the strength rules apply when signing up.
                        validator: (v) => (v == null || v.isEmpty)
                            ? 'Password is required'
                            : null,
                      ),
                      SizedBox(height: 8.h),
                      FilledButton(
                        onPressed: _loading ? null : _submit,
                        child: _loading
                            ? SizedBox(
                                height: 20.h,
                                width: 20.h,
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Log in'),
                      ),
                      SizedBox(height: 8.h),
                      if (_isFirebase)
                        TextButton(
                          onPressed: () =>
                              Navigator.pushNamed(context, '/signup'),
                          child: const Text("Don't have an account? Sign up"),
                        )
                      else
                        CustomText(
                          text: 'Test account: emilys / emilyspass',
                          fontSize: 12.sp,
                          textAlign: TextAlign.center,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
