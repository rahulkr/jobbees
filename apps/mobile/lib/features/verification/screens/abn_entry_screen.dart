// ignore_for_file: public_member_api_docs

/// ABN entry (inventory row 24).
///
/// Tasker enters their ABN; the backend validates the checksum and looks the
/// business up on the ABR. On success we pop back to the verification status
/// screen, which re-renders from the updated [abnStatusProvider].
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/network/error_mapper.dart';
import '../../../core/responsive/responsive_layout.dart';
import '../../../ui/ui.dart';
import '../providers/verification_providers.dart';

class AbnEntryScreen extends ConsumerStatefulWidget {
  const AbnEntryScreen({super.key});

  @override
  ConsumerState<AbnEntryScreen> createState() => _AbnEntryScreenState();
}

class _AbnEntryScreenState extends ConsumerState<AbnEntryScreen> {
  final _abn = TextEditingController();
  final _abnFocus = FocusNode();

  String? _abnError;
  bool _submitting = false;

  @override
  void dispose() {
    _abn.dispose();
    _abnFocus.dispose();
    super.dispose();
  }

  bool _validate() {
    final digits = _abn.text.replaceAll(RegExp(r'\s+'), '');
    // Format check only; the server owns the checksum (and returns its message).
    final looksValid = RegExp(r'^\d{11}$').hasMatch(digits);
    setState(() => _abnError = looksValid ? null : 'Enter your 11-digit ABN');
    return _abnError == null;
  }

  Future<void> _submit() async {
    if (_submitting) return;
    FocusScope.of(context).unfocus();
    if (!_validate()) {
      JHaptics.error();
      _abnFocus.requestFocus();
      return;
    }

    setState(() => _submitting = true);

    try {
      await ref
          .read(abnStatusProvider.notifier)
          .submit(_abn.text.replaceAll(RegExp(r'\s+'), ''));
      if (mounted) context.pop();
    } on AppError catch (error) {
      if (mounted) {
        JHaptics.error();
        JSnackbar.showError(
          context,
          error.message,
          onRetry: error.retryable ? _submit : null,
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Add your ABN')),
      body: SafeArea(
        child: ResponsiveLayout(
          compact: (context) =>
              _form(context, theme, maxWidth: double.infinity),
          expanded: (context) =>
              Center(child: _form(context, theme, maxWidth: 480)),
        ),
      ),
    );
  }

  Widget _form(
    BuildContext context,
    ThemeData theme, {
    required double maxWidth,
  }) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(JSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: JSpacing.sm),
              JEntrance(
                child: Center(
                  child: Container(
                    width: 72,
                    height: 72,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: JRadius.heroAll,
                    ),
                    child: Icon(
                      LucideIcons.building2,
                      size: 32,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: JSpacing.lg),
              JEntrance(
                delay: const Duration(milliseconds: 80),
                child: Text(
                  "We'll check your ABN against the Australian Business "
                  'Register and show your business name.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: JSpacing.xl),
              JEntrance(
                delay: const Duration(milliseconds: 160),
                child: JTextField(
                  label: 'ABN',
                  controller: _abn,
                  focusNode: _abnFocus,
                  enabled: !_submitting,
                  errorText: _abnError,
                  hintText: '11 digits',
                  helperText: 'Your 11-digit Australian Business Number',
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  maxLength: 14, // 11 digits + up to 3 spaces
                  onSubmitted: (_) => _submit(),
                ),
              ),
              const SizedBox(height: JSpacing.xl),
              JEntrance(
                delay: const Duration(milliseconds: 240),
                child: JButton.primary(
                  label: 'Verify ABN',
                  onPressed: _submitting ? null : _submit,
                  loading: _submitting,
                  expanded: true,
                  size: JButtonSize.lg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
