// lib/features/members/repositories/member_repository.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:volunteers_management/core/config/supabase_config.dart';
import 'package:volunteers_management/features/members/models/member_model.dart';
import 'package:volunteers_management/features/communities/models/community_model.dart';
import 'package:volunteers_management/features/map/models/live_location_model.dart';

class MemberRepository {
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

  MemberRepository();

  Future<List<MemberModel>> getCommunityMembers(String communityId) async {
    if (SupabaseConfig.isConfigured && _supabase != null) {
      final res = await _supabase
          .from('community_members')
          .select('''
            id, user_id, community_id, role, status, joined_at,
            profiles (
              full_name, username, email, phone, profile_photo_url,
              city, volunteer_id, skills, organization, emergency_contact,
              location_sharing_enabled
            )
          ''')
          .eq('community_id', communityId)
          .eq('status', 'active');

      return (res as List).map((item) => MemberModel.fromJson(item as Map<String, dynamic>)).toList();
    } else {
      // Mock realistic roster
      return [
        MemberModel(
          id: 'mem-01',
          userId: 'usr-demo-01',
          communityId: communityId,
          role: MemberRole.owner,
          joinedAt: DateTime.now().subtract(const Duration(days: 40)),
          fullName: 'Dr. Sameer Khan',
          username: 'sameer_lead',
          email: 'sameer@vortex.org',
          phone: '+91 99887 76655',
          city: 'Kanpur',
          volunteerId: 'VORTEX-001',
          skills: ['Disaster Management', 'Trauma Response'],
          organization: 'Apex Hospital',
          teamName: 'Core Executive',
          presenceStatus: MarkerActivityStatus.online,
          locationSharingEnabled: true,
        ),
        MemberModel(
          id: 'mem-02',
          userId: 'usr-demo-02',
          communityId: communityId,
          role: MemberRole.coordinator,
          joinedAt: DateTime.now().subtract(const Duration(days: 35)),
          fullName: 'Rohit Sharma',
          username: 'rohit_logistics',
          email: 'rohit@vortex.org',
          phone: '+91 98111 22334',
          city: 'Kanpur',
          volunteerId: 'VORTEX-012',
          skills: ['Fleet Dispatch', 'Inventory Control'],
          teamName: 'Logistics',
          presenceStatus: MarkerActivityStatus.online,
          locationSharingEnabled: true,
        ),
        MemberModel(
          id: 'mem-03',
          userId: 'usr-demo-03',
          communityId: communityId,
          role: MemberRole.volunteer,
          joinedAt: DateTime.now().subtract(const Duration(days: 18)),
          fullName: 'Khushi Verma',
          username: 'khushi_media',
          email: 'khushi@vortex.org',
          city: 'Kanpur',
          volunteerId: 'VORTEX-055',
          skills: ['Photography', 'Social Media Broadcast'],
          teamName: 'Media',
          presenceStatus: MarkerActivityStatus.online,
          locationSharingEnabled: true,
        ),
        MemberModel(
          id: 'mem-04',
          userId: 'usr-demo-04',
          communityId: communityId,
          role: MemberRole.volunteer,
          joinedAt: DateTime.now().subtract(const Duration(days: 10)),
          fullName: 'Aman Gupta',
          username: 'aman_field',
          email: 'aman@vortex.org',
          volunteerId: 'VORTEX-089',
          skills: ['First Aid', 'Patient Transport'],
          teamName: 'Field Medical',
          presenceStatus: MarkerActivityStatus.stale,
          locationSharingEnabled: true,
        ),
        MemberModel(
          id: 'mem-05',
          userId: 'usr-demo-05',
          communityId: communityId,
          role: MemberRole.volunteer,
          joinedAt: DateTime.now().subtract(const Duration(days: 5)),
          fullName: 'Priya Singh',
          username: 'priya_coord',
          email: 'priya@vortex.org',
          city: 'Lucknow',
          volunteerId: 'VORTEX-104',
          skills: ['Registration Desk', 'Hospitality'],
          teamName: 'Registration',
          presenceStatus: MarkerActivityStatus.offline,
          locationSharingEnabled: false,
        ),
      ];
    }
  }

  /// Change member role (Admin/Owner only)
  Future<void> updateMemberRole({
    required String memberId,
    required MemberRole newRole,
  }) async {
    if (SupabaseConfig.isConfigured && _supabase != null) {
      await _supabase
          .from('community_members')
          .update({'role': newRole.name})
          .eq('id', memberId);
    }
  }

  /// Remove member from community (Admin/Owner only)
  Future<void> removeMember(String memberId) async {
    if (SupabaseConfig.isConfigured && _supabase != null) {
      await _supabase
          .from('community_members')
          .delete()
          .eq('id', memberId);
    }
  }
}
