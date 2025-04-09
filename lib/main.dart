import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_app/screens/splash_screen.dart';
import 'package:flutter_app/screens/login_screen.dart';
import 'package:flutter_app/screens/signup_screen.dart';
import 'package:flutter_app/screens/profile_setup_screen.dart';
import 'package:flutter_app/screens/home_screen.dart';
import 'package:flutter_app/screens/profile_screen.dart';
import 'package:flutter_app/screens/nearby_users_screen.dart';
import 'package:flutter_app/screens/map_screen.dart';
import 'package:flutter_app/utils/constants.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: const String.fromEnvironment('SUPABASE_URL', defaultValue: ''),
    anonKey: const String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: ''),
  );
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SoloBudd',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF5E17EB),
          primary: const Color(0xFF5E17EB),
          secondary: const Color(0xFF00C6AE),
        ),
        useMaterial3: true,
        // Use a system font as fallback in case custom fonts aren't available
        fontFamily: 'Poppins',
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/profile-setup': (context) => const ProfileSetupScreen(),
        '/home': (context) => const HomeScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/nearby-users': (context) => const NearbyUsersScreen(),
        '/map': (context) => const MapScreen(),
      },
    );
  }
}
