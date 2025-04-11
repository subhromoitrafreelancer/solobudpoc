import 'package:flutter/material.dart';
import 'package:flutter_app/utils/constants.dart';
import 'package:flutter_app/services/location_service.dart';
import 'package:flutter_app/screens/map_screen.dart';
import 'package:geolocator/geolocator.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final LocationService _locationService = LocationService();
  bool _isLocationInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    try {
      final serviceEnabled = await _locationService.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return;
      }

      final permission = await _locationService.requestPermission();
      if (permission == LocationPermission.denied || 
          permission == LocationPermission.deniedForever) {
        return;
      }

      await _locationService.getCurrentPosition();
      _locationService.startLocationUpdates();
      
      setState(() {
        _isLocationInitialized = true;
      });
    } catch (e) {
      debugPrint('Error initializing location: $e');
    }
  }

  @override
  void dispose() {
    _locationService.stopLocationUpdates();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SoloBudd'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.of(context).pushNamed('/profile');
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          // Home tab
          _buildHomeTab(),
          // Explore tab
          _buildExploreTab(),
          // Chat tab
          const ChatListScreen(),
          // Meetups tab
          const Center(
            child: Text('Meetups Screen'),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (int index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore),
            label: 'Explore',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_outlined),
            selectedIcon: Icon(Icons.chat),
            label: 'Chat',
          ),
          NavigationDestination(
            icon: Icon(Icons.event_outlined),
            selectedIcon: Icon(Icons.event),
            label: 'Meetups',
          ),
        ],
      ),
    );
  }

  Widget _buildHomeTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome to SoloBudd!',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Connect with travelers worldwide and explore new places together.',
                  ),
                  const SizedBox(height: 16),
                  if (!_isLocationInitialized)
                    ElevatedButton.icon(
                      onPressed: _initializeLocation,
                      icon: const Icon(Icons.location_on),
                      label: const Text('Enable Location Services'),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Nearby section
          Text(
            'Explore Nearby',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildFeatureCard(
                  icon: Icons.people,
                  title: 'Nearby Users',
                  description: 'Find travelers near you',
                  onTap: () {
                    Navigator.of(context).pushNamed('/nearby-users');
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildFeatureCard(
                  icon: Icons.map,

```dart file="lib/utils/constants.dart"
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;
final LocalDatabaseService _localDb = LocalDatabaseService();

extension ShowSnackBar on BuildContext {
  void showSnackBar(
    String message, {
    bool isError = false,
    Duration duration = const Duration(seconds: 4),
  }) {
    ScaffoldMessenger.of(this).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: isError ? Colors.red : null,
      duration: duration,
    ));
  }

  void showErrorSnackBar(String message) {
    showSnackBar(message, isError: true);
  }
}
