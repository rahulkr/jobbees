import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jobbees_mobile/features/verification/data/verification_repository.dart';

class _StubAdapter implements HttpClientAdapter {
  _StubAdapter(this.respond);

  final ({int status, Map<String, dynamic> body}) Function(RequestOptions)
  respond;
  RequestOptions? lastRequest;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastRequest = options;
    final result = respond(options);
    return ResponseBody.fromString(
      jsonEncode(result.body),
      result.status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

VerificationRepository _repo(_StubAdapter adapter) {
  final dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000'))
    ..httpClientAdapter = adapter;
  return VerificationRepository(dio, newIdempotencyKey: () => 'idem-1');
}

void main() {
  test(
    'submitAbn posts the ABN with an Idempotency-Key and parses status',
    () async {
      final adapter = _StubAdapter(
        (_) => (
          status: 200,
          body: {
            'abn': '51824753556',
            'businessName': 'Test Business Pty Ltd',
            'verifiedAt': '2026-06-18T00:00:00.000Z',
          },
        ),
      );

      final status = await _repo(adapter).submitAbn('51824753556');

      expect(adapter.lastRequest!.path, '/me/abn');
      expect(adapter.lastRequest!.method, 'POST');
      expect(adapter.lastRequest!.headers['Idempotency-Key'], 'idem-1');
      expect((adapter.lastRequest!.data as Map)['abn'], '51824753556');
      expect(status.businessName, 'Test Business Pty Ltd');
      expect(status.isVerified, isTrue);
    },
  );

  test('fetchAbnStatus parses an empty (not-submitted) status', () async {
    final adapter = _StubAdapter(
      (_) => (
        status: 200,
        body: {'abn': null, 'businessName': null, 'verifiedAt': null},
      ),
    );

    final status = await _repo(adapter).fetchAbnStatus();

    expect(adapter.lastRequest!.path, '/me/abn');
    expect(status.isEmpty, isTrue);
    expect(status.isVerified, isFalse);
  });
}
