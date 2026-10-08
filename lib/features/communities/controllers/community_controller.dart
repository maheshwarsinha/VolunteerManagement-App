// lib/features/communities/controllers/community_controller.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:volunteers_management/features/communities/models/community_model.dart';
import 'package:volunteers_management/features/communities/repositories/community_repository.dart';
import 'package:volunteers_management/features/auth/controllers/auth_controller.dart';

final communityRepositoryProvider = Provider<CommunityRepository>((ref) {
  return CommunityRepository();
});

class CommunityState {
  final bool isLoading;
  final List<CommunityModel> userCommunities;
  final CommunityModel? activeCommunity;
  final String? errorMessage;

  const CommunityState({
    this.isLoading = false,
    this.userCommunities = const [],
    this.activeCommunity,
    this.errorMessage,
  });

  CommunityState copyWith({
    bool? isLoading,
    List<CommunityModel>? userCommunities,
    CommunityModel? activeCommunity,
    String? errorMessage,
  }) {
    return CommunityState(
      isLoading: isLoading ?? this.isLoading,
      userCommunities: userCommunities ?? this.userCommunities,
      activeCommunity: activeCommunity ?? this.activeCommunity,
      errorMessage: errorMessage,
    );
  }
}

class CommunityController extends StateNotifier<CommunityState> {
  final CommunityRepository _repository;
  final Ref _ref;

  CommunityController(this._repository, this._ref) : super(const CommunityState());

  Future<void> loadCommunities() async {
    final user = _ref.read(authProvider).user;
    if (user == null) return;

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final list = await _repository.getUserCommunities(user.id);
      final active = list.isNotEmpty
          ? (state.activeCommunity != null && list.any((c) => c.id == state.activeCommunity!.id)
              ? list.firstWhere((c) => c.id == state.activeCommunity!.id)
              : list.first)
          : null;

      state = state.copyWith(
        isLoading: false,
        userCommunities: list,
        activeCommunity: active,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  /// Switch active community context
  void selectCommunity(CommunityModel community) {
    state = state.copyWith(activeCommunity: community);
  }

  /// Create community and set as active
  Future<CommunityModel?> createCommunity({
    required String name,
    String? description,
    String? category,
    String? city,
    String? contactInfo,
    bool requiresApproval = false,
    LocationVisibility locationVisibility = LocationVisibility.allMembers,
    int locationRetentionDays = 30,
  }) async {
    final user = _ref.read(authProvider).user;
    if (user == null) return null;

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final newComm = await _repository.createCommunity(
        name: name,
        ownerId: user.id,
        description: description,
        category: category,
        city: city,
        contactInfo: contactInfo,
        requiresApproval: requiresApproval,
        locationVisibility: locationVisibility,
        locationRetentionDays: locationRetentionDays,
      );

      final updatedList = [newComm, ...state.userCommunities];
      state = state.copyWith(
        isLoading: false,
        userCommunities: updatedList,
        activeCommunity: newComm,
      );
      return newComm;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return null;
    }
  }

  /// Preview community before joining by code
  Future<CommunityModel> previewCommunityByCode(String code) async {
    return await _repository.previewCommunityByCode(code);
  }

  /// Join community
  Future<bool> joinCommunity(String communityId) async {
    final user = _ref.read(authProvider).user;
    if (user == null) return false;

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _repository.joinCommunity(
        communityId: communityId,
        userId: user.id,
      );
      await loadCommunities();
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  /// Regenerate code (Admin/Owner only)
  Future<String?> regenerateCommunityCode() async {
    final active = state.activeCommunity;
    if (active == null) return null;

    try {
      final newCode = await _repository.regenerateCode(active.id, active.name);
      await loadCommunities();
      return newCode;
    } catch (e) {
      return null;
    }
  }
}

final communityProvider = StateNotifierProvider<CommunityController, CommunityState>((ref) {
  final repo = ref.watch(communityRepositoryProvider);
  return CommunityController(repo, ref);
});
