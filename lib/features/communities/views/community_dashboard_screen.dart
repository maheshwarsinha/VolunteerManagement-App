// lib/features/communities/views/community_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:volunteers_management/core/theme/app_theme.dart';
import 'package:volunteers_management/features/communities/controllers/community_controller.dart';
import 'package:volunteers_management/features/map/controllers/live_map_controller.dart';
import 'package:volunteers_management/features/announcements/repositories/announcement_repository.dart';
import 'package:volunteers_management/features/announcements/models/announcement_model.dart';
import 'package:volunteers_management/shared/widgets/community_switcher_sheet.dart';
import 'package:volunteers_management/features/admin/views/admin_dashboard_screen.dart';

final announcementRepoProvider = Provider<AnnouncementRepository>((ref) {
  return AnnouncementRepository();
});

final announcementsProvider = FutureProvider.family<List<AnnouncementModel>, String>((ref, communityId) {
  return ref.watch(announcementRepoProvider).getAnnouncements(communityId);
});

class CommunityDashboardScreen extends ConsumerWidget {
  final void Function(int tabIndex)? onSwitchTab;

  const CommunityDashboardScreen({super.key, this.onSwitchTab});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final commState = ref.watch(communityProvider);
    final activeComm = commState.activeCommunity;
    final liveMapState = ref.watch(liveMapProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final announcementsAsync = activeComm != null
        ? ref.watch(announcementsProvider(activeComm.id))
        : const AsyncValue.data(<AnnouncementModel>[]);

    final isUserAdmin = activeComm?.currentUserRole?.isAdminOrHigher ?? false;

    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: () {
            showModalBottomSheet(
              context: context,
              backgroundColor: Colors.transparent,
              builder: (_) => const CommunitySwitcherSheet(),
            );
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  activeComm?.name ?? 'Community',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.arrow_drop_down_rounded, size: 24),
            ],
          ),
        ),
        actions: [
          if (isUserAdmin) ...[
            IconButton(
              icon: const Icon(Icons.admin_panel_settings_outlined),
              tooltip: 'Admin Console',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
                );
              },
            ),
          ],
          IconButton(
            icon: const Icon(Icons.qr_code_rounded),
            tooltip: 'Invite Code',
            onPressed: () {
              if (activeComm != null) {
                _showCodeDialog(context, activeComm.code, activeComm.name);
              }
            },
          ),
        ],
      ),
      body: activeComm == null
          ? const Center(child: Text('No community selected'))
          : RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(announcementsProvider(activeComm.id));
              },
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Primary Live Presence Banner / Map Teaser
                    GestureDetector(
                      onTap: () => onSwitchTab?.call(0), // Navigate to Map tab
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isDark
                                ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                                : [const Color(0xFFEFF6FF), const Color(0xFFDBEAFE)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.3),
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppColors.statusOnline.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 8,
                                            height: 8,
                                            decoration: const BoxDecoration(
                                              color: AppColors.statusOnline,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          const Text(
                                            'LIVE RADAR ACTIVE',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.statusOnline,
                                              letterSpacing: 1,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.primary),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Text(
                              '${liveMapState.onlineCount} Volunteers Online',
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Open live community map to view coordinate presence, responder safety, and active mission paths.',
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Metrics Strip: Total Members, Online, Teams, Events
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricCard(
                            label: 'Total Members',
                            value: '${activeComm.memberCount}',
                            icon: Icons.groups_rounded,
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildMetricCard(
                            label: 'Online Now',
                            value: '${liveMapState.onlineCount}',
                            icon: Icons.cell_tower_rounded,
                            iconColor: AppColors.statusOnline,
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildMetricCard(
                            label: 'Inactive/Stale',
                            value: '${liveMapState.staleCount + liveMapState.offlineCount}',
                            icon: Icons.history_toggle_off_rounded,
                            iconColor: AppColors.statusStale,
                            isDark: isDark,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Latest Announcements Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Community Announcements',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 17),
                        ),
                        Text(
                          'Latest Updates',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    announcementsAsync.when(
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20.0),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      error: (err, _) => Text('Failed to load announcements: $err'),
                      data: (announcements) {
                        if (announcements.isEmpty) {
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkCard : AppColors.lightCard,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                            ),
                            child: const Text('No announcements yet for this community.'),
                          );
                        }

                        return Column(
                          children: announcements.map((ann) => _buildAnnouncementCard(ann, isDark)).toList(),
                        );
                      },
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildMetricCard({
    required String label,
    required String value,
    required IconData icon,
    Color? iconColor,
    required bool isDark,
  }) {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: iconColor ?? AppColors.primary),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildAnnouncementCard(AnnouncementModel ann, bool isDark) {
    final isUrgent = ann.isUrgent;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUrgent ? AppColors.error.withOpacity(0.4) : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          width: isUrgent ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (isUrgent) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'PRIORITY ALERT',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.error),
                  ),
                ),
              ],
              Expanded(
                child: Text(
                  ann.title,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            ann.content,
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Posted by ${ann.authorName}',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white38 : Colors.black45,
            ),
          ),
        ],
      ),
    );
  }

  void _showCodeDialog(BuildContext context, String code, String name) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Share this code with volunteers to join:'),
            const SizedBox(height: 14),
            SelectableText(
              code,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
