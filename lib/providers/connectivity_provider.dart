import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

class ConnectivityProvider extends ChangeNotifier {
  bool _isOnline = true;
  bool get isOnline => _isOnline;

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  ConnectivityProvider() {
    _initConnectivity();
    _subscription = _connectivity.onConnectivityChanged.listen(_updateStatus);
  }

  Future<void> _initConnectivity() async {
    final result = await _connectivity.checkConnectivity();
    _updateStatus(result);
  }

  void _updateStatus(List<ConnectivityResult> results) {
    // Check if any result is NOT none
    final bool online = results.any((result) => result != ConnectivityResult.none);
    
    if (!_isOnline && online) {
      // Transition from offline to online
      _simulateSync();
    }
    
    _isOnline = online;
    notifyListeners();
  }

  void _simulateSync() {
    debugPrint('--- [Internet Restored] Syncing records to server... ---');
    debugPrint('Syncing Appointment records from Hive to Mock Server...');
    debugPrint('--- [Sync Complete] ---');
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
