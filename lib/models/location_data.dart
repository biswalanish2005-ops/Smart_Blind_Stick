/// Real Phone GPS coordinates and metadata for SafePath
class LocationData {
  final double latitude;
  final double longitude;
  final double accuracy;
  final double speed;
  final double heading;
  final DateTime timestamp;

  LocationData({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.speed,
    required this.heading,
    required this.timestamp,
  });

  /// Google Maps navigational hyperlink
  String get googleMapsUrl =>
      'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';

  /// Evaluates whether location update is stale (> 45 seconds old)
  bool get isStale {
    return DateTime.now().difference(timestamp).inSeconds > 45;
  }

  int get secondsAgo => DateTime.now().difference(timestamp).inSeconds;

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'speed': speed,
      'heading': heading,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory LocationData.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic val, [double fallback = 0.0]) {
      if (val == null) return fallback;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString()) ?? fallback;
    }

    return LocationData(
      latitude: parseDouble(json['latitude']),
      longitude: parseDouble(json['longitude']),
      accuracy: parseDouble(json['accuracy']),
      speed: parseDouble(json['speed']),
      heading: parseDouble(json['heading']),
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
