import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jobbees_mobile/core/network/error_mapper.dart';

DioException _dio(DioExceptionType type, {Response<dynamic>? response}) =>
    DioException(
      requestOptions: RequestOptions(path: '/x'),
      type: type,
      response: response,
    );

Response<dynamic> _resp(int status, {Object? data}) => Response<dynamic>(
  requestOptions: RequestOptions(path: '/x'),
  statusCode: status,
  data: data,
);

void main() {
  group('ErrorMapper.retryable', () {
    test('a connection error is retryable', () {
      expect(
        ErrorMapper.map(_dio(DioExceptionType.connectionError)).retryable,
        isTrue,
      );
    });

    test('a timeout is retryable', () {
      expect(
        ErrorMapper.map(_dio(DioExceptionType.receiveTimeout)).retryable,
        isTrue,
      );
    });

    test('a 5xx is retryable', () {
      final mapped = ErrorMapper.map(
        _dio(DioExceptionType.badResponse, response: _resp(503)),
      );
      expect(mapped.retryable, isTrue);
    });

    test('a 4xx is not retryable', () {
      final mapped = ErrorMapper.map(
        _dio(DioExceptionType.badResponse, response: _resp(409)),
      );
      expect(mapped.retryable, isFalse);
    });

    test('a non-dio error is not retryable', () {
      expect(ErrorMapper.map(Exception('weird')).retryable, isFalse);
    });

    test('passes an existing AppError through unchanged', () {
      const original = AppError('boom', retryable: true);
      expect(identical(ErrorMapper.map(original), original), isTrue);
    });
  });

  test('surfaces the server message on a 4xx and stays non-retryable', () {
    final mapped = ErrorMapper.map(
      _dio(
        DioExceptionType.badResponse,
        response: _resp(400, data: {'message': 'Bad ABN'}),
      ),
    );
    expect(mapped.message, 'Bad ABN');
    expect(mapped.retryable, isFalse);
  });
}
