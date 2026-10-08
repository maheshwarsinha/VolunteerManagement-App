// lib/features/announcements/repositories/announcement_repository.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:volunteers_management/core/config/supabase_config.dart';
import 'package:volunteers_management/features/announcements/models/announcement_model.dart';

class AnnouncementRepository {
  final List<AnnouncementModel> _mockAnnouncements = [];

  SupabaseClient? get _supabase {
    if (SupabaseConfig.isConfigured) {
      try {
        return Supabase.instance.client;
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  AnnouncementRepository() {
    _initMockAnnouncements();
  }

  void _initMockAnnouncements() {
    _mockAnnouncements.addAll([
      AnnouncementModel(
        id: 'ann-01',
        communityId: 'comm-vortex-01',
        title: 'Meeting at 5 PM at Main Logistics Tent',
        content: 'All team coordinators and logistics volunteers please gather for the evening debrief and distribution update.',
        priority: 'urgent',
        authorName: 'Dr. Sameer Khan (Owner)',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      AnnouncementModel(
        id: 'ann-02',
        communityId: 'comm-vortex-01',
        title: 'Heavy Rainfall Advisory & Field Safety',
        content: 'Weather department has issued a heavy downpour warning. All field teams must maintain buddy pairs and keep location sharing active.',
        priority: 'emergency',
        authorName: 'Rohit Sharma (Coordinator)',
        createdAt: DateTime.now().subtract(const Duration(hours: 6)),
      ),
      AnnouncementModel(
        id: 'ann-03',
        communityId: 'comm-vortex-01',
        title: 'New Volunteer Orientation Scheduled',
        content: 'Welcome to all 42 new volunteers who joined this week! Introductory session starts tomorrow morning.',
        priority: 'normal',
        authorName: 'Priya Singh (Admin)',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ]);
  }

  Future<List<AnnouncementModel>> getAnnouncements(String communityId) async {
    if (SupabaseConfig.isConfigured && _supabase != null) {
      final res = await _supabase
          .from('announcements')
          .select('''
            id, community_id, team_id, title, content, priority, created_at,
            profiles (full_name)
          ''')
          .eq('community_id', communityId)
          .order('created_at', ascending: false);

      return (res as List).map((item) => AnnouncementModel.fromJson(item as Map<String, dynamic>)).toList();
    } else {
      return _mockAnnouncements.where((a) => a.communityId == communityId).toList();
    }
  }

  Future<void> createAnnouncement({
    required String communityId,
    required String authorId,
    required String title,
    required String content,
    String priority = 'normal',
  }) async {
    if (SupabaseConfig.isConfigured && _supabase != null) {
      await _supabase.from('announcements').insert({
        'community_id': communityId,
        'created_by': authorId,
        'title': title,
        'content': content,
        'priority': priority,
      });
    } else {
      _mockAnnouncements.insert(
        0,
        AnnouncementModel(
          id: 'ann-${DateTime.now().millisecondsSinceEpoch}',
          communityId: communityId,
          title: title,
          content: content,
          priority: priority,
          authorName: 'You (Admin)',
          createdAt: DateTime.now(),
        ),
      );
    }
  }
}
