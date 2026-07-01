// ignore_for_file: public_member_api_docs

/// Google / Apple sign-in buttons shared by the login + signup screens.
///
/// Google shows everywhere; Apple shows on Apple platforms and web (Android has
/// no native Apple flow, and App Store policy requires offering Apple wherever
/// other social sign-in is offered, i.e. iOS). A cancelled provider sheet just
/// clears the busy state; a real failure is reported up via [onError] so the
/// host screen renders it in its banner.
///
/// Branding: Google uses the multi-colour "G" (assets/social/google.png) on the
/// neutral outline [JButton.secondary]. Apple uses [JButton.apple] — a custom
/// Sign in with Apple button built per Apple's HIG (black fill, white label,
/// Apple's official mark in assets/social/apple_logo.png). Going custom (vs the
/// native SignInWithAppleButton, whose font is locked to 0.43 × height) lets the
/// two buttons match pixel-for-pixel: both are JButtonSize.md (52px), same
/// radius, same Inter label. The primary CTA stays dominant.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/error_mapper.dart';
import '../../../core/platform/platform_info.dart';
import '../../../ui/ui.dart';
import '../providers/auth_controller.dart';

enum _Provider { google, apple }

class SocialAuthButtons extends ConsumerStatefulWidget {
  const SocialAuthButtons({
    this.onError,
    this.dividerLabel = 'or',
    this.dividerAtBottom = false,
    super.key,
  });

  /// Surfaces a provider failure message to the host screen's error banner.
  final ValueChanged<String>? onError;

  /// Text in the "or" divider. Login uses the default; the social-first signup
  /// layout passes 'or sign up with email' to frame email as the alt path.
  final String dividerLabel;

  /// When true, the divider renders *below* the provider buttons (social-first
  /// layouts where socials lead and the email form follows). Default false =
  /// divider on top (form-first screens, e.g. login).
  final bool dividerAtBottom;

  @override
  ConsumerState<SocialAuthButtons> createState() => _SocialAuthButtonsState();
}

class _SocialAuthButtonsState extends ConsumerState<SocialAuthButtons> {
  _Provider? _busy;

  bool get _showApple => PlatformInfo.isApplePlatform || PlatformInfo.isWeb;

  Future<void> _run(_Provider provider) async {
    if (_busy != null) return;
    widget.onError?.call('');
    setState(() => _busy = provider);
    try {
      final controller = ref.read(authControllerProvider.notifier);
      if (provider == _Provider.google) {
        await controller.signInWithGoogle();
      } else {
        await controller.signInWithApple();
      }
      // Success: the router redirect takes over. Cancellation is a silent no-op.
    } on AppError catch (error) {
      widget.onError?.call(error.message);
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final anyBusy = _busy != null;

    final divider = <Widget>[
      _OrDivider(label: widget.dividerLabel),
      const SizedBox(height: JSpacing.lg),
    ];
    final buttons = <Widget>[
      JButton.secondary(
        label: 'Continue with Google',
        leading: Image.asset(
          'assets/social/google.png',
          width: 20,
          height: 20,
          filterQuality: FilterQuality.medium,
        ),
        onPressed: anyBusy ? null : () => _run(_Provider.google),
        loading: _busy == _Provider.google,
        expanded: true,
        // md (52px) — matches the Apple button below; the primary CTA
        // (Log in, lg/56px) stays dominant.
        size: JButtonSize.md,
      ),
      if (_showApple) ...[
        const SizedBox(height: JSpacing.md),
        // Custom Sign in with Apple button built per Apple's HIG (Creating a
        // custom Sign in with Apple button): black fill, white label, and
        // Apple's official logo mark. Rendered through JButton.apple so it's
        // pixel-identical to the Google button above — same height, radius,
        // font and logo gap — which the native SignInWithAppleButton couldn't
        // be (its font is locked to 0.43 × height).
        JButton.apple(
          label: 'Continue with Apple',
          leading: Image.asset(
            'assets/social/apple_logo.png',
            height: 20,
            filterQuality: FilterQuality.medium,
          ),
          onPressed: anyBusy ? null : () => _run(_Provider.apple),
          loading: _busy == _Provider.apple,
          expanded: true,
          size: JButtonSize.md,
        ),
      ],
    ];

    return Column(
      children: widget.dividerAtBottom
          // Social-first: buttons lead, divider separates them from the form below.
          ? [...buttons, const SizedBox(height: JSpacing.lg), divider.first]
          // Form-first: divider on top, then buttons.
          : [...divider, ...buttons],
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider({this.label = 'or'});

  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final line = Expanded(child: Divider(color: scheme.outlineVariant));
    return Row(
      children: [
        line,
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: JSpacing.base),
          child: Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ),
        line,
      ],
    );
  }
}
