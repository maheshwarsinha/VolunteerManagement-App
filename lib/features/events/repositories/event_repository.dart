// lib/features/events/repositories/event_repository.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:volunteers_management/core/config/supabase_config.dart';
import 'package:volunteers_management/features/events/models/event_model.dart';

class EventRepository {
  final SupabaseClient? _supabase;
  final List<EventModel> _mockEvents = [];

  EventRepository([SupabaseClient? supabase])
      : _supabase = supabase ?? (SupabaseConfig.isConfigured ? _getSafeClient() : null) {
    _initMockEvents();
  }

  static SupabaseClient? _getSafeClient() {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  void _initMockEvents() {
    final now = DateTime.now();
    _mockEvents.addAll([
      EventModel(
        id: 'evt-01',
        communityId: 'comm-vortex-01',
        title: 'Flood Relief Supply Packing & Dispatch',
        description: 'Assembling emergency ration kits, medicine packs, and life vests for the eastern river bank relief drive.',
        venueName: 'Central Logistics Warehouse, Sector 4',
        latitude: 26.4520,
        longitude: 80.3340,
        startTime: now.add(const Duration(hours: 4)),
        endTime: now.add(const Duration(hours: 9)),
        qrCodeToken: 'EVT-VORTEX-FLOOD-RELIEF',
        participantsCount: 38,
        isUserRegistered: true,
      ),
      EventModel(
        id: 'evt-02',
        communityId: 'comm-vortex-01',
        title: 'Emergency First Aid & CPR Drill',
        description: 'Hands-on practical training with certified paramedics for all field volunteers.',
        venueName: 'Community Center Hall B',
        latitude: 26.4480,
        longitude: 80.3290,
        startTime: now.add(const Duration(days: 2, hours: 10)),
        endTime: now.add(const Duration(days: 2, hours: 13)),
        qrCodeToken: 'EVT-VORTEX-CPR-DRILL',
        participantsCount: 22,
        isUserRegistered: false,
      ),
      EventModel(
        id: 'evt-03',
        communityId: 'comm-csjmu-02',
        title: 'Clean Campus Tree Plantation Drive',
        description: 'Planting 200 neem and banyan saplings along the campus perimeter.',
        venueName: 'Main Campus Botanical Garden',
        startTime: now.add(const Duration(days: 3, hours: 8)),
        endTime: now.add(const Duration(days: 3, hours: 12)),
        qrCodeToken: 'EVT-CSJMU-GREEN-PLANTATION',
        participantsCount: 45,
        isUserRegistered: true,
      ),
    ]);
  }

  Future<List<EventModel>> getEvents(String communityId) async {
    if (SupabaseConfig.isConfigured && _supabase != null) {
      final res = await _supabase
          .from('events')
          .select()
          .eq('community_id', communityId)
          .order('start_time', ascending: true);

      return (res as List).map((item) => EventModel.fromJson(item as Map<String, dynamic>)).toList();
    } else {
      return _mockEvents.where((e) => e.communityId == communityId).toList();
    }
  }

  Future<void> createEvent({
    required String communityId,
    required String title,
    required String venueName,
    required DateTime startTime,
    required DateTime endTime,
    String? description,
    double? latitude,
    double? longitude,
  }) async {
    final qrToken = 'EVT-${DateTime.now().millisecondsSinceEpoch}';

    if (SupabaseConfig.isConfigured && _supabase != null) {
      await _supabase.from('events').insert({
        'community_id': communityId,
        'title': title,
        'venue_name': venueName,
        'start_time': startTime.toIso8601String(),
        'end_time': endTime.toIso8601String(),
        'description': description,
        'latitude': latitude,
        'longitude': longitude,
        'qr_code_token': qrToken,
      });
    } else {
      _mockEvents.add(
        EventModel(
          id: 'evt-${DateTime.now().millisecondsSinceEpoch}',
          communityId: communityId,
          title: title,
          description: description,
          venueName: venueName,
          latitude: latitude,
          longitude: longitude,
          startTime: startTime,
          endTime: endTime,
          qrCodeToken: qrToken,
          participantsCount: 1,
        ),
      );
    }
  }

  /// Check-in via QR token or manual confirmation
  Future<bool> checkInAttendance({
    required String eventId,
    required String userId,
    required String scannedQrToken,
  }) async {
    if (SupabaseConfig.isConfigured && _supabase != null) {
      final evt = await _supabase
          .from('events')
          .select('qr_code_token')
          .eq('id', eventId)
          .single();

      if (evt['qr_code_token'] != scannedQrToken) {
        throw Exception('Invalid QR Code for this event.');
      }

      await _supabase.from('attendance').upsert({
        'event_id': eventId,
        'user_id': userId,
        'status': 'attended',
        'check_in_time': DateTime.now().toIso8601String(),
      });
      return true;
    } else {
      return true;
    }
  }
}
