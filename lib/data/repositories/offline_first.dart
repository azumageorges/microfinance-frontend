import 'package:dio/dio.dart';

import '../../core/network/connectivity_service.dart';

/// Stratégie « offline-first » commune aux repositories :
/// hors ligne on renvoie le cache local, en ligne on interroge l'API,
/// on met le cache à jour et on retombe sur le cache si l'appel échoue.
///
/// [onRemoteError] n'est appelé que si le cache local est vide ; par défaut
/// l'erreur réseau est propagée telle quelle.
Future<List<T>> offlineFirstList<T>({
  required ConnectivityService? connectivity,
  required Future<List<T>> Function() local,
  required Future<List<T>> Function() remote,
  Future<void> Function(List<T> items)? cache,
  Never Function(DioException e)? onRemoteError,
}) async {
  final cached = await local();

  if (connectivity != null && await connectivity.isOnline()) {
    try {
      final items = await remote();
      await cache?.call(items);
      return items;
    } on DioException catch (e) {
      if (cached.isNotEmpty) return cached;
      if (onRemoteError != null) onRemoteError(e);
      rethrow;
    }
  }

  return cached;
}
