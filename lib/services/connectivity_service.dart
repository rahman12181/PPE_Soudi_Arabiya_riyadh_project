// ignore_for_file: unrelated_type_itype_checks

import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  final StreamController<ConnectivityResult> _connectionStatusController = 
      StreamController<ConnectivityResult>.broadcast();

  Stream<ConnectivityResult> get connectionStatus => _connectionStatusController.stream;

  void initialize() {
    _connectivity.onConnectivityChanged.listen((List<ConnectivityResult> result) {
      ConnectivityResult primaryResult = result.isNotEmpty ? result.first : ConnectivityResult.none;
      _connectionStatusController.add(primaryResult);
    });
  }

  Future<bool> hasInternetConnection() async {
    try {
      var connectivityResult = await _connectivity.checkConnectivity();
      return connectivityResult.isNotEmpty && 
             connectivityResult.first != ConnectivityResult.none;
    } catch (e) {
      return false;
    }
  }

  Future<ConnectivityResult> getConnectionType() async {
    try {
      var connectivityResult = await _connectivity.checkConnectivity();
      return connectivityResult.isNotEmpty ? connectivityResult.first : ConnectivityResult.none;
    } catch (e) {
      return ConnectivityResult.none;
    }
  }

  void dispose() {
    _connectionStatusController.close();
  }
}