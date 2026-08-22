import 'package:flutter/material.dart'; 
import 'package:flutter/services.dart'; 
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart'; 
import 'package:provider/provider.dart';

import 'screens/home_screen.dart';
import 'screens/settings_screen.dart';

import 'providers/theme_provider.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]).then((_) async {
    await dotenv.load(fileName: 'assets/.env');
    runApp(const RoqueAdvMobProg());
  });
}

class RoqueAdvMobProg extends StatelessWidget {
  const RoqueAdvMobProg({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: ScreenUtilInit(
        designSize: const Size(412, 715),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (build, child) {
          final themeModel = build.watch<ThemeProvider>();
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: themeModel.lightTheme,
            darkTheme: themeModel.darkTheme,
            themeMode: themeModel.isDark ? ThemeMode.dark : ThemeMode.light,
            title: 'E-commerce App',
            initialRoute: '/home',
            routes: {
              '/home' : (context) => const HomeScreen(),
              '/settings' : (context) => const SettingsScreen(),
            },
          );
        },
      ),
    );
  }
}


