import 'package:flutter_app/models/user_profile.dart';

class NearbyUser {
  final UserInfo userInfo;
  final double distanceMeters;
  final String? lastLocationUpdate;

  NearbyUser({
    required this.userInfo,
    required this.distanceMeters,
    this.lastLocationUpdate,
  });

  factory NearbyUser.fromJson(Map<String, dynamic> json) {
    return NearbyUser(
      userInfo: UserInfo.fromJson(json),
      distanceMeters: json['distance_meters'] ?? 0.0,
      lastLocationUpdate: json['updated_at'],
    );
  }

  String get formattedDistance {
    if (distanceMeters < 1000) {
      return '${distanceMeters.toStringAsFixed(0)} m';
    } else {
      final km = distanceMeters / 1000;
      return '${km.toStringAsFixed(1)} km';
    }
  }
}
