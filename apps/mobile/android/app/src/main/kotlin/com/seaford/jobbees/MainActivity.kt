package com.seaford.jobbees

import io.flutter.embedding.android.FlutterFragmentActivity

// local_auth shows the biometric prompt as a fragment, so the host must be a
// FragmentActivity — FlutterFragmentActivity rather than the default
// FlutterActivity.
class MainActivity : FlutterFragmentActivity()
