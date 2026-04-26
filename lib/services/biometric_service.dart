import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:app_settings/app_settings.dart';

enum BiometricStatus {
  available,
  noHardware,
  notEnrolled,
  error,
}

enum BiometricErrorType {
  none,
  canceled,
  notAvailable,
  tooManyAttempts,
  hardwareError,
  lockedOut,
  notEnrolled,
}

class BiometricResult {
  final bool success;
  final BiometricErrorType errorType;
  final String message;

  BiometricResult({
    required this.success,
    required this.errorType,
    required this.message,
  });

  factory BiometricResult.success() => BiometricResult(
        success: true,
        errorType: BiometricErrorType.none,
        message: 'Authentication successful',
      );

  factory BiometricResult.canceled() => BiometricResult(
        success: false,
        errorType: BiometricErrorType.canceled,
        message: 'Authentication cancelled',
      );

  factory BiometricResult.lockedOut() => BiometricResult(
        success: false,
        errorType: BiometricErrorType.lockedOut,
        message: 'Too many failed attempts. Please try after 30 seconds',
      );

  factory BiometricResult.notEnrolled() => BiometricResult(
        success: false,
        errorType: BiometricErrorType.notEnrolled,
        message: 'No fingerprint enrolled. Please add fingerprint in settings',
      );

  factory BiometricResult.notAvailable() => BiometricResult(
        success: false,
        errorType: BiometricErrorType.notAvailable,
        message: 'Biometric hardware not available',
      );

  factory BiometricResult.hardwareError(String error) => BiometricResult(
        success: false,
        errorType: BiometricErrorType.hardwareError,
        message: 'Hardware error: $error',
      );
}

class BiometricService {
  static final LocalAuthentication _localAuth = LocalAuthentication();
  static const int _maxAttempts = 3;
  static int _attemptCount = 0;
  static DateTime? _lastAttemptTime;
  static const Duration _cooldownPeriod = Duration(seconds: 30);
  static bool _isAuthenticating = false;

  // Reset attempt counter after cooldown
  static void _checkAndResetAttempts() {
    if (_lastAttemptTime != null) {
      final timeSinceLastAttempt = DateTime.now().difference(_lastAttemptTime!);
      if (timeSinceLastAttempt > _cooldownPeriod) {
        _attemptCount = 0;
      }
    }
  }

  // Check if user is in cooldown period
  static bool _isInCooldown() {
    if (_attemptCount >= _maxAttempts && _lastAttemptTime != null) {
      final timeSinceLastAttempt = DateTime.now().difference(_lastAttemptTime!);
      if (timeSinceLastAttempt < _cooldownPeriod) {
        return true;
      }
    }
    return false;
  }

  // Get remaining cooldown seconds
  static int getRemainingCooldownSeconds() {
    if (_attemptCount >= _maxAttempts && _lastAttemptTime != null) {
      final timeSinceLastAttempt = DateTime.now().difference(_lastAttemptTime!);
      if (timeSinceLastAttempt < _cooldownPeriod) {
        return _cooldownPeriod.inSeconds - timeSinceLastAttempt.inSeconds;
      }
    }
    return 0;
  }

  // Check if device has biometric hardware
  static Future<bool> isDeviceSupported() async {
    try {
      return await _localAuth.isDeviceSupported();
    } catch (e) {
      return false;
    }
  }

  // Get available biometric types
  static Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      return [];
    }
  }

  // Check biometric status with detailed info
  static Future<BiometricStatus> checkBiometricStatus() async {
    try {
      // Check if device is supported
      bool isSupported = await _localAuth.isDeviceSupported();
      if (!isSupported) {
        return BiometricStatus.noHardware;
      }

      // Check if biometric hardware is available
      bool canCheckBiometrics = await _localAuth.canCheckBiometrics;
      if (!canCheckBiometrics) {
        return BiometricStatus.noHardware;
      }

      // Get available biometrics
      List<BiometricType> availableBiometrics = 
          await _localAuth.getAvailableBiometrics();
      
      if (availableBiometrics.isEmpty) {
        return BiometricStatus.notEnrolled;
      }

      return BiometricStatus.available;
    } catch (e) {
      return BiometricStatus.error;
    }
  }

  // Get user-friendly biometric type name
  static Future<String> getBiometricTypeName() async {
    try {
      final biometrics = await _localAuth.getAvailableBiometrics();
      if (biometrics.contains(BiometricType.face)) {
        return 'Face ID';
      } else if (biometrics.contains(BiometricType.fingerprint)) {
        return 'Fingerprint';
      } else if (biometrics.contains(BiometricType.iris)) {
        return 'Iris';
      }
      return 'Biometric';
    } catch (e) {
      return 'Biometric';
    }
  }

  // Authenticate with biometrics (enhanced with retry logic)
  static Future<BiometricResult> authenticate({
    required String reason,
    bool stickyAuth = true,
  }) async {
    // Prevent multiple simultaneous authentication attempts
    if (_isAuthenticating) {
      return BiometricResult(
        success: false,
        errorType: BiometricErrorType.hardwareError,
        message: 'Authentication already in progress',
      );
    }

    // Check cooldown period
    _checkAndResetAttempts();
    if (_isInCooldown()) {
      final remaining = getRemainingCooldownSeconds();
      return BiometricResult(
        success: false,
        errorType: BiometricErrorType.lockedOut,
        message: 'Too many attempts. Please try after $remaining seconds',
      );
    }

    try {
      // First check if biometric is available
      BiometricStatus status = await checkBiometricStatus();
      
      if (status == BiometricStatus.noHardware) {
        return BiometricResult.notAvailable();
      }
      
      if (status == BiometricStatus.notEnrolled) {
        return BiometricResult.notEnrolled();
      }
      
      if (status == BiometricStatus.error) {
        return BiometricResult.hardwareError('Biometric hardware error');
      }

      _isAuthenticating = true;

      // Authentication options
      final options = AuthenticationOptions(
        stickyAuth: stickyAuth,
        biometricOnly: true,
        sensitiveTransaction: true,
      );

      // Authenticate with timeout
      bool authenticated = await _localAuth.authenticate(
        localizedReason: reason,
        options: options,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          _localAuth.stopAuthentication();
          return false;
        },
      );

      _isAuthenticating = false;

      if (authenticated) {
        // Reset counter on successful authentication
        _attemptCount = 0;
        _lastAttemptTime = null;
        return BiometricResult.success();
      } else {
        // Increment failed attempt counter
        _attemptCount++;
        _lastAttemptTime = DateTime.now();
        
        // Check if now locked out
        if (_attemptCount >= _maxAttempts) {
          return BiometricResult.lockedOut();
        }
        
        return BiometricResult.canceled();
      }
      
    } on PlatformException catch (e) {
      _isAuthenticating = false;
      _attemptCount++;
      _lastAttemptTime = DateTime.now();
      
      // Handle specific platform errors
      if (e.code == 'NOT_AVAILABLE') {
        return BiometricResult.notAvailable();
      } else if (e.code == 'LOCKED_OUT' || e.code == 'PermanentLockout') {
        return BiometricResult.lockedOut();
      } else if (e.code == 'USER_CANCELED') {
        return BiometricResult.canceled();
      }
      
      return BiometricResult.hardwareError(e.message ?? 'Unknown error');
    } catch (e) {
      _isAuthenticating = false;
      _attemptCount++;
      _lastAttemptTime = DateTime.now();
      return BiometricResult.hardwareError(e.toString());
    }
  }

  // Check if authentication is in progress
  static bool isAuthenticating() => _isAuthenticating;

  // Stop current authentication
  static Future<void> stopAuthentication() async {
    if (_isAuthenticating) {
      await _localAuth.stopAuthentication();
      _isAuthenticating = false;
    }
  }

  // Reset attempt counter
  static void resetAttempts() {
    _attemptCount = 0;
    _lastAttemptTime = null;
  }

  // Open security settings
  static Future<void> openSecuritySettings() async {
    try {
      await AppSettings.openAppSettings(type: AppSettingsType.security);
    } catch (e) {
      // Fallback to general settings
      await AppSettings.openAppSettings();
    }
  }

  // Check if device has any biometric hardware
  static Future<bool> hasBiometricHardware() async {
    try {
      return await _localAuth.canCheckBiometrics;
    } catch (e) {
      return false;
    }
  }
}