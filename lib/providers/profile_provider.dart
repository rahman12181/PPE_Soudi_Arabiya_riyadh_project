import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:management_app/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileProvider extends ChangeNotifier {
  Map<String, dynamic>? _profileData;

  Map<String, dynamic>? get profileData => _profileData;

  final String baseUrl = "https://ppecon.erpnext.com";

 
  Future<void> clearProfileCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('profileData');
    await prefs.remove('cachedUserEmail');

    _profileData = null;
    notifyListeners();
  }

  Future<void> loadProfile({bool forceRefresh = false}) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      String? currentUserEmail =
          prefs.getString('email');

      String? cachedUserEmail =
          prefs.getString('cachedUserEmail');

      if (cachedUserEmail != null &&
          currentUserEmail != null &&
          cachedUserEmail != currentUserEmail) {
        print("🔄 User switched → clearing cache");

        await prefs.remove('profileData');
        await prefs.remove('cachedUserEmail');
        _profileData = null;
      }

      if (!forceRefresh) {
        String? cachedProfile =
            prefs.getString('profileData');

        if (cachedProfile != null &&
            cachedUserEmail == currentUserEmail) {
          _profileData = jsonDecode(cachedProfile);
          notifyListeners();
          return;
        }
      }

      await AuthService.loadCookies();

      final loggedUserResponse =
          await AuthService.client.get(
        Uri.parse(
            "$baseUrl/api/method/frappe.auth.get_logged_user"),
        headers: {
          "Cookie": AuthService.cookies.join('; ')
        },
      );

      final loggedUserEmail =
          jsonDecode(loggedUserResponse.body)["message"];

      /// FETCH PROFILE
      final profileResponse =
          await AuthService.client.get(
        Uri.parse(
            "$baseUrl/api/resource/User/$loggedUserEmail"),
        headers: {
          "Cookie": AuthService.cookies.join('; ')
        },
      );

      final profileJson =
          jsonDecode(profileResponse.body);

      String? userImage =
          profileJson["data"]["user_image"];

      String fullImageUrl = "";

      if (userImage != null && userImage.isNotEmpty) {
        if (userImage.startsWith("http")) {
          fullImageUrl = userImage;
        } else {
          /// 🔥 CACHE BUSTER FIX
          fullImageUrl =
              "$baseUrl$userImage?v=${DateTime.now().millisecondsSinceEpoch}";
        }
      }

      _profileData = {
        "full_name":
            profileJson["data"]["full_name"] ?? "",
        "email": loggedUserEmail,
        "user_image": userImage ?? "",
        "full_image_url": fullImageUrl,
      };

      /// SAVE CACHE PER USER
      await prefs.setString(
          'profileData', jsonEncode(_profileData));
      await prefs.setString(
          'cachedUserEmail', loggedUserEmail);

      notifyListeners();
    // ignore: empty_catches
    } catch (e) {
    }
  }

  String? getProfileImageUrl() {
    return _profileData?['full_image_url'];
  }
}