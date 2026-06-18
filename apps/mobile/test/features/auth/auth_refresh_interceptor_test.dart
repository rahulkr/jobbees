import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jobbees_mobile/core/network/auth_refresh_interceptor.dart';

/// Returns a scripted status per call so we can model "401 then 200 on retry".
class _ScriptedAdapter implements HttpClientAdapter {
  _ScriptedAdapter(this.statuses);

  final List<int> statuses;
  int callCount = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final status = statuses[callCount.clamp(0, statuses.length - 1)];
    callCount++;
    return ResponseBody.fromString('{}', status);
  }

  @override
  void close({bool force = false}) {}
}

Dio _dioWith(_ScriptedAdapter adapter, Future<bool> Function() refresh) {
  final dio = Dio(
    BaseOptions(
      baseUrl: 'http://localhost:3000',
      // Treat non-2xx as errors so the interceptor's onError fires.
      validateStatus: (s) => s != null && s < 400,
    ),
  )..httpClientAdapter = adapter;
  dio.interceptors.add(
    AuthRefreshInterceptor(dio: dio, refreshSession: refresh),
  );
  return dio;
}

void main() {
  test('refreshes and retries once on 401, then succeeds', () async {
    final adapter = _ScriptedAdapter([401, 200]);
    var refreshCalls = 0;
    final dio = _dioWith(adapter, () async {
      refreshCalls++;
      return true;
    });

    final res = await dio.get<dynamic>('/auth/me');

    expect(res.statusCode, 200);
    expect(refreshCalls, 1);
    expect(adapter.callCount, 2); // original + one retry
  });

  test('surfaces the 401 when refresh fails', () async {
    final adapter = _ScriptedAdapter([401, 401]);
    final dio = _dioWith(adapter, () async => false);

    await expectLater(
      dio.get<dynamic>('/protected'),
      throwsA(
        isA<DioException>().having(
          (e) => e.response?.statusCode,
          'status',
          401,
        ),
      ),
    );
    expect(adapter.callCount, 1); // no retry when refresh fails
  });

  test('does not refresh on a 401 from an auth endpoint', () async {
    final adapter = _ScriptedAdapter([401]);
    var refreshCalls = 0;
    final dio = _dioWith(adapter, () async {
      refreshCalls++;
      return true;
    });

    await expectLater(
      dio.post<dynamic>('/auth/login'),
      throwsA(isA<DioException>()),
    );
    expect(refreshCalls, 0);
    expect(adapter.callCount, 1);
  });
}
