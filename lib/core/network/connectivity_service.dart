import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();

  Future<bool> isOnline() async {
    final results = await _connectivity.checkConnectivity();
    return results.any((r) => r != ConnectivityResult.none);
  }

  Stream<bool> onConnectivityChanged() {
    return _connectivity.onConnectivityChanged.map(
      (results) => results.any((r) => r != ConnectivityResult.none),
    );
  }
}
