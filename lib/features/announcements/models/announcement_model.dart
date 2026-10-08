// lib/features/announcements/models/announcement_model.dart

class AnnouncementModel {
  final String id;
  final String communityId;
  final String? teamId;
  final String title;
  final String content;
  final String priority; // normal, urgent, emergency
  final String authorName;
  final DateTime createdAt;

  AnnouncementModel({
    required this.id,
    required this.communityId,
    this.teamId,
    required this.title,
    required this.content,
    this.priority = 'normal',
    required this.authorName,
    required this.createdAt,
  });

  bool get isUrgent => priority == 'urgent' || priority == 'emergency';

  factory AnnouncementModel.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'] as Map<String, dynamic>?;

    return AnnouncementModel(
      id: json['id'] as String,
      communityId: json['community_id'] as String,
      teamId: json['team_id'] as String?,
      title: json['title'] as String,
      content: json['content'] as String,
      priority: json['priority'] as String? ?? 'normal',
      authorName: profile?['full_name'] as String? ?? 'Community Admin',
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String) 
          : DateTime.now(),
    );
  }
}
