// lib/features/members/views/members_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:volunteers_management/core/theme/app_theme.dart';
import 'package:volunteers_management/features/members/repositories/member_repository.dart';
import 'package:volunteers_management/features/members/models/member_model.dart';
import 'package:volunteers_management/features/communities/controllers/community_controller.dart';
import 'package:volunteers_management/features/communities/models/community_model.dart';
import 'package:volunteers_management/shared/widgets/status_badge.dart';
import 'package:volunteers_management/features/map/models/live_location_model.dart';

final memberRepositoryProvider = Provider<MemberRepository>((ref) {
  return MemberRepository();
});

final communityMembersProvider = FutureProvider.family<List<MemberModel>, String>((ref, communityId) {
  return ref.watch(memberRepositoryProvider).getCommunityMembers(communityId);
});

class MembersScreen extends ConsumerStatefulWidget {
  const MembersScreen({super.key});

  @override
  ConsumerState<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends ConsumerState<MembersScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _statusFilter = 'all'; // all, online, offline
  MemberRole? _roleFilter;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final commState = ref.watch(communityProvider);
    final activeComm = commState.activeCommunity;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (activeComm == null) {
      return const Scaffold(
        body: Center(child: Text('No active community')),
      );
    }

    final membersAsync = ref.watch(communityMembersProvider(activeComm.id));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Member Directory'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search and Filter Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Search members, skills, volunteer ID...',
                      prefixIcon: const Icon(Icons.search_rounded, size: 20),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 16),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {});
                              },
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterPill(
                          label: 'All Members',
                          isSelected: _statusFilter == 'all' && _roleFilter == null,
                          onTap: () => setState(() {
                            _statusFilter = 'all';
                            _roleFilter = null;
                          }),
                          isDark: isDark,
                        ),
                        const SizedBox(width: 8),
                        _buildFilterPill(
                          label: '🟢 Online Only',
                          isSelected: _statusFilter == 'online',
                          onTap: () => setState(() => _statusFilter = 'online'),
                          isDark: isDark,
                        ),
                        const SizedBox(width: 8),
                        _buildFilterPill(
                          label: 'Coordinators',
                          isSelected: _roleFilter == MemberRole.coordinator,
                          onTap: () => setState(() => _roleFilter = MemberRole.coordinator),
                          isDark: isDark,
                        ),
                        const SizedBox(width: 8),
                        _buildFilterPill(
                          label: 'Admins',
                          isSelected: _roleFilter == MemberRole.admin,
                          onTap: () => setState(() => _roleFilter = MemberRole.admin),
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 6),

            // Members List
            Expanded(
              child: membersAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(child: Text('Error loading members: $err')),
                data: (members) {
                  final filtered = members.where((m) {
                    final query = _searchController.text.toLowerCase();
                    if (query.isNotEmpty) {
                      final match = m.fullName.toLowerCase().contains(query) ||
                          m.username.toLowerCase().contains(query) ||
                          (m.volunteerId != null && m.volunteerId!.toLowerCase().contains(query)) ||
                          m.skills.any((s) => s.toLowerCase().contains(query));
                      if (!match) return false;
                    }

                    if (_statusFilter == 'online' && m.presenceStatus != MarkerActivityStatus.online) {
                      return false;
                    }

                    if (_roleFilter != null && m.role != _roleFilter) {
                      return false;
                    }

                    return true;
                  }).toList();

                  if (filtered.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.person_search_rounded, size: 48, color: isDark ? Colors.white24 : Colors.black26),
                          const SizedBox(height: 12),
                          const Text('No members matched your search criteria.'),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final member = filtered[index];
                      return _buildMemberTile(context, member, isDark);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterPill({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : (isDark ? AppColors.darkCard : AppColors.lightCard),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : (isDark ? Colors.white70 : AppColors.lightTextPrimary),
          ),
        ),
      ),
    );
  }

  Widget _buildMemberTile(BuildContext context, MemberModel member, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.primary.withValues(alpha: 0.12),
            child: Text(
              member.fullName.isNotEmpty ? member.fullName[0].toUpperCase() : 'V',
              style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        member.fullName,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    StatusBadge(status: member.presenceStatus, showLabel: false),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '@${member.username} • ${member.role.displayName} ${member.teamName != null ? "• ${member.teamName}" : ""}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
                if (member.skills.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: member.skills.take(2).map((skill) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          skill,
                          style: TextStyle(
                            fontSize: 10,
                            color: isDark ? Colors.white70 : AppColors.lightTextPrimary,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded),
            onPressed: () => _showMemberSheet(context, member),
          ),
        ],
      ),
    );
  }

  void _showMemberSheet(BuildContext context, MemberModel member) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                    child: Text(
                      member.fullName[0].toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 22, color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          member.fullName,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                        ),
                        Text(
                          '${member.role.displayName} • ID: ${member.volunteerId ?? "Assigned"}',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (member.organization != null) ...[
                Text('Organization: ${member.organization}', style: const TextStyle(fontSize: 13)),
                const SizedBox(height: 6),
              ],
              if (member.city != null) ...[
                Text('City: ${member.city}', style: const TextStyle(fontSize: 13)),
                const SizedBox(height: 6),
              ],
              Text('Location Sharing: ${member.locationSharingEnabled ? "ENABLED" : "OFF"}',
                  style: const TextStyle(fontSize: 13)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
