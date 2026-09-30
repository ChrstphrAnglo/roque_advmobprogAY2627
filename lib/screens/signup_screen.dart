import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../services/user_service.dart';
import '../utils/validators.dart';
import '../widgets/custom_text.dart';
import '../widgets/custom_text_field.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fName = TextEditingController();
  final _lName = TextEditingController();
  final _age = TextEditingController();
  final _contactNo = TextEditingController();
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  String? _gender;
  bool _loading = false;

  @override
  void dispose() {
    for (final c in [_fName, _lName, _age, _contactNo, _username, _email, _password]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final service = userService.value;
    try {
      await service.createAccount(
        email: _email.text.trim(),
        password: _password.text,
      );
      await service.updateUsername(username: _username.text.trim());
      await service.saveFirebaseProfileDetails(
        uid: service.currentUser!.uid,
        firstName: _fName.text.trim(),
        lastName: _lName.text.trim(),
        age: int.parse(_age.text.trim()),
        contactNo: _contactNo.text.trim(),
        gender: _gender,
      );
      await service.syncUserToFirestore(
        uid: service.currentUser!.uid,
        email: service.currentUser!.email,
        firstName: _fName.text.trim(),
        lastName: _lName.text.trim(),
        username: _username.text.trim(),
      );
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? e.code);
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
    return Scaffold(
      appBar: AppBar(
        title: CustomText(
          text: 'Create account',
          fontSize: 20.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24.w),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CustomTextField(
                  controller: _fName,
                  label: 'First name',
                  icon: Icons.badge,
                  validator: (v) => Validators.name(v, 'First name'),
                ),
                CustomTextField(
                  controller: _lName,
                  label: 'Last name',
                  icon: Icons.badge_outlined,
                  validator: (v) => Validators.name(v, 'Last name'),
                ),
                CustomTextField(
                  controller: _age,
                  label: 'Age',
                  icon: Icons.cake,
                  keyboardType: TextInputType.number,
                  validator: Validators.age,
                ),
                // Same field DummyJSON profiles have, so both kinds of profile match.
                Padding(
                  padding: EdgeInsets.only(bottom: 12.h),
                  child: DropdownButtonFormField<String>(
                    initialValue: _gender,
                    decoration: const InputDecoration(
                      labelText: 'Gender',
                      prefixIcon: Icon(Icons.wc),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'female', child: Text('Female')),
                      DropdownMenuItem(value: 'male', child: Text('Male')),
                      DropdownMenuItem(value: 'other', child: Text('Other')),
                    ],
                    onChanged: (value) => setState(() => _gender = value),
                    validator: (v) => v == null ? 'Gender is required' : null,
                  ),
                ),
                CustomTextField(
                  controller: _contactNo,
                  label: 'Contact number',
                  icon: Icons.phone,
                  keyboardType: TextInputType.phone,
                  validator: Validators.contactNo,
                ),
                CustomTextField(
                  controller: _username,
                  label: 'Username',
                  icon: Icons.person,
                  validator: Validators.username,
                ),
                CustomTextField(
                  controller: _email,
                  label: 'Email address',
                  icon: Icons.email,
                  keyboardType: TextInputType.emailAddress,
                  validator: Validators.email,
                ),
                CustomTextField(
                  controller: _password,
                  label: 'Password',
                  icon: Icons.lock,
                  obscure: true,
                  textInputAction: TextInputAction.done,
                  validator: Validators.password,
                ),
                CustomText(
                  text: 'At least 8 characters with an uppercase letter, a lowercase letter, a number and a special character.',
                  fontSize: 11.sp,
                ),
                SizedBox(height: 16.h),
                FilledButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? SizedBox(
                          height: 20.h,
                          width: 20.h,
                          child: const CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Sign up'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
