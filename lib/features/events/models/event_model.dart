// lib/features/events/models/event_model.dart

class EventModel {
  final String id;
  final String communityId;
  final String title;
  final String? description;
  final String venueName;
  final double? latitude;
  final double? longitude;
  final DateTime startTime;
  final DateTime endTime;
  final String? imageUrl;
  final String? qrCodeToken;
  final int participantsCount;
  final bool isUserRegistered;
  final bool hasAttended;

  EventModel({
    required this.id,
    required this.communityId,
    required this.title,
    this.description,
    required this.venueName,
    this.latitude,
    this.longitude,
    required this.startTime,
    required this.endTime,
    this.imageUrl,
    this.qrCodeToken,
    this.participantsCount = 0,
    this.isUserRegistered = false,
    this.hasAttended = false,
  });

  bool get isUpcoming => startTime.isAfter(DateTime.now());
  bool get isOngoing => DateTime.now().isAfter(startTime) && DateTime.now().isBefore(endTime);
  bool get isCompleted => endTime.isBefore(DateTime.now());

  factory EventModel.fromJson(Map<String, dynamic> json, {bool isRegistered = false, bool attended = false}) {
    return EventModel(
      id: json['id'] as String,
      communityId: json['community_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      venueName: json['venue_name'] as String? ?? 'Main Volunteer Ground',
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      startTime: json['start_time'] != null 
          ? DateTime.parse(json['start_time'] as String) 
          : DateTime.now().add(const Duration(days: 1)),
      endTime: json['end_time'] != null 
          ? DateTime.parse(json['end_time'] as String) 
          : DateTime.now().add(const Duration(days: 1, hours: 3)),
      imageUrl: json['image_url'] as String?,
      qrCodeToken: json['qr_code_token'] as String?,
      participantsCount: json['participants_count'] as int? ?? 14,
      isUserRegistered: isRegistered,
      hasAttended: attended,
    );
  }
}
