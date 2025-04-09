import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_app/utils/constants.dart';
import 'dart:async';

class LocationService {
  // Singleton pattern
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  // Current position
  Position? _currentPosition;
  Position? get currentPosition => _currentPosition;

  // Stream for location updates
  Stream<Position>? _positionStream;
  StreamSubscription<Position>? _positionSubscription;

  // Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  // Request location permission
  Future<LocationPermission> requestPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission;
  }

  // Get current position
  Future<Position?> getCurrentPosition() async {
    try {
      final serviceEnabled = await isLocationServiceEnabled();
      if (!serviceEnabled) {
        return Future.error('Location services are disabled.');
      }

      final permission = await requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied.');
      }

      if (permission == LocationPermission.deniedForever) {
        return Future.error(
            'Location permissions are permanently denied, we cannot request permissions.');
      }

      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      return _currentPosition;
    } catch (e) {
      debugPrint('Error getting location: $e');
      return null;
    }
  }

  // Start listening to location updates
  void startLocationUpdates() {
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update every 10 meters
      ),
    );

    _positionSubscription = _positionStream?.listen((Position position) {
      _currentPosition = position;
      _updateUserLocation(position);
    });
  }

  // Stop listening to location updates
  void stopLocationUpdates() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
  }

  // Update user location in Supabase
  Future<void> _updateUserLocation(Position position) async {
    try {
      final userId = supabase.auth.currentUser!.id;
      
      // Add to user_locations table
      await supabase.from('user_locations').insert({
        'user_id': userId,
        'geometry': 'POINT(${position.longitude} ${position.latitude})',
        'accuracy': position.accuracy,
        'location_type': 'precise', // Can be 'precise', 'nearby', or 'hidden'
      });
      
      debugPrint('Location updated: ${position.latitude}, ${position.longitude}');
    } catch (e) {
      debugPrint('Error updating location: $e');
    }
  }

  // Find nearby users
  Future<List<Map<String, dynamic>>> findNearbyUsers({
    required double latitude,
    required double longitude,
    required int radiusMeters,
    int limit = 20,
  }) async {
    try {
      final response = await supabase.rpc(
        'find_nearby_users',
        params: {
          'lat': latitude,
          'lng': longitude,
          'radius_meters': radiusMeters,
          'limit_count': limit,
        },
      );
      
      if (response == null) {
        return [];
      }
      
      // Get user details for each nearby user
      final List<Map<String, dynamic>> nearbyUsers = [];
      for (final user in response) {
        final userId = user['user_id'];
        final distance = user['distance_meters'];
        
        // Get user info
        final userInfo = await supabase
            .from('user_info')
            .select()
            .eq('id', userId)
            .single();
        
        nearbyUsers.add({
          ...userInfo,
          'distance_meters': distance,
        });
      }
      
      return nearbyUsers;
    } catch (e) {
      debugPrint('Error finding nearby users: $e');
      return [];
    }
  }

  // Find nearby meetups
  Future<List<Map<String, dynamic>>> findNearbyMeetups({
    required double latitude,
    required double longitude,
    required int radiusMeters,
    DateTime? fromDate,
    DateTime? toDate,
    int limit = 20,
  }) async {
    try {
      final response = await supabase.rpc(
        'find_nearby_meetups',
        params: {
          'lat': latitude,
          'lng': longitude,
          'radius_meters': radiusMeters,
          'from_date': fromDate?.toIso8601String() ?? DateTime.now().toIso8601String(),
          'to_date': toDate?.toIso8601String(),
          'limit_count': limit,
        },
      );
      
      if (response == null) {
        return [];
      }
      
      // Get meetup details for each nearby meetup
      final List<Map<String, dynamic>> nearbyMeetups = [];
      for (final meetup in response) {
        final meetupId = meetup['meetup_id'];
        final distance = meetup['distance_meters'];
        
        // Get meetup info
        final meetupInfo = await supabase
            .from('meetups')
            .select('*, locations(*), creator:creator_id(full_name, avatar_url)')
            .eq('id', meetupId)
            .single();
        
        nearbyMeetups.add({
          ...meetupInfo,
          'distance_meters': distance,
        });
      }
      
      return nearbyMeetups;
    } catch (e) {
      debugPrint('Error finding nearby meetups: $e');
      return [];
    }
  }
}
