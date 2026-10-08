// lib/features/communities/models/community_model.dart

enum LocationVisibility {
  allMembers,
  adminsCoordinatorsOnly,
  teamMembersOnly;

  static LocationVisibility fromString(String? val) {
    switch (val) {
      case 'admins_coordinators_only':
        return LocationVisibility.adminsCoordinatorsOnly;
      case 'team_members_only':
        return LocationVisibility.teamMembersOnly;
      case 'all_members':
      default:
        return LocationVisibility.allMembers;
    }
  }

  String toDbString() {
    switch (this) {
      case LocationVisibility.adminsCoordinatorsOnly:
        return 'admins_coordinators_only';
      case LocationVisibility.teamMembersOnly:
        return 'team_members_only';
      case LocationVisibility.allMembers:
        return 'all_members';
    }
  }

  String get displayName {
    switch (this) {
      case LocationVisibility.allMembers:
        return 'All Community Members';
      case LocationVisibility.adminsCoordinatorsOnly:
        return 'Admins & Coordinators Only';
      case LocationVisibility.teamMembersOnly:
        return 'Team Members Only';
    }
  }
}

enum MemberRole {
  owner,
  admin,
  coordinator,
  volunteer;

  static MemberRole fromString(String? val) {
    switch (val?.toLowerCase()) {
      case 'owner':
        return MemberRole.owner;
      case 'admin':
        return MemberRole.admin;
      case 'coordinator':
        return MemberRole.coordinator;
      case 'volunteer':
      default:
        return MemberRole.volunteer;
    }
  }

  String get displayName {
    switch (this) {
      case MemberRole.owner:
        return 'Owner';
      case MemberRole.admin:
        return 'Admin';
      case MemberRole.coordinator:
        return 'Coordinator';
      case MemberRole.volunteer:
        return 'Volunteer';
    }
  }

  bool get isAdminOrHigher => this == MemberRole.owner || this == MemberRole.admin;
  bool get isCoordinatorOrHigher => isAdminOrHigher || this == MemberRole.coordinator;
}

class CommunityModel {
  final String id;
  final String name;
  final String? description;
  final String? logoUrl;
  final String code;
  final bool codeEnabled;
  final String ownerId;
  final String category;
  final String? city;
  final String? contactInfo;
  final bool requiresApproval;
  final LocationVisibility locationVisibility;
  final int locationRetentionDays;
  final DateTime createdAt;
  final MemberRole? currentUserRole;
  final int memberCount;

  CommunityModel({
    required this.id,
    required this.name,
    this.description,
    this.logoUrl,
    required this.code,
    this.codeEnabled = true,
    required this.ownerId,
    this.category = 'General',
    this.city,
    this.contactInfo,
    this.requiresApproval = false,
    this.locationVisibility = LocationVisibility.allMembers,
    this.locationRetentionDays = 30,
    required this.createdAt,
    this.currentUserRole,
    this.memberCount = 1,
  });

  factory CommunityModel.fromJson(Map<String, dynamic> json, {MemberRole? role, int? count}) {
    return CommunityModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      logoUrl: json['logo_url'] as String?,
      code: json['code'] as String,
      codeEnabled: json['code_enabled'] as bool? ?? true,
      ownerId: json['owner_id'] as String,
      category: json['category'] as String? ?? 'General',
      city: json['city'] as String?,
      contactInfo: json['contact_info'] as String?,
      requiresApproval: json['requires_approval'] as bool? ?? false,
      locationVisibility: LocationVisibility.fromString(json['location_visibility'] as String?),
      locationRetentionDays: json['location_retention_days'] as int? ?? 30,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String) 
          : DateTime.now(),
      currentUserRole: role ?? MemberRole.fromString(json['user_role'] as String?),
      memberCount: count ?? json['member_count'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'logo_url': logoUrl,
    'code': code,
    'code_enabled': codeEnabled,
    'owner_id': ownerId,
    'category': category,
    'city': city,
    'contact_info': contactInfo,
    'requires_approval': requiresApproval,
    'location_visibility': locationVisibility.toDbString(),
    'location_retention_days': locationRetentionDays,
  };
}
