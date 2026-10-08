// lib/features/map/views/live_map_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:volunteers_management/core/theme/app_theme.dart';
import 'package:volunteers_management/core/services/map_service.dart';
import 'package:volunteers_management/features/map/controllers/live_map_controller.dart';
import 'package:volunteers_management/features/map/models/live_location_model.dart';
import 'package:volunteers_management/features/communities/controllers/community_controller.dart';
import 'package:volunteers_management/features/auth/controllers/auth_controller.dart';
import 'package:volunteers_management/features/map/views/member_location_bottom_sheet.dart';
import 'package:volunteers_management/shared/widgets/community_switcher_sheet.dart';

class LiveMapScreen extends ConsumerStatefulWidget {
  const LiveMapScreen({super.key});

  @override
  ConsumerState<LiveMapScreen> createState() => _LiveMapScreenState();
}

class _LiveMapScreenState extends ConsumerState<LiveMapScreen> {
  final MapController _mapController = MapController();
  final MapService _mapService = OsmFlutterMapService();
  final TextEditingController _searchController = TextEditingController();

  static const LatLng _defaultCenter = LatLng(26.4499, 80.3319); // Default field coordinates

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _recenterMap(LatLng target, {double zoom = 14.5}) {
    _mapController.move(target, zoom);
  }

  void _fitAllMarkers(List<LiveLocationModel> locations) {
    if (locations.isEmpty) {
      _recenterMap(_defaultCenter);
      return;
    }

    final points = locations.map((l) => l.coordinates).toList();
    if (points.length == 1) {
      _recenterMap(points.first, zoom: 15.0);
      return;
    }

    final bounds = _mapService.calculateBounds(points);
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(60.0),
      ),
    );
  }

  void _showMemberDetails(LiveLocationModel member) {
    ref.read(liveMapProvider.notifier).selectMember(member);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => MemberLocationBottomSheet(
        location: member,
        onClose: () {
          ref.read(liveMapProvider.notifier).selectMember(null);
          Navigator.of(context).pop();
        },
      ),
    );
  }

  List<Marker> _buildMapMarkers(List<LiveLocationModel> locations, LiveLocationModel? selectedMember) {
    return locations.map((loc) {
      final isSelected = selectedMember?.userId == loc.userId;
      final isOnline = loc.activityStatus == MarkerActivityStatus.online;
      final markerColor = loc.activityStatus.color;

      return Marker(
        point: loc.coordinates,
        width: isSelected ? 56 : 48,
        height: isSelected ? 56 : 48,
        child: GestureDetector(
          onTap: () => _showMemberDetails(loc),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(
                color: markerColor,
                width: isSelected ? 3.5 : 2.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: markerColor.withOpacity(isOnline ? 0.45 : 0.2),
                  blurRadius: isSelected ? 12 : 8,
                  spreadRadius: isSelected ? 3 : 1,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Text(
                    loc.fullName.isNotEmpty ? loc.fullName[0].toUpperCase() : 'V',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: markerColor,
                    ),
                  ),
                  // Small presence dot in the corner
                  Positioned(
                    right: 2,
                    top: 2,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: markerColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final liveMapState = ref.watch(liveMapProvider);
    final commState = ref.watch(communityProvider);
    final authState = ref.watch(authProvider);
    final activeComm = commState.activeCommunity;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filteredLocations = liveMapState.filteredLocations;
    final markers = _buildMapMarkers(filteredLocations, liveMapState.selectedMember);

    final isSharingActive = liveMapState.isTrackingActive ||
        (authState.user?.locationSharingEnabled ?? false);

    return Scaffold(
      body: Stack(
        children: [
          // 1. Full-screen OpenStreetMap via MapService abstraction
          Positioned.fill(
            child: _mapService.buildMap(
              initialCenter: filteredLocations.isNotEmpty
                  ? filteredLocations.first.coordinates
                  : _defaultCenter,
              initialZoom: 14.0,
              markers: markers,
              mapController: _mapController,
              onTap: (_, __) {
                if (liveMapState.selectedMember != null) {
                  ref.read(liveMapProvider.notifier).selectMember(null);
                }
              },
            ),
          ),

          // 2. Top Floating Navigation & Search Bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Community Selector Header Card
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface.withOpacity(0.92) : Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Center(
                            child: Icon(Icons.shield_rounded, size: 20, color: AppColors.primary),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                activeComm?.name ?? 'No Community Active',
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '${activeComm?.memberCount ?? 0} members • Code: ${activeComm?.code ?? "---"}',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.swap_horiz_rounded, size: 22),
                          tooltip: 'Switch Community',
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              backgroundColor: Colors.transparent,
                              builder: (_) => const CommunitySwitcherSheet(),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Search Field
                  Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface.withOpacity(0.92) : Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                        width: 1,
                      ),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) => ref.read(liveMapProvider.notifier).setSearchQuery(val),
                      decoration: InputDecoration(
                        hintText: 'Search volunteers, roles or teams...',
                        prefixIcon: const Icon(Icons.search_rounded, size: 18),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 16),
                                onPressed: () {
                                  _searchController.clear();
                                  ref.read(liveMapProvider.notifier).setSearchQuery('');
                                },
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Presence Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip(
                          label: 'All (${liveMapState.allLocations.length})',
                          isSelected: liveMapState.selectedStatusFilter == 'all',
                          onTap: () => ref.read(liveMapProvider.notifier).setStatusFilter('all'),
                          isDark: isDark,
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          label: '🟢 Online (${liveMapState.onlineCount})',
                          isSelected: liveMapState.selectedStatusFilter == 'online',
                          onTap: () => ref.read(liveMapProvider.notifier).setStatusFilter('online'),
                          isDark: isDark,
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          label: '⚪ Stale (${liveMapState.staleCount})',
                          isSelected: liveMapState.selectedStatusFilter == 'stale',
                          onTap: () => ref.read(liveMapProvider.notifier).setStatusFilter('stale'),
                          isDark: isDark,
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          label: 'Offline (${liveMapState.offlineCount})',
                          isSelected: liveMapState.selectedStatusFilter == 'offline',
                          onTap: () => ref.read(liveMapProvider.notifier).setStatusFilter('offline'),
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. Floating Map Controls (Right side: Recenter, Fit Bounds)
          Positioned(
            right: 16,
            bottom: 110,
            child: Column(
              children: [
                _buildFloatingCircleButton(
                  icon: Icons.filter_center_focus_rounded,
                  tooltip: 'Fit All Responders',
                  onTap: () => _fitAllMarkers(filteredLocations),
                  isDark: isDark,
                ),
                const SizedBox(height: 12),
                _buildFloatingCircleButton(
                  icon: Icons.my_location_rounded,
                  tooltip: 'Recenter Map',
                  onTap: () {
                    if (filteredLocations.isNotEmpty) {
                      _recenterMap(filteredLocations.first.coordinates);
                    } else {
                      _recenterMap(_defaultCenter);
                    }
                  },
                  isDark: isDark,
                ),
              ],
            ),
          ),

          // 4. Bottom Location Sharing Transparency Bar
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface.withOpacity(0.95) : Colors.white.withOpacity(0.98),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSharingActive
                      ? AppColors.statusOnline.withOpacity(0.4)
                      : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: isSharingActive ? AppColors.statusOnline : AppColors.statusOffline,
                      shape: BoxShape.circle,
                      boxShadow: isSharingActive
                          ? [
                              BoxShadow(
                                color: AppColors.statusOnline.withOpacity(0.6),
                                blurRadius: 6,
                                spreadRadius: 2,
                              ),
                            ]
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isSharingActive ? 'Live Location: ACTIVE' : 'Live Location: OFF',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: isSharingActive ? AppColors.statusOnline : null,
                          ),
                        ),
                        Text(
                          isSharingActive ? 'Throttled (30m / 30s) • Battery-conscious' : 'Not visible to team members',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      if (isSharingActive) {
                        ref.read(liveMapProvider.notifier).stopBroadcasting();
                      } else {
                        ref.read(liveMapProvider.notifier).startBroadcasting();
                      }
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: isSharingActive ? AppColors.error : AppColors.primary,
                      textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                    child: Text(isSharingActive ? 'STOP SHARING' : 'SHARE NOW'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : (isDark ? AppColors.darkSurface.withOpacity(0.9) : Colors.white.withOpacity(0.9)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
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

  Widget _buildFloatingCircleButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, size: 20, color: AppColors.primary),
        tooltip: tooltip,
        onPressed: onTap,
      ),
    );
  }
}
