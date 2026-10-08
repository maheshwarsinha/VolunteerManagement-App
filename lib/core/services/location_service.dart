// lib/core/services/location_service.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class LocationServiceException implements Exception {
  final String message;
  LocationServiceException(this.message);

  @override
  String toString() => message;
}

class LocationPoint {
  final double latitude;
  final double longitude;
  final double accuracy;
  final double? speed;
  final double? heading;
  final DateTime timestamp;

  LocationPoint({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    this.speed,
    this.heading,
    required this.timestamp,
  });

  LatLng toLatLng() => LatLng(latitude, longitude);

  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
    'accuracy': accuracy,
    'speed': speed,
    'heading': heading,
    'timestamp': timestamp.toIso8601String(),
  };
}

class LocationService {
  StreamSubscription<Position>? _positionSubscription;
  Timer? _snapshotTimer;
  LocationPoint? _lastBroadcastLocation;
  DateTime? _lastBroadcastTime;
  
  // Offline buffer for temporary internet drops (Max 50 points to conserve memory)
  final List<LocationPoint> _offlineQueue = [];

  // Configuration thresholds for battery conservation
  static const int minDistanceFilterMeters = 30; // 30 meters
  static const int minTimeIntervalSeconds = 30;  // 30 seconds
  static const Duration snapshotInterval = Duration(minutes: 5); // 5-minute history snapshot

  /// Verify and check current permission status
  Future<LocationPermission> checkPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw LocationServiceException('Location services are disabled on this device.');
    }
    return await Geolocator.checkPermission();
  }

  /// Request permission from operating system
  Future<LocationPermission> requestPermission() async {
    return await Geolocator.requestPermission();
  }

  /// Get current instantaneous position
  Future<LocationPoint> getCurrentLocation() async {
    final hasPermission = await checkPermission();
    if (hasPermission == LocationPermission.denied ||
        hasPermission == LocationPermission.deniedForever) {
      throw LocationServiceException('Location permission is denied.');
    }

    final pos = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium, // Battery-conscious
        timeLimit: Duration(seconds: 15),
      ),
    );

    return LocationPoint(
      latitude: pos.latitude,
      longitude: pos.longitude,
      accuracy: pos.accuracy,
      speed: pos.speed,
      heading: pos.heading,
      timestamp: pos.timestamp,
    );
  }

  /// Start battery-conscious location tracking with distance filter
  void startTracking({
    required Function(LocationPoint point) onLiveLocationUpdate,
    required Function(LocationPoint point) onSnapshotDue,
  }) {
    stopTracking();

    final locationSettings = const LocationSettings(
      accuracy: LocationAccuracy.medium, // High battery efficiency
      distanceFilter: minDistanceFilterMeters, // Update only after moving > 30m
    );

    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position position) {
      final now = DateTime.now();
      final point = LocationPoint(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        speed: position.speed,
        heading: position.heading,
        timestamp: position.timestamp,
      );

      // Throttle: Ensure we don't spam if OS sends rapid consecutive events
      if (_lastBroadcastTime == null ||
          now.difference(_lastBroadcastTime!).inSeconds >= minTimeIntervalSeconds ||
          _hasMovedSignificantly(point)) {
        _lastBroadcastLocation = point;
        _lastBroadcastTime = now;
        onLiveLocationUpdate(point);
      }
    });

    // 5-Minute periodic timer for historical location snapshots
    _snapshotTimer = Timer.periodic(snapshotInterval, (_) {
      if (_lastBroadcastLocation != null) {
        onSnapshotDue(_lastBroadcastLocation!);
      }
    });
  }

  bool _hasMovedSignificantly(LocationPoint newPoint) {
    if (_lastBroadcastLocation == null) return true;
    final distance = Geolocator.distanceBetween(
      _lastBroadcastLocation!.latitude,
      _lastBroadcastLocation!.longitude,
      newPoint.latitude,
      newPoint.longitude,
    );
    return distance >= minDistanceFilterMeters;
  }

  /// Stop tracking & release battery resources immediately
  void stopTracking() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
    _snapshotTimer?.cancel();
    _snapshotTimer = null;
    _lastBroadcastLocation = null;
    _lastBroadcastTime = null;
  }

  /// Offline queue support
  void enqueueOffline(LocationPoint point) {
    if (_offlineQueue.length >= 50) {
      _offlineQueue.removeAt(0); // FIFO drop oldest
    }
    _offlineQueue.add(point);
  }

  List<LocationPoint> flushOfflineQueue() {
    final list = List<LocationPoint>.from(_offlineQueue);
    _offlineQueue.clear();
    return list;
  }
}
