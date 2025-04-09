import 'package:flutter/material.dart';
import 'package:flutter_app/utils/constants.dart';
import 'package:flutter_app/services/location_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_app/screens/map_screen.dart';

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
          const Center(
            child: Text('Chat Screen'),
          ),
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
                  title: 'Map View',
                  description: 'See users on a map',
                  onTap: () {
                    Navigator.of(context).pushNamed('/map');
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildFeatureCard(
                  icon: Icons.event,
                  title: 'Meetups',
                  description: 'Join local events',
                  onTap: () {
                    context.showSnackBar('Meetups feature coming soon!');
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildFeatureCard(
                  icon: Icons.forum,
                  title: 'Forums',
                  description: 'Discuss travel topics',
                  onTap: () {
                    context.showSnackBar('Forums feature coming soon!');
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Tips section
          Text(
            'Travel Tips',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Safety First',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Always meet in public places and let someone know your plans when meeting new travel buddies.',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Local Customs',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Research local customs and traditions before traveling to a new destination.',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExploreTab() {
    return Column(
      children: [
        Expanded(
          child: Navigator(
            onGenerateRoute: (settings) {
              return MaterialPageRoute(
                builder: (context) => const MapScreen(),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(
                icon,
                size: 40,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
