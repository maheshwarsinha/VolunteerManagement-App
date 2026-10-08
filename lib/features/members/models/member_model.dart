import 'package:volunteers_management/features/communities/models/community_model.dart';
import 'package:volunteers_management/features/map/models/live_location_model.dart';

class MemberModel {
  final String id;
  final String userId;
  final String communityId;
  final MemberRole role;
  final String status;
  final DateTime joinedAt;
  
  // Profile fields
  final String fullName;
  final String username;
  final String email;
  final String? phone;
  final String? profilePhotoUrl;
  final String? city;
  final String? volunteerId;
  final List<String> skills;
  final String? organization;
  final String? emergencyContact;
  final bool locationSharingEnabled;
  final String? teamName;
  final MarkerActivityStatus presenceStatus;
  final DateTime? lastActiveAt;

  MemberModel({
    required this.id,
    required this.userId,
    required this.communityId,
    required this.role,
    this.status = 'active',
    required this.joinedAt,
    required this.fullName,
    required this.username,
    required this.email,
    this.phone,
    this.profilePhotoUrl,
    this.city,
    this.volunteerId,
    this.skills = const [],
    this.organization,
    this.emergencyContact,
    this.locationSharingEnabled = false,
    this.teamName,
    this.presenceStatus = MarkerActivityStatus.offline,
    this.lastActiveAt,
  });

  factory MemberModel.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'] as Map<String, dynamic>? ?? {};

    return MemberModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      communityId: json['community_id'] as String,
      role: MemberRole.fromString(json['role'] as String?),
      status: json['status'] as String? ?? 'active',
      joinedAt: json['joined_at'] != null 
          ? DateTime.parse(json['joined_at'] as String) 
          : DateTime.now(),
      fullName: profile['full_name'] as String? ?? 'Volunteer Member',
      username: profile['username'] as String? ?? 'volunteer',
      email: profile['email'] as String? ?? '',
      phone: profile['phone'] as String?,
      profilePhotoUrl: profile['profile_photo_url'] as String?,
      city: profile['city'] as String?,
      volunteerId: profile['volunteer_id'] as String?,
      skills: (profile['skills'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      organization: profile['organization'] as String?,
      emergencyContact: profile['emergency_contact'] as String?,
      locationSharingEnabled: profile['location_sharing_enabled'] as bool? ?? false,
      teamName: json['team_name'] as String?,
      presenceStatus: MarkerActivityStatus.offline,
    );
  }
}
