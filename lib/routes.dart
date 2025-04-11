import 'package:flutter/material.dart';
import 'package:flutter_app/screens/chat/chat_list_screen.dart';
import 'package:flutter_app/screens/chat/chat_detail_screen.dart';
import 'package:flutter_app/screens/home_screen.dart';
import 'package:flutter_app/screens/login_screen.dart';
import 'package:flutter_app/screens/map_screen.dart';
import 'package:flutter_app/screens/nearby_users_screen.dart';
import 'package:flutter_app/screens/profile_screen.dart';
import 'package:flutter_app/screens/profile_setup_screen.dart';
import 'package:flutter_app/screens/signup_screen.dart';
import 'package:flutter_app/screens/splash_screen.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case '/login':
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case '/signup':
        return MaterialPageRoute(builder: (_) => const SignupScreen());
      case '/profile-setup':
        return MaterialPageRoute(builder: (_) => const ProfileSetupScreen());
      case '/home':
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case '/profile':
        return MaterialPageRoute(builder: (_) => const ProfileScreen());
      case '/nearby-users':
        return MaterialPageRoute(builder: (_) => const NearbyUsersScreen());
      case '/map':
        return MaterialPageRoute(builder: (_) => const MapScreen());
      case '/chats':
        return MaterialPageRoute(builder: (_) => const ChatListScreen());
      case '/chat':
        final conversationId = settings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => ChatDetailScreen(conversationId: conversationId),
        );
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
}
