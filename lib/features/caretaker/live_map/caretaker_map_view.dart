import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/accessibility_utils.dart';
import '../../../models/location_data.dart';

class CaretakerMapView extends StatefulWidget {
  final LocationData? locationData;
  final bool isSosActive;

  const CaretakerMapView({
    super.key,
    required this.locationData,
    this.isSosActive = false,
  });

  @override
  State<CaretakerMapView> createState() => _CaretakerMapViewState();
}

class _CaretakerMapViewState extends State<CaretakerMapView> {
  final MapController _mapController = MapController();

  // Fallback initial location if GPS not yet acquired (Center of India / Default)
  static const LatLng _fallbackCenter = LatLng(20.5937, 78.9629);

  @override
  void didUpdateWidget(covariant CaretakerMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.locationData != null &&
        (oldWidget.locationData == null ||
            oldWidget.locationData!.latitude != widget.locationData!.latitude ||
            oldWidget.locationData!.longitude != widget.locationData!.longitude)) {
      _mapController.move(
        LatLng(widget.locationData!.latitude, widget.locationData!.longitude),
        16.0,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = widget.locationData;
    final LatLng currentPoint = loc != null
        ? LatLng(loc.latitude, loc.longitude)
        : _fallbackCenter;

    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: currentPoint,
              initialZoom: loc != null ? 16.0 : 4.5,
              maxZoom: 18.0,
              minZoom: 3.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.safepath.app.safepath',
              ),
              if (loc != null) ...[
                // Accuracy circle
                CircleLayer(
                  circles: [
                    CircleMarker(
                      point: currentPoint,
                      radius: loc.accuracy.clamp(10.0, 50.0),
                      useRadiusInMeter: false,
                      color: (widget.isSosActive
                              ? AppColors.dangerRed
                              : AppColors.caretakerPrimary)
                          .withAlpha(50),
                      borderColor: widget.isSosActive
                          ? AppColors.dangerRed
                          : AppColors.caretakerPrimary,
                      borderStrokeWidth: 2,
                    ),
                  ],
                ),
                // Marker
                MarkerLayer(
                  markers: [
                    Marker(
                      point: currentPoint,
                      width: 50,
                      height: 50,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: widget.isSosActive
                              ? AppColors.dangerRed
                              : AppColors.caretakerPrimary,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(100),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                        child: const Icon(
                          Icons.blind,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),

        // Live Telemetry Overlay Pills
        Positioned(
          top: 12,
          left: 12,
          right: 12,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Staleness & Update pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(200),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: loc == null || loc.isStale
                        ? AppColors.dangerRed
                        : AppColors.safeGreen,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.circle,
                      size: 10,
                      color: loc == null || loc.isStale
                          ? AppColors.dangerRed
                          : AppColors.safeGreen,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      loc == null
                          ? 'WAITING FOR GPS...'
                          : loc.isStale
                              ? 'LOCATION STALE (${loc.secondsAgo}s ago)'
                              : 'UPDATED ${loc.secondsAgo}s AGO',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              // Accuracy badge
              if (loc != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(200),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Text(
                    '±${loc.accuracy.toStringAsFixed(0)}m',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Floating Action Buttons (Recenter + External Maps)
        if (loc != null)
          Positioned(
            bottom: 12,
            right: 12,
            child: Column(
              children: [
                FloatingActionButton.small(
                  heroTag: 'recenter_map',
                  backgroundColor: AppColors.surface,
                  foregroundColor: AppColors.highVisYellow,
                  onPressed: () {
                    _mapController.move(currentPoint, 16.5);
                  },
                  tooltip: 'Center on Blind User',
                  child: const Icon(Icons.my_location),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'open_external_map',
                  backgroundColor: AppColors.caretakerPrimary,
                  foregroundColor: Colors.white,
                  onPressed: () {
                    AccessibilityUtils.sendSms(
                      '',
                      'Blind User Location: ${loc.googleMapsUrl}',
                    );
                  },
                  tooltip: 'Open in Google Maps',
                  child: const Icon(Icons.navigation),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
