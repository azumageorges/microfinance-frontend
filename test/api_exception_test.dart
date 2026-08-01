import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:microfinance_app/core/network/api_exception.dart';

void main() {
  group('ApiException.from', () {
    test('conserve une ApiException existante', () {
      const original = ApiException('Solde insuffisant', statusCode: 400);

      final result = ApiException.from(original, StackTrace.current);

      expect(identical(result, original), isTrue);
    });

    test('traduit une DioException en message lisible', () {
      final dioError = DioException(
        requestOptions: RequestOptions(path: '/api/comptes'),
        response: Response(
          requestOptions: RequestOptions(path: '/api/comptes'),
          statusCode: 404,
        ),
        type: DioExceptionType.badResponse,
      );

      final result = ApiException.from(dioError, StackTrace.current);

      expect(result.message, 'Ressource introuvable');
      expect(result.statusCode, 404);
      expect(result.cause, dioError);
    });

    test('encapsule une erreur de parsing sans perdre la cause', () {
      Object? raw;
      StackTrace? stack;
      try {
        // Réponse mal formée : `data` n'est pas la Map attendue.
        // ignore: unnecessary_cast
        (<String, dynamic>{'data': 'oops'}['data'] as Map<String, dynamic>);
      } catch (e, s) {
        raw = e;
        stack = s;
      }

      final result = ApiException.from(raw!, stack!);

      expect(result.message, 'Réponse inattendue du serveur');
      expect(result.cause, raw);
      expect(result.stackTrace, stack);
    });
  });
}
