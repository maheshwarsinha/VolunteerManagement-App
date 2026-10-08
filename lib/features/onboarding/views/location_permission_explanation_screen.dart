// lib/features/onboarding/views/location_permission_explanation_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:volunteers_management/core/theme/app_theme.dart';
import 'package:volunteers_management/features/map/controllers/live_map_controller.dart';
import 'package:volunteers_management/features/communities/controllers/community_controller.dart';
import 'package:volunteers_management/features/communities/views/community_setup_screen.dart';
import 'package:volunteers_management/features/shared/views/main_shell_screen.dart';

class LocationPermissionExplanationScreen extends ConsumerStatefulWidget {
  const LocationPermissionExplanationScreen({super.key});

  @override
  ConsumerState<LocationPermissionExplanationScreen> createState() =>
      _LocationPermissionExplanationScreenState();
}

class _LocationPermissionExplanationScreenState
    extends ConsumerState<LocationPermissionExplanationScreen> {
  bool _isRequesting = false;
  String? _statusMessage;
  bool _permanentlyDenied = false;

  Future<void> _proceedToNext() async {
    final commState = ref.read(communityProvider);
    await ref.read(communityProvider.notifier).loadCommunities();

    if (!mounted) return;
    if (commState.activeCommunity != null || commState.userCommunities.isNotEmpty) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainShellScreen()),
        (route) => false,
      );
    } else {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const CommunitySetupScreen()),
        (route) => false,
      );
    }
  }

  Future<void> _requestLocationPermission() async {
    setState(() {
      _isRequesting = true;
      _statusMessage = null;
    });

    try {
      final locService = ref.read(locationServiceProvider);
      LocationPermission perm = await locService.checkPermission();

      if (perm == LocationPermission.denied) {
        perm = await locService.requestPermission();
      }

      if (perm == LocationPermission.deniedForever) {
        setState(() {
          _isRequesting = false;
          _permanentlyDenied = true;
          _statusMessage =
              'Location permission is permanently denied. You can open system settings to grant it, or continue with location sharing turned off.';
        });
      } else if (perm == LocationPermission.always || perm == LocationPermission.whileInUse) {
        // Permission granted
        await _proceedToNext();
      } else {
        setState(() {
          _isRequesting = false;
          _statusMessage = 'Permission was not granted. You can still continue without live location.';
        });
      }
    } catch (e) {
      setState(() {
        _isRequesting = false;
        _statusMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Location Transparency'),
        actions: [
          TextButton(
            onPressed: _proceedToNext,
            child: const Text('Skip for Now'),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Icon
              Center(
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(Icons.location_on_rounded, size: 36, color: AppColors.primary),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Text(
                'How Live Location is Used',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 22),
              ),
              const SizedBox(height: 8),
              Text(
                'We believe in absolute privacy transparency. Review how and when your coordinates are accessed.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 28),

              // Educational Privacy Points
              _buildPrivacyCard(
                icon: Icons.shield_outlined,
                title: 'Why Location is Needed',
                description:
                    'To display your marker on the community live map during field missions and disaster coordination so team leads can verify your safety.',
              ),
              const SizedBox(height: 12),
              _buildPrivacyCard(
                icon: Icons.battery_charging_full_rounded,
                title: 'What is Collected & Battery Impact',
                description:
                    'Only latitude, longitude, and accuracy. Battery-conscious distance filtering (>30m) is used. No continuous high-drain GPS polling.',
              ),
              const SizedBox(height: 12),
              _buildPrivacyCard(
                icon: Icons.visibility_outlined,
                title: 'Who Can See It',
                description:
                    'Only verified active members in your currently selected community. It is never sold, publicized, or accessible across communities.',
              ),
              const SizedBox(height: 12),
              _buildPrivacyCard(
                icon: Icons.history_rounded,
                title: 'Data Retention & History',
                description:
                    'Ephemeral live locations are kept in memory. Historical snapshots are kept for 30 days and then automatically deleted by database policy.',
              ),
              const SizedBox(height: 12),
              _buildPrivacyCard(
                icon: Icons.toggle_on_outlined,
                title: 'How to Stop Sharing',
                description:
                    'You have full control. You can toggle Location Sharing OFF at any time with a single tap on the live map.',
              ),

              if (_statusMessage != null) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        _statusMessage!,
                        style: const TextStyle(fontSize: 13, color: AppColors.warning),
                        textAlign: TextAlign.center,
                      ),
                      if (_permanentlyDenied) ...[
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => Geolocator.openAppSettings(),
                          child: const Text('Open Device Settings'),
                        ),
                      ],
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 32),

              ElevatedButton.icon(
                onPressed: _isRequesting ? null : _requestLocationPermission,
                icon: _isRequesting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.check_circle_outline_rounded, size: 20),
                label: const Text('Understand & Enable Location'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _proceedToNext,
                child: const Text('Continue with Location Sharing OFF'),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrivacyCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: AppColors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.4,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
