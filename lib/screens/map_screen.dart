import 'package:flutter/material.dart';
import 'package:flutter_app/models/nearby_user.dart';
import 'package:flutter_app/services/location_service.dart';
import 'package:flutter_app/utils/constants.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'dart:math' as math;

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final LocationService _locationService = LocationService();
  final MapController _mapController = MapController();
  bool _isLoading = true;
  String _errorMessage = '';
  List<NearbyUser> _nearbyUsers = [];
  int _selectedRadius = 5000; // Default 5km
  Position? _currentPosition;
  bool _isMapReady = false;

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  @override
  void dispose() {
    _locationService.stopLocationUpdates();
    super.dispose();
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

      // Start location updates
      _locationService.startLocationUpdates();

      await _loadNearbyUsers();
      
      setState(() {
        _isMapReady = true;
      });
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

  void _centerOnUser() {
    if (_currentPosition != null) {
      _mapController.move(
        LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        13.0,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Map'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadNearbyUsers,
          ),
          IconButton(
            icon: const Icon(Icons.list),
            onPressed: () {
              Navigator.of(context).pushNamed('/nearby-users');
            },
          ),
        ],
      ),
      body: _buildContent(),
      floatingActionButton: FloatingActionButton(
        onPressed: _centerOnUser,
        child: const Icon(Icons.my_location),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading && !_isMapReady) {
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

    if (_currentPosition == null) {
      return const Center(
        child: Text('Location not available'),
      );
    }

    return Column(
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
          child: FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: LatLng(
                _currentPosition!.latitude,
                _currentPosition!.longitude,
              ),
              initialZoom: 13.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.app',
              ),
              CircleLayer(
                circles: [
                  CircleMarker(
                    point: LatLng(
                      _currentPosition!.latitude,
                      _currentPosition!.longitude,
                    ),
                    radius: _selectedRadius.toDouble(),
                    color: Colors.blue.withOpacity(0.2),
                    borderColor: Colors.blue,
                    borderStrokeWidth: 2.0,
                  ),
                ],
              ),
              MarkerLayer(
                markers: [
                  // Current user marker
                  Marker(
                    point: LatLng(
                      _currentPosition!.latitude,
                      _currentPosition!.longitude,
                    ),
                    width: 40,
                    height: 40,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.person_pin_circle,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  // Nearby users markers (mock positions since we don't have actual coordinates)
                  ..._nearbyUsers.map((user) {
                    // Calculate a random position within the radius for demo purposes
                    // In a real app, you would use the actual coordinates from the database
                    final random = DateTime.now().millisecondsSinceEpoch % user.hashCode;
                    final angle = random / 1000 * 2 * 3.14159; // Random angle
                    final distance = (random % _selectedRadius) / 1000; // Random distance within radius
                    
                    // Calculate offset position (this is just for demo)
                    final lat = _currentPosition!.latitude + distance * 0.009 * math.cos(angle);
                    final lng = _currentPosition!.longitude + distance * 0.009 * math.sin(angle);
                    
                    return Marker(
                      point: LatLng(lat, lng),
                      width: 40,
                      height: 40,
                      child: GestureDetector(
                        onTap: () {
                          _showUserInfo(user);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Theme.of(context).colorScheme.secondary,
                              width: 2,
                            ),
                          ),
                          child: ClipOval(
                            child: user.userInfo.avatarUrl != null
                                ? Image.network(
                                    user.userInfo.avatarUrl!,
                                    fit: BoxFit.cover,
                                  )
                                : const Icon(Icons.person),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showUserInfo(NearbyUser user) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: user.userInfo.avatarUrl != null
                        ? NetworkImage(user.userInfo.avatarUrl!)
                        : null,
                    child: user.userInfo.avatarUrl == null
                        ? const Icon(Icons.person, size: 30)
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.userInfo.fullName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text('Distance: ${user.formattedDistance}'),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (user.userInfo.bio != null && user.userInfo.bio!.isNotEmpty)
                Text(
                  user.userInfo.bio!,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      // TODO: Implement chat functionality
                      context.showSnackBar('Chat functionality coming soon!');
                    },
                    icon: const Icon(Icons.message),
                    label: const Text('Message'),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      // TODO: Navigate to user profile
                      context.showSnackBar('User profile view coming soon!');
                    },
                    icon: const Icon(Icons.person),
                    label: const Text('View Profile'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
