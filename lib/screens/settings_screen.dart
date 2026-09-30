import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../providers/theme_provider.dart';
import '../utils/logout.dart';
import '../widgets/custom_text.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      appBar: AppBar(
        title: CustomText(
          text: 'Settings',
          fontSize: 20.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
      // Enhancement 3: dark/light mode switch
      body: ListView(
        children: [
          SwitchListTile(
            title: CustomText(
              text: themeProvider.isDark ? 'Light Mode' : 'Dark Mode',
              fontSize: 16.sp,
            ),
            value: themeProvider.isDark,
            onChanged: (_) => context.read<ThemeProvider>().toggleTheme(),
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: CustomText(text: 'Log out', fontSize: 16.sp),
            onTap: () => confirmLogout(context),
          ),
        ],
      ),
    );
  }
}
