// ignore_for_file: public_member_api_docs

/// Google / Apple sign-in buttons shared by the login + signup screens.
///
/// Google shows everywhere; Apple shows on Apple platforms and web (Android has
/// no native Apple flow, and App Store policy requires offering Apple wherever
/// other social sign-in is offered, i.e. iOS). A cancelled provider sheet just
/// clears the busy state; a real failure is reported up via [onError] so the
/// host screen renders it in its banner.
///
/// NOTE (brand): production should use the official Google/Apple button assets
/// for store review. These branded JButtons are the MVP stand-in.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/error_mapper.dart';
import '../../../core/platform/platform_info.dart';
import '../../../ui/ui.dart';
import '../providers/auth_controller.dart';

enum _Provider { google, apple }

class SocialAuthButtons extends ConsumerStatefulWidget {
  const SocialAuthButtons({this.onError, super.key});

  /// Surfaces a provider failure message to the host screen's error banner.
  final ValueChanged<String>? onError;

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
    return Column(
      children: [
        const _OrDivider(),
        const SizedBox(height: JSpacing.lg),
        JButton.secondary(
          label: 'Continue with Google',
          icon: Icons.g_mobiledata,
          onPressed: anyBusy ? null : () => _run(_Provider.google),
          loading: _busy == _Provider.google,
          expanded: true,
          size: JButtonSize.lg,
        ),
        if (_showApple) ...[
          const SizedBox(height: JSpacing.md),
          JButton.secondary(
            label: 'Continue with Apple',
            icon: Icons.apple,
            onPressed: anyBusy ? null : () => _run(_Provider.apple),
            loading: _busy == _Provider.apple,
            expanded: true,
            size: JButtonSize.lg,
          ),
        ],
      ],
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

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
            'or',
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
