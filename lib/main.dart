import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart'; 
import 'package:provider/provider.dart';

import 'screens/home_screen.dart';
import 'screens/signin_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/signup_screen.dart';

import 'providers/cart_provider.dart';
import 'providers/theme_provider.dart';
import 'firebase_options.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]).then((_) async {
    await dotenv.load(fileName: 'assets/.env');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    runApp(const RoqueAdvMobProg());
  });
}

class RoqueAdvMobProg extends StatelessWidget {
  const RoqueAdvMobProg({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
      ],
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
            // Enhancement 1: the splash screen checks for a saved session first.
            initialRoute: '/splash',
            routes: {
              '/splash' : (context) => const SplashScreen(),
              '/signin' : (context) => const SigninScreen(),
              '/signup' : (context) => const SignupScreen(),
              '/home' : (context) => const HomeScreen(),
              '/settings' : (context) => const SettingsScreen(),
            },
          );
        },
      ),
    );
  }
}


