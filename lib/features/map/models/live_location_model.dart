// lib/features/map/models/live_location_model.dart
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:volunteers_management/core/theme/app_theme.dart';
import 'package:volunteers_management/features/communities/models/community_model.dart';

enum MarkerActivityStatus {
  online,
  stale,
  offline;

  Color get color {
    switch (this) {
      case MarkerActivityStatus.online:
        return AppColors.statusOnline;
      case MarkerActivityStatus.stale:
        return AppColors.statusStale;
      case MarkerActivityStatus.offline:
        return AppColors.statusOffline;
    }
  }

  String get label {
    switch (this) {
      case MarkerActivityStatus.online:
        return 'Online';
      case MarkerActivityStatus.stale:
        return 'Stale (Inactive)';
      case MarkerActivityStatus.offline:
        return 'Offline';
    }
  }
}

class LiveLocationModel {
  final String userId;
  final String communityId;
  final double latitude;
  final double longitude;
  final double? accuracy;
  final double? speed;
  final double? heading;
  final int? batteryLevel;
  final DateTime lastUpdatedAt;

  // Joined profile metadata
  final String fullName;
  final String username;
  final MemberRole role;
  final String? profilePhotoUrl;
  final String? teamName;
  final String? phone;
  final String? volunteerId;

  LiveLocationModel({
    required this.userId,
    required this.communityId,
    required this.latitude,
    required this.longitude,
    this.accuracy,
    this.speed,
    this.heading,
    this.batteryLevel,
    required this.lastUpdatedAt,
    required this.fullName,
    required this.username,
    this.role = MemberRole.volunteer,
    this.profilePhotoUrl,
    this.teamName,
    this.phone,
    this.volunteerId,
  });

  LatLng get coordinates => LatLng(latitude, longitude);

  /// Dynamic presence calculation based on prompt thresholds:
  /// 0-5 mins: Online
  /// 5-15 mins: Stale
  /// 15+ mins: Offline
  MarkerActivityStatus get activityStatus {
    final diff = DateTime.now().difference(lastUpdatedAt);
    if (diff.inMinutes < 5) {
      return MarkerActivityStatus.online;
    } else if (diff.inMinutes < 15) {
      return MarkerActivityStatus.stale;
    } else {
      return MarkerActivityStatus.offline;
    }
  }

  bool get isStaleOrOffline => activityStatus != MarkerActivityStatus.online;

  factory LiveLocationModel.fromJson(Map<String, dynamic> json) {
    // If json contains joined profile object
    final profile = json['profiles'] as Map<String, dynamic>?;

    return LiveLocationModel(
      userId: json['user_id'] as String,
      communityId: json['community_id'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      accuracy: (json['accuracy'] as num?)?.toDouble(),
      speed: (json['speed'] as num?)?.toDouble(),
      heading: (json['heading'] as num?)?.toDouble(),
      batteryLevel: json['battery_level'] as int?,
      lastUpdatedAt: json['last_updated_at'] != null
          ? DateTime.parse(json['last_updated_at'] as String)
          : DateTime.now(),
      fullName: profile?['full_name'] as String? ?? json['full_name'] as String? ?? 'Volunteer',
      username: profile?['username'] as String? ?? json['username'] as String? ?? 'volunteer',
      role: MemberRole.fromString(json['role'] as String?),
      profilePhotoUrl: profile?['profile_photo_url'] as String? ?? json['profile_photo_url'] as String?,
      teamName: json['team_name'] as String?,
      phone: profile?['phone'] as String?,
      volunteerId: profile?['volunteer_id'] as String?,
    );
  }
}
