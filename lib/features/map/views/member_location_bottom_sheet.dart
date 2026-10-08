// lib/features/map/views/member_location_bottom_sheet.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:volunteers_management/core/theme/app_theme.dart';
import 'package:volunteers_management/features/map/models/live_location_model.dart';
import 'package:volunteers_management/shared/widgets/status_badge.dart';

class MemberLocationBottomSheet extends StatelessWidget {
  final LiveLocationModel location;
  final VoidCallback? onClose;

  const MemberLocationBottomSheet({
    super.key,
    required this.location,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final timeStr = DateFormat('hh:mm a').format(location.lastUpdatedAt);
    final diffMinutes = DateTime.now().difference(location.lastUpdatedAt).inMinutes;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle bar
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

              // Header: Avatar, Name, Role & Status Badge
              Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: AppColors.primary.withOpacity(0.15),
                    child: Text(
                      location.fullName.isNotEmpty ? location.fullName[0].toUpperCase() : 'V',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                location.fullName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 17,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            StatusBadge(status: location.activityStatus),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '@${location.username} • ${location.role.displayName}',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: onClose ?? () => Navigator.of(context).pop(),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),

              // Metadata grid: Team, Coordinates, Last Seen
              Row(
                children: [
                  Expanded(
                    child: _buildInfoItem(
                      icon: Icons.groups_outlined,
                      label: 'Assigned Team',
                      value: location.teamName ?? 'General Pool',
                      isDark: isDark,
                    ),
                  ),
                  Expanded(
                    child: _buildInfoItem(
                      icon: Icons.access_time_rounded,
                      label: 'Last Broadcast',
                      value: diffMinutes < 1 ? 'Just now' : '$diffMinutes mins ago ($timeStr)',
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildInfoItem(
                      icon: Icons.gps_fixed_rounded,
                      label: 'GPS Accuracy',
                      value: location.accuracy != null ? '±${location.accuracy!.toStringAsFixed(1)}m' : 'Standard',
                      isDark: isDark,
                    ),
                  ),
                  Expanded(
                    child: _buildInfoItem(
                      icon: Icons.badge_outlined,
                      label: 'Volunteer ID',
                      value: location.volunteerId ?? 'Active Responder',
                      isDark: isDark,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Contact action (if phone is shared/authorized)
              if (location.phone != null) ...[
                OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Contacting ${location.fullName}: ${location.phone}')),
                    );
                  },
                  icon: const Icon(Icons.phone_outlined, size: 18),
                  label: Text('Call ${location.phone}'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 16,
          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
