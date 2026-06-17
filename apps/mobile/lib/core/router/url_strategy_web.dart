// ignore_for_file: public_member_api_docs

/// Web implementation: serve clean `/jobs/123` URLs instead of `/#/jobs/123`.
library;

import 'package:flutter_web_plugins/url_strategy.dart';

void configureUrlStrategy() => usePathUrlStrategy();
