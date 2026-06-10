import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:management_app/services/auth_service.dart';
import 'package:management_app/services/navigation_service.dart';

class InterceptedClient extends http.BaseClient {
  final http.Client _inner;

  // Yeh flag prevent karta hai ki ek saath multiple relogin na ho jayein
  bool _isRefreshing = false;

  InterceptedClient(this._inner);

  // Yeh method automatically call hota hai har http request pe
  // chahe get ho, post ho, put ho — sab iske andar se guzarta hai
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {

    // Har request se pehle latest cookies attach karo
    await AuthService.loadCookies();
    _attachCookies(request);

    // Original request bhejo server pe
    http.StreamedResponse response = await _inner.send(request);

    // Response check karo — session expire hua kya?
    if (_isSessionExpired(response.statusCode) && !_isRefreshing) {
      _isRefreshing = true;
      debugPrint("⚠️ Session expired detect hua — silent relogin start...");

      // Background mein silently relogin karo
      final success = await AuthService.autoRelogin();
      _isRefreshing = false;

      if (success) {
        // Relogin hua — same request dobara bhejo
        debugPrint("✅ Relogin successful — request retry ho raha hai...");
        final retryRequest = await _copyRequest(request);
        _attachCookies(retryRequest);
        return await _inner.send(retryRequest);
      } else {
        // Relogin bhi fail — force logout karo
        debugPrint("❌ Relogin bhi fail — login screen pe bhej raha hun");
        _forceLogout();
      }
    }

    return response;
  }

  // Request headers mein cookies lagao
  void _attachCookies(http.BaseRequest request) {
    if (AuthService.cookies.isNotEmpty) {
      request.headers['Cookie'] = AuthService.cookies.join('; ');
    }
  }

  // 401 = Unauthorized, 403 = Forbidden — dono session expire ke signs hain ERPNext mein
  bool _isSessionExpired(int statusCode) {
    return statusCode == 401 || statusCode == 403;
  }

  // Same request ki copy banao — original already consume ho chuka hota hai
  Future<http.BaseRequest> _copyRequest(http.BaseRequest original) async {
    if (original is http.Request) {
      final copy = http.Request(original.method, original.url);
      copy.headers.addAll(original.headers);
      copy.body = original.body;
      return copy;
    }
    if (original is http.MultipartRequest) {
      final copy = http.MultipartRequest(original.method, original.url);
      copy.headers.addAll(original.headers);
      copy.fields.addAll(original.fields);
      copy.files.addAll(original.files);
      return copy;
    }
    return original;
  }

  // Bina context ke login screen pe navigate karo
  void _forceLogout() async {
    final auth = AuthService();
    await auth.logoutUser();

    NavigationService.navigatorKey.currentState
        ?.pushNamedAndRemoveUntil('/loginScreen', (route) => false);
  }
}