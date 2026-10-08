// lib/features/profile/views/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:volunteers_management/core/theme/app_theme.dart';
import 'package:volunteers_management/features/auth/controllers/auth_controller.dart';
import 'package:volunteers_management/features/communities/controllers/community_controller.dart';
import 'package:volunteers_management/features/map/controllers/live_map_controller.dart';
import 'package:volunteers_management/features/auth/views/welcome_screen.dart';
import 'package:volunteers_management/features/admin/views/admin_dashboard_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final commState = ref.watch(communityProvider);
    final activeComm = commState.activeCommunity;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final isUserAdmin = activeComm?.currentUserRole?.isAdminOrHigher ?? false;

    if (user == null) {
      return const Scaffold(body: Center(child: Text('User profile unavailable')));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Volunteer Profile'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // User Identification Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : AppColors.lightCard,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: AppColors.primary.withOpacity(0.15),
                      child: Text(
                        user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : 'V',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 26, color: AppColors.primary),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.fullName,
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '@${user.username} • ${activeComm?.currentUserRole?.displayName ?? "Volunteer"}',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'ID: ${user.volunteerId ?? "VORTEX-LOCAL"}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Section: Location Privacy & Diagnostics
              Text(
                'Location Privacy & Battery',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 16),
              ),
              const SizedBox(height: 8),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : AppColors.lightCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                ),
                child: Column(
                  children: [
                    SwitchListTile.adaptive(
                      value: user.locationSharingEnabled,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (val) {
                        if (val) {
                          ref.read(liveMapProvider.notifier).startBroadcasting();
                        } else {
                          ref.read(liveMapProvider.notifier).stopBroadcasting();
                        }
                      },
                      title: const Text(
                        'Live Location Sharing',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                      subtitle: Text(
                        user.locationSharingEnabled
                            ? 'Broadcasting coordinates (>30m filter, 30s throttle)'
                            : 'Sharing is disabled. Invisible on community map.',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    const Divider(),
                    _buildDiagnosticRow(
                      label: 'Battery Profile',
                      value: 'Balanced & Optimized (No GPS Polling)',
                      isDark: isDark,
                    ),
                    const SizedBox(height: 8),
                    _buildDiagnosticRow(
                      label: 'Snapshot Retention',
                      value: '${activeComm?.locationRetentionDays ?? 30} Days (Auto Pruned)',
                      isDark: isDark,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Section: Skills & Details
              if (user.skills.isNotEmpty) ...[
                Text(
                  'Volunteer Skills',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 16),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: user.skills.map((s) {
                    return Chip(
                      label: Text(s, style: const TextStyle(fontSize: 12)),
                      backgroundColor: isDark ? AppColors.darkCard : const Color(0xFFF1F5F9),
                      side: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
              ],

              // Admin Panel Shortcut (if admin)
              if (isUserAdmin) ...[
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(color: AppColors.primary.withOpacity(0.3)),
                  ),
                  tileColor: AppColors.primary.withOpacity(0.06),
                  leading: const Icon(Icons.admin_panel_settings_rounded, color: AppColors.primary),
                  title: const Text('Community Admin Controls', style: TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: const Text('Manage members, teams, code regeneration & policies', style: TextStyle(fontSize: 12)),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
                    );
                  },
                ),
                const SizedBox(height: 16),
              ],

              // Logout Button
              OutlinedButton.icon(
                onPressed: () async {
                  await ref.read(liveMapProvider.notifier).stopBroadcasting();
                  await ref.read(authProvider.notifier).logout();
                  if (context.mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                      (route) => false,
                    );
                  }
                },
                icon: const Icon(Icons.logout_rounded, size: 18, color: AppColors.error),
                label: const Text('Sign Out Session', style: TextStyle(color: AppColors.error)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: const BorderSide(color: AppColors.error, width: 1.2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDiagnosticRow({required String label, required String value, required bool isDark}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
