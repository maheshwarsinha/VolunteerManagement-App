// lib/features/communities/repositories/community_repository.dart
import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:volunteers_management/core/config/supabase_config.dart';
import 'package:volunteers_management/features/communities/models/community_model.dart';

class CommunityRepository {
  final SupabaseClient? _supabase;

  // In-memory cache & mock fallback
  final List<CommunityModel> _mockCommunities = [];

  CommunityRepository([SupabaseClient? supabase])
      : _supabase = supabase ?? (SupabaseConfig.isConfigured ? _getSafeClient() : null) {
    _initMockData();
  }

  static SupabaseClient? _getSafeClient() {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  void _initMockData() {
    _mockCommunities.addAll([
      CommunityModel(
        id: 'comm-vortex-01',
        name: 'ANCOME VORTEX',
        description: 'Rapid disaster response and volunteer community corps.',
        code: 'AVX-7K29P',
        ownerId: 'usr-demo-owner',
        category: 'Disaster Relief & Tech',
        city: 'Kanpur',
        memberCount: 248,
        currentUserRole: MemberRole.admin,
        locationVisibility: LocationVisibility.allMembers,
        createdAt: DateTime.now().subtract(const Duration(days: 45)),
      ),
      CommunityModel(
        id: 'comm-csjmu-02',
        name: 'CSJMU Volunteers',
        description: 'University campus green campus and event management committee.',
        code: 'CSJ-49M1Q',
        ownerId: 'usr-demo-univ',
        category: 'Campus & Education',
        city: 'Kanpur',
        memberCount: 86,
        currentUserRole: MemberRole.volunteer,
        locationVisibility: LocationVisibility.allMembers,
        createdAt: DateTime.now().subtract(const Duration(days: 20)),
      ),
    ]);
  }

  /// Generate human-readable, case-insensitive unique code e.g. AVX-7K29P
  String generateCommunityCode(String name) {
    final prefix = name.replaceAll(RegExp(r'[^a-zA-Z]'), '').toUpperCase();
    final cleanPrefix = prefix.length >= 3 ? prefix.substring(0, 3) : 'VOL';
    const chars = '23456789ABCDEFGHJKLMNPQRSTUVWXYZ'; // exclude 0, 1, I, O to avoid confusion
    final rand = Random();
    final suffix = List.generate(5, (_) => chars[rand.nextInt(chars.length)]).join();
    return '$cleanPrefix-$suffix';
  }

  /// Fetch all communities where current user is an active member
  Future<List<CommunityModel>> getUserCommunities(String userId) async {
    if (SupabaseConfig.isConfigured && _supabase != null) {
      final res = await _supabase
          .from('community_members')
          .select('''
            role,
            communities (
              id, name, description, logo_url, code, code_enabled,
              owner_id, category, city, contact_info, requires_approval,
              location_visibility, location_retention_days, created_at
            )
          ''')
          .eq('user_id', userId)
          .eq('status', 'active');

      return (res as List).map((item) {
        final commData = item['communities'] as Map<String, dynamic>;
        final roleStr = item['role'] as String?;
        return CommunityModel.fromJson(commData, role: MemberRole.fromString(roleStr));
      }).toList();
    } else {
      return List.unmodifiable(_mockCommunities);
    }
  }

  /// Create a new Community with unique code & automatically assign creator as Owner
  Future<CommunityModel> createCommunity({
    required String name,
    required String ownerId,
    String? description,
    String? category,
    String? city,
    String? contactInfo,
    bool requiresApproval = false,
    LocationVisibility locationVisibility = LocationVisibility.allMembers,
    int locationRetentionDays = 30,
  }) async {
    final code = generateCommunityCode(name);

    if (SupabaseConfig.isConfigured && _supabase != null) {
      final insertRes = await _supabase
          .from('communities')
          .insert({
            'name': name.trim(),
            'description': description?.trim(),
            'code': code,
            'owner_id': ownerId,
            'category': category ?? 'General',
            'city': city?.trim(),
            'contact_info': contactInfo?.trim(),
            'requires_approval': requiresApproval,
            'location_visibility': locationVisibility.toDbString(),
            'location_retention_days': locationRetentionDays,
          })
          .select()
          .single();

      final community = CommunityModel.fromJson(insertRes, role: MemberRole.owner);

      // Automatically insert owner into community_members
      await _supabase.from('community_members').insert({
        'community_id': community.id,
        'user_id': ownerId,
        'role': 'owner',
        'status': 'active',
      });

      return community;
    } else {
      final newComm = CommunityModel(
        id: 'comm-${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        description: description,
        code: code,
        ownerId: ownerId,
        category: category ?? 'General',
        city: city,
        contactInfo: contactInfo,
        requiresApproval: requiresApproval,
        locationVisibility: locationVisibility,
        locationRetentionDays: locationRetentionDays,
        createdAt: DateTime.now(),
        currentUserRole: MemberRole.owner,
        memberCount: 1,
      );
      _mockCommunities.insert(0, newComm);
      return newComm;
    }
  }

  /// Preview a community before joining by its code
  Future<CommunityModel> previewCommunityByCode(String code) async {
    final cleanCode = code.trim().toUpperCase();

    if (SupabaseConfig.isConfigured && _supabase != null) {
      final res = await _supabase
          .from('communities')
          .select()
          .eq('code', cleanCode)
          .eq('code_enabled', true)
          .maybeSingle();

      if (res == null) {
        throw Exception('Community not found or joining code has been disabled.');
      }
      return CommunityModel.fromJson(res);
    } else {
      final match = _mockCommunities.firstWhere(
        (c) => c.code.toUpperCase() == cleanCode,
        orElse: () => CommunityModel(
          id: 'comm-preview-${cleanCode}',
          name: 'TechFest Volunteers',
          description: 'Coordination team for upcoming National Tech Festival.',
          code: cleanCode,
          ownerId: 'usr-org',
          category: 'Technology',
          city: 'Kanpur',
          memberCount: 42,
          createdAt: DateTime.now(),
        ),
      );
      return match;
    }
  }

  /// Join community using Code
  Future<void> joinCommunity({
    required String communityId,
    required String userId,
  }) async {
    if (SupabaseConfig.isConfigured && _supabase != null) {
      // Check if community requires approval
      final commRes = await _supabase
          .from('communities')
          .select('requires_approval')
          .eq('id', communityId)
          .single();

      final requiresApproval = commRes['requires_approval'] as bool? ?? false;

      if (requiresApproval) {
        await _supabase.from('join_requests').insert({
          'community_id': communityId,
          'user_id': userId,
          'status': 'pending',
        });
      } else {
        await _supabase.from('community_members').insert({
          'community_id': communityId,
          'user_id': userId,
          'role': 'volunteer',
          'status': 'active',
        });
      }
    } else {
      // In mock mode, add to list if not already present
      final existingIdx = _mockCommunities.indexWhere((c) => c.id == communityId);
      if (existingIdx != -1) {
        final existing = _mockCommunities[existingIdx];
        _mockCommunities[existingIdx] = CommunityModel(
          id: existing.id,
          name: existing.name,
          description: existing.description,
          code: existing.code,
          ownerId: existing.ownerId,
          category: existing.category,
          city: existing.city,
          contactInfo: existing.contactInfo,
          requiresApproval: existing.requiresApproval,
          locationVisibility: existing.locationVisibility,
          locationRetentionDays: existing.locationRetentionDays,
          createdAt: existing.createdAt,
          currentUserRole: MemberRole.volunteer,
          memberCount: existing.memberCount + 1,
        );
      }
    }
  }

  /// Regenerate community code (Admin/Owner only)
  Future<String> regenerateCode(String communityId, String communityName) async {
    final newCode = generateCommunityCode(communityName);
    if (SupabaseConfig.isConfigured && _supabase != null) {
      await _supabase
          .from('communities')
          .update({'code': newCode})
          .eq('id', communityId);
    }
    return newCode;
  }
}
