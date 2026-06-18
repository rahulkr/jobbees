import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jobbees_mobile/features/auth/data/auth_repository.dart';

/// Captures the outgoing request and returns a canned JSON response, so we can
/// assert what the repository sends without a real server.
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

AuthRepository _repo(_StubAdapter adapter) {
  final dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000'))
    ..httpClientAdapter = adapter;
  return AuthRepository(dio, newIdempotencyKey: () => 'idem-123');
}

void main() {
  test(
    'signup posts to /auth/signup with an Idempotency-Key and parses tokens',
    () async {
      final adapter = _StubAdapter(
        (_) => (
          status: 201,
          body: {'accessToken': 'access-1', 'refreshToken': 'refresh-1'},
        ),
      );

      final tokens = await _repo(adapter).signup(
        email: 'jordan@example.com',
        password: 'a-strong-passphrase',
        firstName: 'Jordan',
        lastName: 'Lee',
      );

      expect(adapter.lastRequest!.path, '/auth/signup');
      expect(adapter.lastRequest!.method, 'POST');
      expect(adapter.lastRequest!.headers['Idempotency-Key'], 'idem-123');
      final body = adapter.lastRequest!.data as Map<String, dynamic>;
      expect(body['email'], 'jordan@example.com');
      expect(body.containsKey('role'), isFalse); // omitted when not provided
      expect(tokens!.accessToken, 'access-1');
      expect(tokens.refreshToken, 'refresh-1');
    },
  );

  test(
    'signup returns null token pair on the web cookie response shape',
    () async {
      final adapter = _StubAdapter(
        (_) => (status: 201, body: {'csrfToken': 'xyz'}),
      );

      final tokens = await _repo(adapter).signup(
        email: 'jordan@example.com',
        password: 'a-strong-passphrase',
        firstName: 'Jordan',
        lastName: 'Lee',
      );

      expect(tokens, isNull);
    },
  );

  test('fetchMe parses the user profile', () async {
    final adapter = _StubAdapter(
      (_) => (
        status: 200,
        body: {
          'id': 'user_1',
          'email': 'jordan@example.com',
          'firstName': 'Jordan',
          'lastName': 'Lee',
          'role': 'TASKER',
          'emailVerified': true,
          'phoneVerified': false,
        },
      ),
    );

    final me = await _repo(adapter).fetchMe();

    expect(adapter.lastRequest!.path, '/auth/me');
    expect(me.fullName, 'Jordan Lee');
    expect(me.role.name, 'tasker');
  });

  test(
    'login posts credentials with an Idempotency-Key and parses tokens',
    () async {
      final adapter = _StubAdapter(
        (_) => (
          status: 200,
          body: {'accessToken': 'access-2', 'refreshToken': 'refresh-2'},
        ),
      );

      final tokens = await _repo(
        adapter,
      ).login(email: 'jordan@example.com', password: 'a-strong-passphrase');

      expect(adapter.lastRequest!.path, '/auth/login');
      expect(adapter.lastRequest!.headers['Idempotency-Key'], 'idem-123');
      expect(tokens!.accessToken, 'access-2');
    },
  );

  test('refresh sends the refresh token and parses the new pair', () async {
    final adapter = _StubAdapter(
      (_) => (
        status: 200,
        body: {'accessToken': 'access-3', 'refreshToken': 'refresh-3'},
      ),
    );

    final tokens = await _repo(adapter).refresh('refresh-2');

    expect(adapter.lastRequest!.path, '/auth/refresh');
    final body = adapter.lastRequest!.data as Map<String, dynamic>;
    expect(body['refreshToken'], 'refresh-2');
    expect(tokens!.accessToken, 'access-3');
  });

  test(
    'refresh omits the token on web (cookie-based) and returns null',
    () async {
      final adapter = _StubAdapter(
        (_) => (status: 200, body: {'csrfToken': 'z'}),
      );

      final tokens = await _repo(adapter).refresh(null);

      final body = adapter.lastRequest!.data as Map<String, dynamic>;
      expect(body.containsKey('refreshToken'), isFalse);
      expect(tokens, isNull);
    },
  );

  test(
    'oauthLogin posts the id token + names to /auth/oauth/{provider}',
    () async {
      final adapter = _StubAdapter(
        (_) => (
          status: 200,
          body: {'accessToken': 'access-4', 'refreshToken': 'refresh-4'},
        ),
      );

      final tokens = await _repo(adapter).oauthLogin(
        provider: 'apple',
        idToken: 'apple-id-token',
        firstName: 'Jordan',
        lastName: 'Lee',
      );

      expect(adapter.lastRequest!.path, '/auth/oauth/apple');
      expect(adapter.lastRequest!.headers['Idempotency-Key'], 'idem-123');
      final body = adapter.lastRequest!.data as Map<String, dynamic>;
      expect(body['idToken'], 'apple-id-token');
      expect(body['firstName'], 'Jordan');
      expect(tokens!.accessToken, 'access-4');
    },
  );
}
