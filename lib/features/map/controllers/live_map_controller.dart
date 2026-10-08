// lib/features/map/controllers/live_map_controller.dart
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:volunteers_management/core/services/location_service.dart';
import 'package:volunteers_management/features/map/models/live_location_model.dart';
import 'package:volunteers_management/features/map/repositories/location_repository.dart';
import 'package:volunteers_management/features/communities/controllers/community_controller.dart';
import 'package:volunteers_management/features/auth/controllers/auth_controller.dart';
import 'package:volunteers_management/features/communities/models/community_model.dart';

final locationRepositoryProvider = Provider<LocationRepository>((ref) {
  final repo = LocationRepository();
  ref.onDispose(() => repo.dispose());
  return repo;
});

final locationServiceProvider = Provider<LocationService>((ref) {
  final service = LocationService();
  ref.onDispose(() => service.stopTracking());
  return service;
});

class LiveMapState {
  final bool isLoading;
  final List<LiveLocationModel> allLocations;
  final String searchQuery;
  final String selectedStatusFilter; // 'all', 'online', 'stale', 'offline'
  final MemberRole? selectedRoleFilter;
  final LiveLocationModel? selectedMember;
  final bool isTrackingActive;
  final String? errorMessage;

  const LiveMapState({
    this.isLoading = false,
    this.allLocations = const [],
    this.searchQuery = '',
    this.selectedStatusFilter = 'all',
    this.selectedRoleFilter,
    this.selectedMember,
    this.isTrackingActive = false,
    this.errorMessage,
  });

  /// Filtered locations based on current search, presence status and role
  List<LiveLocationModel> get filteredLocations {
    return allLocations.where((loc) {
      // Search text filter
      if (searchQuery.isNotEmpty) {
        final q = searchQuery.toLowerCase();
        final match = loc.fullName.toLowerCase().contains(q) ||
            loc.username.toLowerCase().contains(q) ||
            (loc.teamName != null && loc.teamName!.toLowerCase().contains(q));
        if (!match) return false;
      }

      // Status filter
      if (selectedStatusFilter != 'all') {
        if (selectedStatusFilter == 'online' && loc.activityStatus != MarkerActivityStatus.online) {
          return false;
        } else if (selectedStatusFilter == 'stale' && loc.activityStatus != MarkerActivityStatus.stale) {
          return false;
        } else if (selectedStatusFilter == 'offline' && loc.activityStatus != MarkerActivityStatus.offline) {
          return false;
        }
      }

      // Role filter
      if (selectedRoleFilter != null && loc.role != selectedRoleFilter) {
        return false;
      }

      return true;
    }).toList();
  }

  int get onlineCount => allLocations.where((l) => l.activityStatus == MarkerActivityStatus.online).length;
  int get staleCount => allLocations.where((l) => l.activityStatus == MarkerActivityStatus.stale).length;
  int get offlineCount => allLocations.where((l) => l.activityStatus == MarkerActivityStatus.offline).length;

  LiveMapState copyWith({
    bool? isLoading,
    List<LiveLocationModel>? allLocations,
    String? searchQuery,
    String? selectedStatusFilter,
    MemberRole? selectedRoleFilter,
    LiveLocationModel? selectedMember,
    bool clearSelectedMember = false,
    bool? isTrackingActive,
    String? errorMessage,
  }) {
    return LiveMapState(
      isLoading: isLoading ?? this.isLoading,
      allLocations: allLocations ?? this.allLocations,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedStatusFilter: selectedStatusFilter ?? this.selectedStatusFilter,
      selectedRoleFilter: selectedRoleFilter ?? this.selectedRoleFilter,
      selectedMember: clearSelectedMember ? null : (selectedMember ?? this.selectedMember),
      isTrackingActive: isTrackingActive ?? this.isTrackingActive,
      errorMessage: errorMessage,
    );
  }
}

class LiveMapController extends StateNotifier<LiveMapState> {
  final LocationRepository _locationRepository;
  final LocationService _locationService;
  final Ref _ref;

  StreamSubscription<List<LiveLocationModel>>? _subscription;
  String? _currentCommunityId;

  LiveMapController(this._locationRepository, this._locationService, this._ref)
      : super(const LiveMapState()) {
    // Listen to community changes and reactively re-subscribe
    _ref.listen<CommunityState>(communityProvider, (prev, next) {
      if (next.activeCommunity?.id != _currentCommunityId) {
        _onActiveCommunityChanged(next.activeCommunity?.id);
      }
    });

    final activeComm = _ref.read(communityProvider).activeCommunity;
    if (activeComm != null) {
      _onActiveCommunityChanged(activeComm.id);
    }
  }

  void _onActiveCommunityChanged(String? newCommunityId) {
    _currentCommunityId = newCommunityId;
    _subscription?.cancel();
    _subscription = null;

    if (newCommunityId == null) {
      state = state.copyWith(allLocations: []);
      return;
    }

    state = state.copyWith(isLoading: true);

    _subscription = _locationRepository
        .subscribeToLiveLocations(newCommunityId)
        .listen((locations) {
      state = state.copyWith(
        isLoading: false,
        allLocations: locations,
      );
    });
  }

  /// Start device location broadcast if permitted
  Future<void> startBroadcasting() async {
    final activeComm = _ref.read(communityProvider).activeCommunity;
    final user = _ref.read(authProvider).user;
    if (activeComm == null || user == null) return;

    try {
      _locationService.startTracking(
        onLiveLocationUpdate: (point) {
          _locationRepository.broadcastLiveLocation(
            communityId: activeComm.id,
            userId: user.id,
            point: point,
          );
        },
        onSnapshotDue: (point) {
          _locationRepository.persistLocationSnapshot(
            communityId: activeComm.id,
            userId: user.id,
            point: point,
          );
        },
      );

      // Update user state
      await _ref.read(authProvider.notifier).toggleLocationSharing(true);
      state = state.copyWith(isTrackingActive: true);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  /// Stop device location broadcast immediately
  Future<void> stopBroadcasting() async {
    final activeComm = _ref.read(communityProvider).activeCommunity;
    final user = _ref.read(authProvider).user;

    _locationService.stopTracking();

    if (activeComm != null && user != null) {
      await _locationRepository.removeLiveLocation(
        communityId: activeComm.id,
        userId: user.id,
      );
    }

    await _ref.read(authProvider.notifier).toggleLocationSharing(false);
    state = state.copyWith(isTrackingActive: false);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setStatusFilter(String status) {
    state = state.copyWith(selectedStatusFilter: status);
  }

  void setRoleFilter(MemberRole? role) {
    state = state.copyWith(selectedRoleFilter: role);
  }

  void selectMember(LiveLocationModel? member) {
    state = state.copyWith(
      selectedMember: member,
      clearSelectedMember: member == null,
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _locationService.stopTracking();
    super.dispose();
  }
}

final liveMapProvider = StateNotifierProvider<LiveMapController, LiveMapState>((ref) {
  final locRepo = ref.watch(locationRepositoryProvider);
  final locSvc = ref.watch(locationServiceProvider);
  return LiveMapController(locRepo, locSvc, ref);
});
