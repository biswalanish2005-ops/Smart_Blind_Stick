/// Records an SOS emergency incident triggered by button or fall.
class SosEvent {
  final String eventId;
  final String type; // "FALL" | "BUTTON" | "MANUAL"
  final DateTime timestamp;
  final double? latitude;
  final double? longitude;
  final String? mapsUrl;
  final bool acknowledged;
  final DateTime? resolvedAt;

  SosEvent({
    required this.eventId,
    required this.type,
    required this.timestamp,
    this.latitude,
    this.longitude,
    this.mapsUrl,
    this.acknowledged = false,
    this.resolvedAt,
  });

  SosEvent copyWith({
    String? eventId,
    String? type,
    DateTime? timestamp,
    double? latitude,
    double? longitude,
    String? mapsUrl,
    bool? acknowledged,
    DateTime? resolvedAt,
  }) {
    return SosEvent(
      eventId: eventId ?? this.eventId,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      mapsUrl: mapsUrl ?? this.mapsUrl,
      acknowledged: acknowledged ?? this.acknowledged,
      resolvedAt: resolvedAt ?? this.resolvedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'event_id': eventId,
      'type': type,
      'timestamp': timestamp.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
      'maps_url': mapsUrl,
      'acknowledged': acknowledged,
      'resolved_at': resolvedAt?.toIso8601String(),
    };
  }

  factory SosEvent.fromJson(Map<String, dynamic> json) {
    return SosEvent(
      eventId: json['event_id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      type: json['type']?.toString() ?? 'BUTTON',
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
      latitude: json['latitude'] is num ? (json['latitude'] as num).toDouble() : null,
      longitude: json['longitude'] is num ? (json['longitude'] as num).toDouble() : null,
      mapsUrl: json['maps_url']?.toString(),
      acknowledged: json['acknowledged'] == true,
      resolvedAt: json['resolved_at'] != null
          ? DateTime.tryParse(json['resolved_at'].toString())
          : null,
    );
  }
}
