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

import '../../../core/network/error_mapper.dart';
import '../../../core/responsive/responsive_layout.dart';
import '../../../ui/ui.dart';
import '../../auth/widgets/auth_error_banner.dart';
import '../providers/verification_providers.dart';

class AbnEntryScreen extends ConsumerStatefulWidget {
  const AbnEntryScreen({super.key});

  @override
  ConsumerState<AbnEntryScreen> createState() => _AbnEntryScreenState();
}

class _AbnEntryScreenState extends ConsumerState<AbnEntryScreen> {
  final _abn = TextEditingController();

  String? _abnError;
  String? _formError;
  bool _submitting = false;

  @override
  void dispose() {
    _abn.dispose();
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
    if (!_validate()) return;

    setState(() {
      _submitting = true;
      _formError = null;
    });

    try {
      await ref
          .read(abnStatusProvider.notifier)
          .submit(_abn.text.replaceAll(RegExp(r'\s+'), ''));
      if (mounted) context.pop();
    } on AppError catch (error) {
      if (mounted) setState(() => _formError = error.message);
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
              Text(
                "We'll check your ABN against the Australian Business Register "
                'and show your business name.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: JSpacing.xl),
              if (_formError != null) ...[
                AuthErrorBanner(message: _formError!),
                const SizedBox(height: JSpacing.base),
              ],
              JTextField(
                label: 'ABN',
                controller: _abn,
                enabled: !_submitting,
                errorText: _abnError,
                hintText: '11 digits',
                helperText: 'Your 11-digit Australian Business Number',
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                maxLength: 14, // 11 digits + up to 3 spaces
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: JSpacing.xl),
              JButton.primary(
                label: 'Verify ABN',
                onPressed: _submitting ? null : _submit,
                loading: _submitting,
                expanded: true,
                size: JButtonSize.lg,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
