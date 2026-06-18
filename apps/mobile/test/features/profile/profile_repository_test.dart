import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jobbees_mobile/features/profile/data/profile_repository.dart';

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

ProfileRepository _repo(_StubAdapter adapter) {
  final dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000'))
    ..httpClientAdapter = adapter;
  return ProfileRepository(dio, newIdempotencyKey: () => 'idem-1');
}

void main() {
  test('fetch parses the tasker profile', () async {
    final adapter = _StubAdapter(
      (_) => (
        status: 200,
        body: {
          'bio': 'Handy',
          'hourlyRateCents': 8500,
          'skills': ['plumbing', 'tiling'],
        },
      ),
    );

    final profile = await _repo(adapter).fetch();

    expect(adapter.lastRequest!.path, '/me/profile');
    expect(adapter.lastRequest!.method, 'GET');
    expect(profile.bio, 'Handy');
    expect(profile.hourlyRateCents, 8500);
    expect(profile.skills, ['plumbing', 'tiling']);
  });

  test('update PATCHes the fields with an Idempotency-Key', () async {
    final adapter = _StubAdapter(
      (_) => (
        status: 200,
        body: {
          'bio': 'New',
          'hourlyRateCents': 9000,
          'skills': ['tiling'],
        },
      ),
    );

    final profile = await _repo(
      adapter,
    ).update(bio: 'New', hourlyRateCents: 9000, skills: ['tiling']);

    expect(adapter.lastRequest!.path, '/me/profile');
    expect(adapter.lastRequest!.method, 'PATCH');
    expect(adapter.lastRequest!.headers['Idempotency-Key'], 'idem-1');
    final data = adapter.lastRequest!.data as Map;
    expect(data['bio'], 'New');
    expect(data['hourlyRateCents'], 9000);
    expect(data['skills'], ['tiling']);
    expect(profile.hourlyRateCents, 9000);
  });

  test('fetchPublic gets /taskers/:id and parses badges', () async {
    final adapter = _StubAdapter(
      (_) => (
        status: 200,
        body: {
          'id': 't1',
          'firstName': 'Sam',
          'avatarUrl': null,
          'bio': 'Reliable',
          'hourlyRateCents': 8500,
          'businessName': 'Sam Pty Ltd',
          'skills': ['plumbing'],
          'verified': {'email': true, 'phone': false, 'payments': true},
        },
      ),
    );

    final profile = await _repo(adapter).fetchPublic('t1');

    expect(adapter.lastRequest!.path, '/taskers/t1');
    expect(adapter.lastRequest!.method, 'GET');
    expect(profile.firstName, 'Sam');
    expect(profile.badges.email, isTrue);
    expect(profile.badges.phone, isFalse);
    expect(profile.badges.payments, isTrue);
    expect(profile.skills, ['plumbing']);
  });
}
