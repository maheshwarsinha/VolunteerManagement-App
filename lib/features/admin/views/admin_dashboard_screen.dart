// lib/features/admin/views/admin_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:volunteers_management/core/theme/app_theme.dart';
import 'package:volunteers_management/features/communities/controllers/community_controller.dart';
import 'package:volunteers_management/features/map/controllers/live_map_controller.dart';
import 'package:volunteers_management/features/announcements/repositories/announcement_repository.dart';
import 'package:volunteers_management/features/communities/views/community_dashboard_screen.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  final _announcementTitleController = TextEditingController();
  final _announcementContentController = TextEditingController();
  String _announcementPriority = 'normal';
  bool _isPostingAnnouncement = false;

  @override
  void dispose() {
    _announcementTitleController.dispose();
    _announcementContentController.dispose();
    super.dispose();
  }

  Future<void> _handleRegenerateCode() async {
    final comm = ref.read(communityProvider).activeCommunity;
    if (comm == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Regenerate Invite Code?'),
        content: const Text(
          'Existing code will be permanently invalidated. Anyone trying to join with the old code will be rejected.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Regenerate Now'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final newCode = await ref.read(communityProvider.notifier).regenerateCommunityCode();
      if (mounted && newCode != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('New community code generated: $newCode')),
        );
      }
    }
  }

  Future<void> _handleBroadcastAnnouncement() async {
    final title = _announcementTitleController.text.trim();
    final content = _announcementContentController.text.trim();
    final comm = ref.read(communityProvider).activeCommunity;

    if (title.isEmpty || content.isEmpty || comm == null) return;

    setState(() => _isPostingAnnouncement = true);

    await ref.read(announcementRepoProvider).createAnnouncement(
      communityId: comm.id,
      authorId: 'admin-id',
      title: title,
      content: content,
      priority: _announcementPriority,
    );

    ref.invalidate(announcementsProvider(comm.id));

    _announcementTitleController.clear();
    _announcementContentController.clear();
    setState(() => _isPostingAnnouncement = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Announcement broadcast to community members!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final commState = ref.watch(communityProvider);
    final activeComm = commState.activeCommunity;
    final liveMapState = ref.watch(liveMapProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (activeComm == null) {
      return const Scaffold(body: Center(child: Text('No community selected')));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Console'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Community Access Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : AppColors.lightCard,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('COMMUNITY CODE', style: TextStyle(fontSize: 11, letterSpacing: 1.5, fontWeight: FontWeight.w700)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.success.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text('Active', style: TextStyle(fontSize: 11, color: AppColors.success, fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        SelectableText(
                          activeComm.code,
                          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: AppColors.primary, letterSpacing: 2),
                        ),
                        const SizedBox(width: 12),
                        IconButton(
                          icon: const Icon(Icons.copy_rounded, size: 20),
                          tooltip: 'Copy',
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: activeComm.code));
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied!')));
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _handleRegenerateCode,
                      icon: const Icon(Icons.refresh_rounded, size: 16),
                      label: const Text('Regenerate Code'),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Operational Metrics
              Text('Operational Readiness', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 16)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildMetricTile(
                      label: 'Total Registered',
                      value: '${activeComm.memberCount}',
                      color: AppColors.primary,
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricTile(
                      label: 'Online on Map',
                      value: '${liveMapState.onlineCount}',
                      color: AppColors.statusOnline,
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildMetricTile(
                      label: 'Stale (>5m)',
                      value: '${liveMapState.staleCount}',
                      color: AppColors.statusStale,
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricTile(
                      label: 'Offline (>15m)',
                      value: '${liveMapState.offlineCount}',
                      color: AppColors.statusOffline,
                      isDark: isDark,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Broadcast Announcement Box
              Text('Broadcast Priority Announcement', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 16)),
              const SizedBox(height: 8),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : AppColors.lightCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _announcementTitleController,
                      decoration: const InputDecoration(hintText: 'Announcement Title'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _announcementContentController,
                      maxLines: 3,
                      decoration: const InputDecoration(hintText: 'Details for all volunteers...'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _announcementPriority,
                      decoration: const InputDecoration(prefixIcon: Icon(Icons.priority_high_rounded)),
                      items: const [
                        DropdownMenuItem(value: 'normal', child: Text('Normal Priority')),
                        DropdownMenuItem(value: 'urgent', child: Text('Urgent Alert')),
                        DropdownMenuItem(value: 'emergency', child: Text('Emergency SOS')),
                      ],
                      onChanged: (val) => setState(() => _announcementPriority = val!),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _isPostingAnnouncement ? null : _handleBroadcastAnnouncement,
                      child: _isPostingAnnouncement
                          ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white))
                          : const Text('Broadcast Announcement'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 22, color: color)),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
