// lib/features/auth/models/user_profile.dart

class UserProfile {
  final String id;
  final String username;
  final String fullName;
  final String email;
  final String? phone;
  final String? profilePhotoUrl;
  final String? city;
  final String? volunteerId;
  final List<String> skills;
  final String? organization;
  final String? emergencyContact;
  final bool locationSharingEnabled;
  final DateTime createdAt;

  UserProfile({
    required this.id,
    required this.username,
    required this.fullName,
    required this.email,
    this.phone,
    this.profilePhotoUrl,
    this.city,
    this.volunteerId,
    this.skills = const [],
    this.organization,
    this.emergencyContact,
    this.locationSharingEnabled = false,
    required this.createdAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      username: json['username'] as String? ?? 'volunteer',
      fullName: json['full_name'] as String? ?? 'Volunteer Member',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String?,
      profilePhotoUrl: json['profile_photo_url'] as String?,
      city: json['city'] as String?,
      volunteerId: json['volunteer_id'] as String?,
      skills: (json['skills'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      organization: json['organization'] as String?,
      emergencyContact: json['emergency_contact'] as String?,
      locationSharingEnabled: json['location_sharing_enabled'] as bool? ?? false,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'full_name': fullName,
    'email': email,
    'phone': phone,
    'profile_photo_url': profilePhotoUrl,
    'city': city,
    'volunteer_id': volunteerId,
    'skills': skills,
    'organization': organization,
    'emergency_contact': emergencyContact,
    'location_sharing_enabled': locationSharingEnabled,
    'created_at': createdAt.toIso8601String(),
  };

  UserProfile copyWith({
    String? fullName,
    String? phone,
    String? profilePhotoUrl,
    String? city,
    String? volunteerId,
    List<String>? skills,
    String? organization,
    String? emergencyContact,
    bool? locationSharingEnabled,
  }) {
    return UserProfile(
      id: id,
      username: username,
      fullName: fullName ?? this.fullName,
      email: email,
      phone: phone ?? this.phone,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      city: city ?? this.city,
      volunteerId: volunteerId ?? this.volunteerId,
      skills: skills ?? this.skills,
      organization: organization ?? this.organization,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      locationSharingEnabled: locationSharingEnabled ?? this.locationSharingEnabled,
      createdAt: createdAt,
    );
  }
}
