// lib/core/services/map_service.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Abstract Map Service allowing plug-and-play migration between
/// OpenStreetMap, MapLibre, Mapbox, or Google Maps in the future.
abstract class MapService {
  String get name;
  Widget buildMap({
    required LatLng initialCenter,
    required double initialZoom,
    required List<Marker> markers,
    required MapController mapController,
    void Function(TapPosition, LatLng)? onTap,
  });

  LatLngBounds calculateBounds(List<LatLng> points);
}

/// OpenStreetMap / Free Tile Implementation using flutter_map
/// Uses CartoDB Positron & OSM tile server - 100% Free, Zero API Key required.
class OsmFlutterMapService implements MapService {
  @override
  String get name => 'OpenStreetMap (CartoDB Positron / OSM)';

  // Fast, clean, modern grey-light tile style (CartoDB Positron)
  // or OpenStreetMap standard tiles
  final String tileUrl = 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}@2x.png';
  final List<String> subdomains = const ['a', 'b', 'c', 'd'];

  @override
  Widget buildMap({
    required LatLng initialCenter,
    required double initialZoom,
    required List<Marker> markers,
    required MapController mapController,
    void Function(TapPosition, LatLng)? onTap,
  }) {
    return FlutterMap(
      mapController: mapController,
      options: MapOptions(
        initialCenter: initialCenter,
        initialZoom: initialZoom,
        minZoom: 3,
        maxZoom: 19,
        onTap: onTap,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: tileUrl,
          subdomains: subdomains,
          userAgentPackageName: 'com.vortex.volunteers',
          maxZoom: 19,
        ),
        MarkerLayer(
          markers: markers,
        ),
      ],
    );
  }

  @override
  LatLngBounds calculateBounds(List<LatLng> points) {
    if (points.isEmpty) {
      return LatLngBounds(
        const LatLng(20.5937, 78.9629),
        const LatLng(20.5937, 78.9629),
      );
    }
    return LatLngBounds.fromPoints(points);
  }
}
