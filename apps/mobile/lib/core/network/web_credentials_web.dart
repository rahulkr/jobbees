// ignore_for_file: public_member_api_docs

/// Web implementation: sets `withCredentials` on dio's browser adapter so the
/// API's HttpOnly `jb_access`/`jb_refresh` cookies ride along on cross-origin
/// requests (the admin/web surfaces talk to the API on a different origin).
library;

import 'package:dio/browser.dart';
import 'package:dio/dio.dart';

void enableWebCredentials(Dio dio) {
  final adapter = dio.httpClientAdapter;
  if (adapter is BrowserHttpClientAdapter) {
    adapter.withCredentials = true;
  }
}
