import 'package:flutter/material.dart';
import 'package:flutter_app/models/nearby_user.dart';
import 'package:flutter_app/services/location_service.dart';
import 'package:flutter_app/utils/constants.dart';
import 'package:geolocator/geolocator.dart';

class NearbyUsersScreen extends StatefulWidget {
  const NearbyUsersScreen({super.key});

  @override
  State<NearbyUsersScreen> createState() => _NearbyUsersScreenState();
}

class _NearbyUsersScreenState extends State<NearbyUsersScreen> {
  final LocationService _locationService = LocationService();
  bool _isLoading = true;
  String _errorMessage = '';
  List<NearbyUser> _nearbyUsers = [];
  int _selectedRadius = 5000; // Default 5km
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final serviceEnabled = await _locationService.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Location services are disabled.';
        });
        return;
      }

      final permission = await _locationService.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Location permissions are denied.';
        });
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Location permissions are permanently denied.';
        });
        return;
      }

      _currentPosition = await _locationService.getCurrentPosition();
      if (_currentPosition == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Unable to get current location.';
        });
        return;
      }

      await _loadNearbyUsers();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error: ${e.toString()}';
      });
    }
  }

  Future<void> _loadNearbyUsers() async {
    if (_currentPosition == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Location not available.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final nearbyUsersData = await _locationService.findNearbyUsers(
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        radiusMeters: _selectedRadius,
      );

      setState(() {
        _nearbyUsers = nearbyUsersData
            .map((userData) => NearbyUser.fromJson(userData))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error loading nearby users: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby Users'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadNearbyUsers,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const Text('Radius: '),
                Expanded(
                  child: Slider(
                    value: _selectedRadius.toDouble(),
                    min: 1000,
                    max: 50000,
                    divisions: 49,
                    label: '${(_selectedRadius / 1000).toStringAsFixed(1)} km',
                    onChanged: (value) {
                      setState(() {
                        _selectedRadius = value.toInt();
                      });
                    },
                    onChangeEnd: (value) {
                      _loadNearbyUsers();
                    },
                  ),
                ),
                Text('${(_selectedRadius / 1000).toStringAsFixed(1)} km'),
              ],
            ),
          ),
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _errorMessage,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _initializeLocation,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_nearbyUsers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'No users found nearby',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadNearbyUsers,
              child: const Text('Refresh'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _nearbyUsers.length,
      itemBuilder: (context, index) {
        final user = _nearbyUsers[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundImage: user.userInfo.avatarUrl != null
                  ? NetworkImage(user.userInfo.avatarUrl!)
                  : null,
              child: user.userInfo.avatarUrl == null
                  ? const Icon(Icons.person)
                  : null,
            ),
            title: Text(user.userInfo.fullName),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Distance: ${user.formattedDistance}'),
                if (user.userInfo.bio != null && user.userInfo.bio!.isNotEmpty)
                  Text(
                    user.userInfo.bio!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.message),
              onPressed: () {
                // TODO: Implement chat functionality
                context.showSnackBar('Chat functionality coming soon!');
              },
            ),
            onTap: () {
              // TODO: Navigate to user profile
              context.showSnackBar('User profile view coming soon!');
            },
          ),
        );
      },
    );
  }
}
