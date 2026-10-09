// lib/features/map/repositories/location_repository.dart
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:volunteers_management/core/config/supabase_config.dart';
import 'package:volunteers_management/core/services/location_service.dart';
import 'package:volunteers_management/features/map/models/live_location_model.dart';
import 'package:volunteers_management/features/communities/models/community_model.dart';

class LocationRepository {
  final SupabaseClient? _supabase;
  RealtimeChannel? _realtimeChannel;
  StreamController<List<LiveLocationModel>>? _locationsStreamController;

  // Local state cache
  final Map<String, LiveLocationModel> _cachedCommunityLocations = {};

  LocationRepository([SupabaseClient? supabase])
      : _supabase = supabase ?? (SupabaseConfig.isConfigured ? _getSafeClient() : null);

  static SupabaseClient? _getSafeClient() {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  /// Stream of live locations for currently active community
  Stream<List<LiveLocationModel>> subscribeToLiveLocations(String communityId) {
    _locationsStreamController?.close();
    _locationsStreamController = StreamController<List<LiveLocationModel>>.broadcast();

    // Clean up any existing channel before subscribing to new community
    unsubscribeRealtime();

    if (SupabaseConfig.isConfigured && _supabase != null) {
      // 1. Initial fetch from locations_live with joined profile
      _fetchInitialLocations(communityId);

      // 2. Setup Supabase Realtime channel for live updates
      _realtimeChannel = _supabase.channel('public:locations_live:$communityId')
        ..onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'locations_live',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'community_id',
            value: communityId,
          ),
          callback: (payload) {
            _handleRealtimePayload(payload, communityId);
          },
        )
        ..subscribe();
    } else {
      // Offline / Demo realistic simulation
      _generateMockLiveLocations(communityId);
    }

    return _locationsStreamController!.stream;
  }

  Future<void> _fetchInitialLocations(String communityId) async {
    try {
      final res = await _supabase!
          .from('locations_live')
          .select('''
            user_id, community_id, latitude, longitude,
            accuracy, speed, heading, battery_level, last_updated_at,
            profiles (
              full_name, username, profile_photo_url, phone, volunteer_id
            )
          ''')
          .eq('community_id', communityId);

      _cachedCommunityLocations.clear();
      for (final item in (res as List)) {
        final loc = LiveLocationModel.fromJson(item as Map<String, dynamic>);
        _cachedCommunityLocations[loc.userId] = loc;
      }
      _emitCurrentLocations();
    } catch (e) {
      // Handle error gracefully
    }
  }

  void _handleRealtimePayload(PostgresChangePayload payload, String communityId) async {
    final record = payload.newRecord;
    if (record.isEmpty) return;

    final userId = record['user_id'] as String;

    // Fetch profile details for new marker if not cached
    if (!_cachedCommunityLocations.containsKey(userId)) {
      final prof = await _supabase!
          .from('profiles')
          .select('full_name, username, profile_photo_url, phone, volunteer_id')
          .eq('id', userId)
          .maybeSingle();

      record['profiles'] = prof;
    } else {
      final existing = _cachedCommunityLocations[userId]!;
      record['profiles'] = {
        'full_name': existing.fullName,
        'username': existing.username,
        'profile_photo_url': existing.profilePhotoUrl,
        'phone': existing.phone,
        'volunteer_id': existing.volunteerId,
      };
    }

    final updatedModel = LiveLocationModel.fromJson(record);
    _cachedCommunityLocations[userId] = updatedModel;
    _emitCurrentLocations();
  }

  void _emitCurrentLocations() {
    if (_locationsStreamController != null && !_locationsStreamController!.isClosed) {
      _locationsStreamController!.add(_cachedCommunityLocations.values.toList());
    }
  }

  /// Broadcast live location update (Single row UPSERT per user/community)
  Future<void> broadcastLiveLocation({
    required String communityId,
    required String userId,
    required LocationPoint point,
  }) async {
    if (SupabaseConfig.isConfigured && _supabase != null) {
      await _supabase.from('locations_live').upsert({
        'user_id': userId,
        'community_id': communityId,
        'latitude': point.latitude,
        'longitude': point.longitude,
        'accuracy': point.accuracy,
        'speed': point.speed,
        'heading': point.heading,
        'last_updated_at': point.timestamp.toIso8601String(),
        'status': 'online',
      });
    } else {
      // Update local state
      _cachedCommunityLocations[userId] = LiveLocationModel(
        userId: userId,
        communityId: communityId,
        latitude: point.latitude,
        longitude: point.longitude,
        accuracy: point.accuracy,
        speed: point.speed,
        heading: point.heading,
        lastUpdatedAt: point.timestamp,
        fullName: 'Alex Vance (You)',
        username: 'alex_volunteer',
        role: MemberRole.admin,
      );
      _emitCurrentLocations();
    }
  }

  /// Persist periodic snapshot (approx. 5 minutes) to location_snapshots
  Future<void> persistLocationSnapshot({
    required String communityId,
    required String userId,
    required LocationPoint point,
  }) async {
    if (SupabaseConfig.isConfigured && _supabase != null) {
      await _supabase.from('location_snapshots').insert({
        'user_id': userId,
        'community_id': communityId,
        'latitude': point.latitude,
        'longitude': point.longitude,
        'accuracy': point.accuracy,
        'recorded_at': point.timestamp.toIso8601String(),
      });
    }
  }

  /// Remove user from live map when they disable location sharing
  Future<void> removeLiveLocation({
    required String communityId,
    required String userId,
  }) async {
    if (SupabaseConfig.isConfigured && _supabase != null) {
      await _supabase
          .from('locations_live')
          .delete()
          .match({'community_id': communityId, 'user_id': userId});
    } else {
      _cachedCommunityLocations.remove(userId);
      _emitCurrentLocations();
    }
  }

  /// Unsubscribe Realtime channel to preserve free tier connection quotas
  void unsubscribeRealtime() {
    if (_realtimeChannel != null) {
      _supabase?.removeChannel(_realtimeChannel!);
      _realtimeChannel = null;
    }
  }

  void dispose() {
    unsubscribeRealtime();
    _locationsStreamController?.close();
  }

  // Realistic mock data around coordinate center (Kanpur, India or coordinates of interest)
  void _generateMockLiveLocations(String communityId) {
    const baseLat = 26.4499;
    const baseLon = 80.3319;

    final mockList = [
      LiveLocationModel(
        userId: 'usr-demo-01',
        communityId: communityId,
        latitude: baseLat + 0.0035,
        longitude: baseLon + 0.0028,
        accuracy: 8.5,
        lastUpdatedAt: DateTime.now().subtract(const Duration(seconds: 40)), // Online
        fullName: 'Rohit Sharma',
        username: 'rohit_logistics',
        role: MemberRole.coordinator,
        teamName: 'Logistics',
        phone: '+91 98111 22334',
        volunteerId: 'VORTEX-012',
      ),
      LiveLocationModel(
        userId: 'usr-demo-02',
        communityId: communityId,
        latitude: baseLat - 0.0042,
        longitude: baseLon + 0.0061,
        accuracy: 12.0,
        lastUpdatedAt: DateTime.now().subtract(const Duration(minutes: 2)), // Online
        fullName: 'Khushi Verma',
        username: 'khushi_media',
        role: MemberRole.volunteer,
        teamName: 'Media',
        phone: '+91 97222 33445',
        volunteerId: 'VORTEX-055',
      ),
      LiveLocationModel(
        userId: 'usr-demo-03',
        communityId: communityId,
        latitude: baseLat + 0.0078,
        longitude: baseLon - 0.0045,
        accuracy: 15.0,
        lastUpdatedAt: DateTime.now().subtract(const Duration(minutes: 9)), // Stale (5-15m)
        fullName: 'Aman Gupta',
        username: 'aman_field',
        role: MemberRole.volunteer,
        teamName: 'Field Medical',
        volunteerId: 'VORTEX-089',
      ),
      LiveLocationModel(
        userId: 'usr-demo-04',
        communityId: communityId,
        latitude: baseLat - 0.0085,
        longitude: baseLon - 0.0032,
        accuracy: 25.0,
        lastUpdatedAt: DateTime.now().subtract(const Duration(minutes: 25)), // Offline (>15m)
        fullName: 'Priya Singh',
        username: 'priya_coord',
        role: MemberRole.coordinator,
        teamName: 'Registration',
        volunteerId: 'VORTEX-007',
      ),
    ];

    _cachedCommunityLocations.clear();
    for (final m in mockList) {
      _cachedCommunityLocations[m.userId] = m;
    }

    Timer(const Duration(milliseconds: 300), () {
      _emitCurrentLocations();
    });
  }
}
