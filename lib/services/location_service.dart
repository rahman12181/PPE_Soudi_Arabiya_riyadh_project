// lib/services/location_service.dart
// ignore_for_file: deprecated_member_use

import 'dart:async' show TimeoutException;
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  // Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  // Check and request permissions
  Future<Map<String, dynamic>> handlePermissions() async {
    LocationPermission permission = await Geolocator.checkPermission();
    
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return {
          'success': false,
          'error': 'Location permission denied.',
          'type': 'denied',
        };
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      return {
        'success': false,
        'error': 'Location permissions are permanently denied.',
        'type': 'permanent',
      };
    }
    
    return {
      'success': true,
      'type': 'granted',
    };
  }

  // Get current location with retry mechanism
  Future<Map<String, dynamic>> getCurrentLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return {
          'success': false,
          'error': 'GPS is disabled. Please enable GPS.',
          'type': 'gps_disabled',
          'position': null,
        };
      }

      // Check permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return {
            'success': false,
            'error': 'Location permission denied.',
            'type': 'denied',
            'position': null,
          };
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        return {
          'success': false,
          'error': 'Location permissions are permanently denied.',
          'type': 'permanent',
          'position': null,
        };
      }

      // Get location with high accuracy
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      // Validate position
      if (position.latitude == 0 && position.longitude == 0) {
        // Retry once if we got 0,0
        await Future.delayed(const Duration(seconds: 1));
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 10),
        );
        
        // If still 0,0 after retry
        if (position.latitude == 0 && position.longitude == 0) {
          return {
            'success': false,
            'error': 'Invalid location coordinates received.',
            'type': 'invalid',
            'position': null,
          };
        }
      }

      return {
        'success': true,
        'position': position,
        'error': null,
        'type': 'success',
      };
      
    } on TimeoutException catch (_) {
      return {
        'success': false,
        'error': 'Location request timed out. Please try again.',
        'type': 'timeout',
        'position': null,
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Failed to get location: $e',
        'type': 'error',
        'position': null,
      };
    }
  }

  // Get live location specifically for punch (with multiple retries)
  Future<Position> getLiveLocationForPunch() async {
    int maxRetries = 3;
    int retryCount = 0;
    List<String> errors = [];
    
    while (retryCount < maxRetries) {
      try {
        // Check if location services are enabled
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          throw Exception('GPS is disabled. Please enable GPS.');
        }

        // Check permissions
        final permissionResult = await handlePermissions();
        if (!permissionResult['success']) {
          throw Exception(permissionResult['error']);
        }

        // Get location with high accuracy
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 15),
        );

        // Validate position
        if (position.latitude == 0 && position.longitude == 0) {
          errors.add("Attempt ${retryCount + 1}: Invalid coordinates (0,0)");
          retryCount++;
          if (retryCount < maxRetries) {
            await Future.delayed(Duration(seconds: retryCount));
            continue;
          }
          throw Exception('Invalid location coordinates after $maxRetries attempts');
        }

        return position;
        
      } on TimeoutException catch (_) {
        errors.add("Attempt ${retryCount + 1}: Timeout");
        retryCount++;
        if (retryCount >= maxRetries) {
          throw Exception('Location request timed out after $maxRetries attempts');
        }
        await Future.delayed(Duration(seconds: retryCount));
      } catch (e) {
        errors.add("Attempt ${retryCount + 1}: $e");
        retryCount++;
        if (retryCount >= maxRetries) {
          throw Exception('Failed to get location: ${errors.join(", ")}');
        }
        await Future.delayed(Duration(seconds: retryCount));
      }
    }
    
    throw Exception('Failed to get location after $maxRetries attempts');
  }

  // Get address from coordinates
  Future<String> getAddressFromLatLng(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        List<String> addressParts = [];
        
        if (place.name?.isNotEmpty ?? false) addressParts.add(place.name!);
        if (place.subLocality?.isNotEmpty ?? false) addressParts.add(place.subLocality!);
        if (place.locality?.isNotEmpty ?? false) addressParts.add(place.locality!);
        if (place.administrativeArea?.isNotEmpty ?? false) addressParts.add(place.administrativeArea!);
        if (place.country?.isNotEmpty ?? false) addressParts.add(place.country!);
        
        return addressParts.join(', ');
      }
      return "Location found";
    } catch (e) {
      debugPrint("Error getting address: $e");
      return "Location found";
    }
  }

  // Open location settings
  Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }

  // Open app settings
  Future<void> openAppSettings() async {
    await Geolocator.openAppSettings();
  }

  // Request location permission
  Future<LocationPermission> requestLocationPermission() async {
    return await Geolocator.requestPermission();
  }
}