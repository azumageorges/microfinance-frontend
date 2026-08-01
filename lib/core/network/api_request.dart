import 'package:dio/dio.dart';

import 'api_exception.dart';

/// Exécute [request] en convertissant toute [DioException] en [ApiException].
Future<T> guardApi<T>(Future<T> Function() request) async {
  try {
    return await request();
  } on DioException catch (e) {
    throw ApiException.fromDioError(e);
  }
}

/// Décode l'enveloppe `{ "data": { ... } }` d'une réponse.
T parseItem<T>(Response res, T Function(Map<String, dynamic>) fromJson) =>
    fromJson(res.data['data'] as Map<String, dynamic>);

/// Décode l'enveloppe `{ "data": [ ... ] }` d'une réponse.
List<T> parseList<T>(Response res, T Function(Map<String, dynamic>) fromJson) =>
    (res.data['data'] as List)
        .map((e) => fromJson(e as Map<String, dynamic>))
        .toList();

/// Décode l'enveloppe paginée `{ "data": { "content": [ ... ] } }`.
List<T> parsePage<T>(Response res, T Function(Map<String, dynamic>) fromJson) =>
    ((res.data['data'] as Map<String, dynamic>)['content'] as List)
        .map((e) => fromJson(e as Map<String, dynamic>))
        .toList();
