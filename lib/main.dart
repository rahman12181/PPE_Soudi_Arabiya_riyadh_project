// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:management_app/card_screen/check_more.dart';
import 'package:management_app/card_screen/employee_advance_screen.dart';
import 'package:management_app/card_screen/leave_approval.dart';
import 'package:management_app/card_screen/leaverequest.dart';
import 'package:management_app/card_screen/leave_balance_screen.dart';
import 'package:management_app/providers/attendance_provider.dart';
import 'package:management_app/providers/employee_provider.dart';
import 'package:management_app/providers/profile_provider.dart';
import 'package:management_app/providers/punch_provider.dart';
import 'package:management_app/providers/slide_provider.dart';
import 'package:management_app/screen/homemain_screen.dart';
import 'package:management_app/screen/attendance_request_screen.dart';
import 'package:management_app/screen/attendance_screen.dart';
import 'package:management_app/screen/forgotpassword_screen.dart';
import 'package:management_app/screen/home_screen.dart';
import 'package:management_app/screen/leave_approval_screen.dart';
import 'package:management_app/screen/login_screen.dart';
import 'package:management_app/screen/notification_screen.dart';
import 'package:management_app/screen/profilescreen.dart';
import 'package:management_app/screen/setting_screen.dart';
import 'package:management_app/screen/splash_screen.dart';
import 'package:management_app/screen/travel_request_screen.dart';
import 'package:management_app/services/auth_service.dart';
import 'package:management_app/services/navigation_service.dart'; // ✅ Yeh sahi path hai
import 'package:management_app/utils/systembars_utils.dart';
import 'package:provider/provider.dart';
import 'package:quick_actions/quick_actions.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.system);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // App open hote hi session silently check aur fix karo
  await _initSession();

  await AuthService.loadCookies();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(create: (_) => EmployeeProvider()),
        ChangeNotifierProvider(create: (_) => PunchProvider()),
        ChangeNotifierProvider(create: (_) => AttendanceProvider()),
        ChangeNotifierProvider(create: (_) => SlideProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

Future<void> _initSession() async {
  final prefs = await SharedPreferences.getInstance();
  final isLoggedIn = prefs.getBool("isLoggedIn") ?? false;

  if (!isLoggedIn) return;
  await AuthService.loadCookies();
  final isValid = await _checkSessionValid();

  if (!isValid) {
    debugPrint("silent relogin happen because session expired during app open");

    final success = await AuthService.autoRelogin();

    if (success) {
      debugPrint("silent relogin succcessful");
    } else {
      // Credentials nahi mile ya wrong — isLoggedIn false karo
      debugPrint("silent relogin failed — clearing session and logging out");
      await prefs.setBool("isLoggedIn", false);
    }
  } else {
    debugPrint("valid session detected on app open — no relogin needed");
  }
}

Future<bool> _checkSessionValid() async {
  try {
    final auth = AuthService();
    final response = await http.get(
      Uri.parse(
        "${AuthService.baseUrl}/api/method/frappe.auth.get_logged_user",
      ),
      headers: auth.buildHeaders(),
    );
    return response.statusCode == 200;
  } catch (e) {
    return true;
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    _initQuickActions();
  }

  void _initQuickActions() {
    const QuickActions quickActions = QuickActions();

    quickActions.setShortcutItems(<ShortcutItem>[
      const ShortcutItem(type: 'home', localizedTitle: 'Home'),
      const ShortcutItem(type: 'attendance', localizedTitle: 'Attendance'),
      const ShortcutItem(type: 'leave_balance', localizedTitle: 'Leave Balance'),
    ]);

    quickActions.initialize((String shortcutType) {
      if (shortcutType == 'home') {
        NavigationService.navigatorKey.currentState?.pushNamed('/homeMainScreen');
      } else if (shortcutType == 'attendance') {
        NavigationService.navigatorKey.currentState?.pushNamed('/attendanceScreen');
      } else if (shortcutType == 'leave_balance') {
        NavigationService.navigatorKey.currentState?.pushNamed('/leaveBalaneceScreen');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentTheme, _) {
        return MaterialApp(
          navigatorKey: NavigationService.navigatorKey, 
          debugShowCheckedModeBanner: false,
          title: 'Pioneer',
          themeMode: currentTheme,
          theme: ThemeData(
            useMaterial3: false,
            fontFamily: 'poppins',
            brightness: Brightness.light,
            scaffoldBackgroundColor: Colors.white,
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              elevation: 0,
              iconTheme: IconThemeData(color: Colors.black),
              titleTextStyle: TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            textTheme: const TextTheme(
              bodyLarge: TextStyle(color: Colors.black),
              bodyMedium: TextStyle(color: Colors.black87),
              bodySmall: TextStyle(color: Colors.black54),
            ),
            iconTheme: const IconThemeData(color: Colors.black),
            cardColor: Colors.white,
            dividerColor: Colors.grey,
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1976D2),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          darkTheme: ThemeData(
            useMaterial3: false,
            fontFamily: 'poppins',
            brightness: Brightness.dark,
            scaffoldBackgroundColor: Colors.black,
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              elevation: 0,
              iconTheme: IconThemeData(color: Colors.white),
              titleTextStyle: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            textTheme: const TextTheme(
              bodyLarge: TextStyle(color: Colors.white),
              bodyMedium: TextStyle(color: Colors.white70),
              bodySmall: TextStyle(color: Colors.white60),
            ),
            iconTheme: const IconThemeData(color: Colors.white),
            cardColor: Color(0xFF1E1E1E),
            dividerColor: Colors.white24,
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF90CAF9),
              onPrimary: Colors.black,
              surface: Color(0xFF121212),
              onSurface: Colors.white,
            ),
          ),
          builder: (context, child) {
            SystembarUtil.setSystemBar(context);
            return child!;
          },
          initialRoute: '/splashScreen',
          routes: {
            '/splashScreen': (_) => const SplashScreen(),
            '/loginScreen': (_) => const LoginScreen(),
            '/forgotpasswordScreen': (_) => const ForgotpasswordScreen(),
            '/homeMainScreen': (_) => const HomemainScreen(),
            '/homeScreen': (_) => const HomeScreen(),
            '/settingScreen': (_) => const SettingsScreen(),
            '/notificationScreen': (_) => const NotificationScreen(),
            '/profileScreen': (_) => const Profilescreen(),
            '/attendanceScreen': (_) => const AttendanceScreen(),
            '/leaveRequest': (_) => const LeaveRequest(),
            '/employeeAdvance': (_) => const EmployeeAdvanceScreen(),
            '/leaveApproval': (_) => const LeaveApproval(),
            '/attendanceRequest': (_) => const AttendanceRequestScreen(),
            '/travelRequest': (_) => const TravelRequestScreen(),
            '/leaveBalaneceScreen': (_) => const LeaveBalanceScreen(),
            '/checkMore': (_) => const CheckMore(),
            '/leaveApprovalScreen': (_) => const LeaveApprovalScreen(),
            '/profilescreen': (_) => const Profilescreen(),
          },
          onUnknownRoute: (_) =>
              MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      },
    );
  }
}