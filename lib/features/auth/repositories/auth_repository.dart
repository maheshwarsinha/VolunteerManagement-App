// lib/features/auth/repositories/auth_repository.dart
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:volunteers_management/core/config/supabase_config.dart';
import 'package:volunteers_management/features/auth/models/user_profile.dart';

class AuthRepository {
  final SupabaseClient? _supabase;

  // Local mock store for instantaneous zero-config developer preview
  UserProfile? _mockCurrentUser;

  AuthRepository([SupabaseClient? supabase])
      : _supabase = supabase ?? (SupabaseConfig.isConfigured ? _getSafeClient() : null);

  static SupabaseClient? _getSafeClient() {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  bool get isAuthenticated => _supabase?.auth.currentUser != null || _mockCurrentUser != null;

  String? get currentUserId => _supabase?.auth.currentUser?.id ?? _mockCurrentUser?.id;

  /// Sign In with Username OR Email + Password
  /// Enforces application-level username resolution without exposing passwords.
  Future<UserProfile> login({
    required String usernameOrEmail,
    required String password,
  }) async {
    final identifier = usernameOrEmail.trim().toLowerCase();

    if (SupabaseConfig.isConfigured && _supabase != null) {
      String resolvedEmail = identifier;

      // If user typed a username without '@', resolve email via secure RPC/query
      if (!identifier.contains('@')) {
        final profileRes = await _supabase
            .from('profiles')
            .select('email')
            .eq('username', identifier)
            .maybeSingle();

        if (profileRes == null || profileRes['email'] == null) {
          throw Exception('Username not found. Please verify your credentials.');
        }
        resolvedEmail = profileRes['email'] as String;
      }

      final response = await _supabase.auth.signInWithPassword(
        email: resolvedEmail,
        password: password,
      );

      final user = response.user;
      if (user == null) {
        throw Exception('Authentication failed. Invalid credentials.');
      }

      return await getUserProfile(user.id);
    } else {
      // Offline / Developer Demo Fallback
      if (password.length < 6) {
        throw Exception('Password must be at least 6 characters.');
      }
      _mockCurrentUser = UserProfile(
        id: 'usr-demo-${DateTime.now().millisecondsSinceEpoch}',
        username: identifier.replaceAll('@', '_'),
        fullName: 'Alex Vance',
        email: identifier.contains('@') ? identifier : '$identifier@volunteers.org',
        phone: '+91 98765 43210',
        city: 'Kanpur',
        volunteerId: 'VORTEX-0042',
        skills: ['First Aid', 'Crowd Management', 'Logistics'],
        organization: 'Vortex Volunteer Corps',
        locationSharingEnabled: true,
        createdAt: DateTime.now(),
      );
      return _mockCurrentUser!;
    }
  }

  /// Register user with required fields and insert into public.profiles
  Future<UserProfile> register({
    required String fullName,
    required String username,
    required String email,
    required String password,
    String? phone,
    String? city,
    String? volunteerId,
    List<String> skills = const [],
    String? organization,
    String? emergencyContact,
  }) async {
    final cleanUsername = username.trim().toLowerCase();
    final cleanEmail = email.trim().toLowerCase();

    if (SupabaseConfig.isConfigured && _supabase != null) {
      // Check if username is already taken
      final existing = await _supabase
          .from('profiles')
          .select('id')
          .eq('username', cleanUsername)
          .maybeSingle();

      if (existing != null) {
        throw Exception('Username "$cleanUsername" is already taken. Please choose another.');
      }

      // Create Supabase Auth user
      final authRes = await _supabase.auth.signUp(
        email: cleanEmail,
        password: password,
        data: {'username': cleanUsername, 'full_name': fullName},
      );

      final user = authRes.user;
      if (user == null) {
        throw Exception('Registration failed.');
      }

      // Upsert profile record
      final profile = UserProfile(
        id: user.id,
        username: cleanUsername,
        fullName: fullName.trim(),
        email: cleanEmail,
        phone: phone?.trim(),
        city: city?.trim(),
        volunteerId: volunteerId?.trim(),
        skills: skills,
        organization: organization?.trim(),
        emergencyContact: emergencyContact?.trim(),
        locationSharingEnabled: false,
        createdAt: DateTime.now(),
      );

      await _supabase.from('profiles').upsert(profile.toJson());
      return profile;
    } else {
      _mockCurrentUser = UserProfile(
        id: 'usr-mock-${cleanUsername}',
        username: cleanUsername,
        fullName: fullName.trim(),
        email: cleanEmail,
        phone: phone?.trim(),
        city: city?.trim(),
        volunteerId: volunteerId?.trim(),
        skills: skills,
        organization: organization?.trim(),
        emergencyContact: emergencyContact?.trim(),
        locationSharingEnabled: false,
        createdAt: DateTime.now(),
      );
      return _mockCurrentUser!;
    }
  }

  /// Fetch user profile
  Future<UserProfile> getUserProfile(String userId) async {
    if (SupabaseConfig.isConfigured && _supabase != null) {
      final res = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();
      return UserProfile.fromJson(res);
    } else {
      return _mockCurrentUser ??
          UserProfile(
            id: userId,
            username: 'alex_volunteer',
            fullName: 'Alex Vance',
            email: 'alex@vortex.org',
            createdAt: DateTime.now(),
          );
    }
  }

  /// Update location sharing toggle state
  Future<void> updateLocationSharing(bool enabled) async {
    final uid = currentUserId;
    if (uid == null) return;

    if (SupabaseConfig.isConfigured && _supabase != null) {
      await _supabase
          .from('profiles')
          .update({'location_sharing_enabled': enabled})
          .eq('id', uid);
    } else {
      if (_mockCurrentUser != null) {
        _mockCurrentUser = _mockCurrentUser!.copyWith(locationSharingEnabled: enabled);
      }
    }
  }

  /// Logout current session
  Future<void> logout() async {
    if (SupabaseConfig.isConfigured && _supabase != null) {
      await _supabase.auth.signOut();
    }
    _mockCurrentUser = null;
  }
}
