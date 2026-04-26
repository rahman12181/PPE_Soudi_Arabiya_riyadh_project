import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:management_app/services/auth_service.dart';

class GeofenceService {
  List<Geofence> _cachedGeofences = [];
  DateTime? _lastFetchTime;

  Future<List<Geofence>> fetchGeofences() async {
    if (_cachedGeofences.isNotEmpty &&
        _lastFetchTime != null &&
        DateTime.now().difference(_lastFetchTime!) < const Duration(minutes: 2)) {
      return _cachedGeofences;
    }
    try {
      final response = await AuthService.client.get(
        Uri.parse("https://ppecon.erpnext.com/api/resource/Geofence?fields=[\"*\"]"),
        headers: {"Cookie": AuthService.cookies.join("; ")},
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> decoded = jsonDecode(response.body);
        final List<dynamic> records = decoded['data'];
        
        _cachedGeofences = records.map((e) => Geofence.fromJson(e)).toList();
        _lastFetchTime = DateTime.now();
        
        print("========== GEOFENCE LIST ==========");
        print("Total Geofences: ${_cachedGeofences.length}");
        for (var gf in _cachedGeofences) {
          print("-----------------------------------");
          print("ID: ${gf.id}");
          print("Latitude: ${gf.latitude}");
          print("Longitude: ${gf.longitude}");
          print("Radius: ${gf.radius} meters");
        }
        print("====================================");
        
      } else {
        debugPrint("❌ Failed to fetch geofences: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("❌ Geofence fetch error: $e");
    }

    return _cachedGeofences;
  }

  Future<bool> isWithinAnyGeofence(Position position) async {
    final geofences = await fetchGeofences();
    if (geofences.isEmpty) {
      return false;
    }
    
    print("========== LOCATION CHECK ==========");
    print("Current Location - Lat: ${position.latitude}, Lng: ${position.longitude}");
    
    for (var gf in geofences) {
      double distance = gf.distanceTo(position);
      bool isInside = distance <= gf.radius;
      print("Checking ${gf.id}: Distance = ${distance.toStringAsFixed(2)}m, Radius = ${gf.radius}m, Inside = $isInside");
      if (isInside) return true;
    }
    print("Result: NOT inside any geofence");
    print("====================================");
    return false;
  }

  void clearCache() {
    _cachedGeofences.clear();
    _lastFetchTime = null;
  }
}

class Geofence {
  final String id;
  final double latitude;
  final double longitude;
  final double radius;

  Geofence({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.radius,
  });

  factory Geofence.fromJson(Map<String, dynamic> json) {
    double toDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    double lat = toDouble(json['latitude']);
    double lng = toDouble(json['longitude']);
    double rad = toDouble(json['range_in_meter'] ?? json['radius']);

    if (lat == 0.0) lat = toDouble(json['Latitude']);
    if (lng == 0.0) lng = toDouble(json['Longitude']);
    if (rad == 0.0) rad = toDouble(json['Range(In Meter)']);

    return Geofence(
      id: json['name'] ?? '',
      latitude: lat,
      longitude: lng,
      radius: rad,
    );
  }

  bool isInside(Position position) {
    double distance = _haversineDistance(
      position.latitude, position.longitude,
      latitude, longitude,
    );
    return distance <= radius;
  }

  double distanceTo(Position position) {
    return _haversineDistance(
      position.latitude, position.longitude,
      latitude, longitude,
    );
  }

  // Haversine Formula with sin()
  double _haversineDistance(double lat1, double lon1, double lat2, double lon2) {
    const double R = 6371000;
    double dLat = (lat2 - lat1) * math.pi / 180;
    double dLon = (lon2 - lon1) * math.pi / 180;
    double a = math.sin(dLat / 2) * math.sin(dLat / 2) +  
               math.cos(lat1 * math.pi / 180) *
               math.cos(lat2 * math.pi / 180) *
               math.sin(dLon / 2) * math.sin(dLon / 2);    
    double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return R * c;
  }
}