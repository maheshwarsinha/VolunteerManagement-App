// test/unit_and_security_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:volunteers_management/features/communities/models/community_model.dart';
import 'package:volunteers_management/features/map/models/live_location_model.dart';
import 'package:volunteers_management/features/communities/repositories/community_repository.dart';

void main() {
  group('Security & RBAC Permission Tests', () {
    test('CRITICAL: Volunteer role must NOT have admin access', () {
      const volunteerRole = MemberRole.volunteer;
      expect(volunteerRole.isAdminOrHigher, isFalse);
      expect(volunteerRole.isCoordinatorOrHigher, isFalse);

      const coordRole = MemberRole.coordinator;
      expect(coordRole.isAdminOrHigher, isFalse);
      expect(coordRole.isCoordinatorOrHigher, isTrue);

      const adminRole = MemberRole.admin;
      expect(adminRole.isAdminOrHigher, isTrue);

      const ownerRole = MemberRole.owner;
      expect(ownerRole.isAdminOrHigher, isTrue);
    });

    test('CRITICAL: Multi-Community Scoping - Community code generation is unique & uppercase', () {
      final repo = CommunityRepository();
      final code1 = repo.generateCommunityCode('ANCOME VORTEX');
      final code2 = repo.generateCommunityCode('ANCOME VORTEX');

      expect(code1.startsWith('ANC-'), isTrue);
      expect(code1, equals(code1.toUpperCase()));
      expect(code1, isNot(equals(code2))); // Uniqueness across invocations
    });
  });

  group('Location Presence & Stale Marker Threshold Tests', () {
    test('Location updated < 5 mins ago is classified as ONLINE (Green)', () {
      final onlineLoc = LiveLocationModel(
        userId: 'u1',
        communityId: 'c1',
        latitude: 26.45,
        longitude: 80.33,
        lastUpdatedAt: DateTime.now().subtract(const Duration(minutes: 2)),
        fullName: 'Volunteer A',
        username: 'vol_a',
      );

      expect(onlineLoc.activityStatus, equals(MarkerActivityStatus.online));
      expect(onlineLoc.isStaleOrOffline, isFalse);
    });

    test('Location updated between 5-15 mins ago is classified as STALE (Grey/Amber marker)', () {
      final staleLoc = LiveLocationModel(
        userId: 'u2',
        communityId: 'c1',
        latitude: 26.45,
        longitude: 80.33,
        lastUpdatedAt: DateTime.now().subtract(const Duration(minutes: 8)),
        fullName: 'Volunteer B',
        username: 'vol_b',
      );

      expect(staleLoc.activityStatus, equals(MarkerActivityStatus.stale));
      expect(staleLoc.isStaleOrOffline, isTrue);
    });

    test('Location updated > 15 mins ago is classified as OFFLINE', () {
      final offlineLoc = LiveLocationModel(
        userId: 'u3',
        communityId: 'c1',
        latitude: 26.45,
        longitude: 80.33,
        lastUpdatedAt: DateTime.now().subtract(const Duration(minutes: 25)),
        fullName: 'Volunteer C',
        username: 'vol_c',
      );

      expect(offlineLoc.activityStatus, equals(MarkerActivityStatus.offline));
      expect(offlineLoc.isStaleOrOffline, isTrue);
    });
  });

  group('Location Visibility Policy Tests', () {
    test('Visibility enum serialization and mapping', () {
      expect(LocationVisibility.fromString('all_members'), equals(LocationVisibility.allMembers));
      expect(LocationVisibility.fromString('admins_coordinators_only'), equals(LocationVisibility.adminsCoordinatorsOnly));
      expect(LocationVisibility.fromString('team_members_only'), equals(LocationVisibility.teamMembersOnly));

      expect(LocationVisibility.adminsCoordinatorsOnly.toDbString(), equals('admins_coordinators_only'));
    });
  });
}
