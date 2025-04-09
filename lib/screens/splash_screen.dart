import 'package:flutter/material.dart';
import 'package:flutter_app/utils/constants.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _redirect();
  }

  Future<void> _redirect() async {
    await Future.delayed(const Duration(seconds: 2));
    final session = supabase.auth.currentSession;
    
    if (mounted) {
      if (session != null) {
        // Check if user has completed profile setup
        final userInfo = await supabase
            .from('user_info')
            .select()
            .eq('id', session.user.id)
            .maybeSingle();
        
        if (userInfo == null) {
          // User needs to complete profile setup
          Navigator.of(context).pushReplacementNamed('/profile-setup');
        } else {
          // User has completed profile setup
          Navigator.of(context).pushReplacementNamed('/home');
        }
      } else {
        // No session, go to login
        Navigator.of(context).pushReplacementNamed('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App logo
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.travel_explore,
                size: 60,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'SoloBudd',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Connect with travelers worldwide',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
