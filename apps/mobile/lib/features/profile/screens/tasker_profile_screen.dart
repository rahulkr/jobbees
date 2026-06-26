// ignore_for_file: public_member_api_docs

/// Tasker profile setup (inventory rows 35-39): bio, hourly rate, skills.
///
/// Single editable form for now; service areas, photos, and the public profile
/// follow. Loads the current profile, lets the tasker edit, and saves through
/// the controller. Four-state aware (CLAUDE.md rule 3).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/network/error_mapper.dart';
import '../../../core/responsive/responsive_layout.dart';
import '../../../ui/ui.dart';
import '../../auth/providers/auth_controller.dart';
import '../../auth/widgets/animated_auth_error.dart';
import '../models/tasker_profile.dart';
import '../providers/profile_providers.dart';

const int _maxSkills = 20;

class TaskerProfileScreen extends ConsumerStatefulWidget {
  const TaskerProfileScreen({super.key});

  @override
  ConsumerState<TaskerProfileScreen> createState() =>
      _TaskerProfileScreenState();
}

class _TaskerProfileScreenState extends ConsumerState<TaskerProfileScreen> {
  final _bio = TextEditingController();
  final _rate = TextEditingController();
  final _skillInput = TextEditingController();
  final _rateFocus = FocusNode();
  final List<String> _skills = [];

  bool _initialised = false;
  bool _saving = false;
  String? _rateError;
  String? _formError;

  @override
  void dispose() {
    _bio.dispose();
    _rate.dispose();
    _skillInput.dispose();
    _rateFocus.dispose();
    super.dispose();
  }

  void _initFrom(TaskerProfile profile) {
    if (_initialised) return;
    _initialised = true;
    _bio.text = profile.bio ?? '';
    final cents = profile.hourlyRateCents;
    if (cents != null) {
      // Whole dollars where possible, else two decimals.
      _rate.text = cents % 100 == 0
          ? (cents ~/ 100).toString()
          : (cents / 100).toStringAsFixed(2);
    }
    _skills.addAll(profile.skills);
  }

  int? _rateCents() {
    final text = _rate.text.trim();
    if (text.isEmpty) return null;
    final dollars = double.tryParse(text);
    if (dollars == null || dollars < 0) return null;
    return (dollars * 100).round();
  }

  void _addSkill() {
    final skill = _skillInput.text.trim();
    if (skill.isEmpty ||
        _skills.contains(skill) ||
        _skills.length >= _maxSkills) {
      return;
    }
    setState(() {
      _skills.add(skill);
      _skillInput.clear();
    });
  }

  Future<void> _save() async {
    if (_saving) return;
    FocusScope.of(context).unfocus();
    if (_rate.text.trim().isNotEmpty && _rateCents() == null) {
      JHaptics.error();
      setState(() => _rateError = 'Enter a valid amount');
      _rateFocus.requestFocus();
      return;
    }
    setState(() {
      _saving = true;
      _rateError = null;
      _formError = null;
    });
    try {
      await ref
          .read(taskerProfileControllerProvider.notifier)
          .save(
            bio: _bio.text.trim(),
            hourlyRateCents: _rateCents(),
            skills: _skills,
          );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Profile saved')));
      }
    } on AppError catch (error) {
      if (mounted) {
        JHaptics.error();
        setState(() => _formError = error.message);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(taskerProfileControllerProvider);
    final myId = ref.watch(authControllerProvider).valueOrNull?.id;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your tasker profile'),
        actions: [
          if (myId != null)
            IconButton(
              tooltip: 'Preview public profile',
              icon: const Icon(LucideIcons.eye),
              onPressed: () => context.push('/taskers/$myId'),
            ),
        ],
      ),
      body: SafeArea(
        child: profile.when(
          loading: () => Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: const _FormSkeleton(),
            ),
          ),
          error: (_, _) => _ErrorState(
            onRetry: () => ref.invalidate(taskerProfileControllerProvider),
          ),
          data: (data) {
            _initFrom(data);
            return ResponsiveLayout(
              compact: (context) => _form(context, maxWidth: double.infinity),
              expanded: (context) =>
                  Center(child: _form(context, maxWidth: 480)),
            );
          },
        ),
      ),
    );
  }

  Widget _form(BuildContext context, {required double maxWidth}) {
    final theme = Theme.of(context);
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
                'Tell clients what you do. This shows on your public profile.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: JSpacing.xl),
              AnimatedAuthError(message: _formError),
              JTextField(
                label: 'About you',
                controller: _bio,
                enabled: !_saving,
                hintText: 'A short intro about your work and experience',
                maxLines: 5,
                minLines: 3,
                maxLength: 1000,
              ),
              const SizedBox(height: JSpacing.lg),
              JTextField(
                label: 'Hourly rate (AUD)',
                controller: _rate,
                focusNode: _rateFocus,
                enabled: !_saving,
                errorText: _rateError,
                hintText: 'e.g. 85',
                helperText: 'Optional. You can set this per job too.',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
              const SizedBox(height: JSpacing.lg),
              Text(
                'Skills',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: JSpacing.sm),
              _SkillsEditor(
                skills: _skills,
                input: _skillInput,
                enabled: !_saving,
                onAdd: _addSkill,
                onRemove: (s) => setState(() => _skills.remove(s)),
              ),
              const SizedBox(height: JSpacing.xl),
              JButton.primary(
                label: 'Save profile',
                onPressed: _saving ? null : _save,
                loading: _saving,
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

/// Loading placeholder shaped like the profile form: intro, bio area, rate
/// field, skills field + chips, save button. Skeleton, not a spinner.
class _FormSkeleton extends StatelessWidget {
  const _FormSkeleton();

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      padding: EdgeInsets.all(JSpacing.lg),
      child: JShimmer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: JSpacing.sm),
            JSkeleton.line(width: 260),
            SizedBox(height: JSpacing.xl),
            JSkeleton.line(width: 88),
            SizedBox(height: JSpacing.sm),
            JSkeleton.box(height: 120),
            SizedBox(height: JSpacing.lg),
            JSkeleton.line(width: 128),
            SizedBox(height: JSpacing.sm),
            JSkeleton.box(height: 56),
            SizedBox(height: JSpacing.lg),
            JSkeleton.line(width: 60),
            SizedBox(height: JSpacing.sm),
            JSkeleton.box(height: 56),
            SizedBox(height: JSpacing.base),
            Row(
              children: [
                JSkeleton.box(width: 96, height: 32, radius: JRadius.chipAll),
                SizedBox(width: JSpacing.sm),
                JSkeleton.box(width: 72, height: 32, radius: JRadius.chipAll),
                SizedBox(width: JSpacing.sm),
                JSkeleton.box(width: 108, height: 32, radius: JRadius.chipAll),
              ],
            ),
            SizedBox(height: JSpacing.xl),
            JSkeleton.box(height: 56),
          ],
        ),
      ),
    );
  }
}

class _SkillsEditor extends StatelessWidget {
  const _SkillsEditor({
    required this.skills,
    required this.input,
    required this.enabled,
    required this.onAdd,
    required this.onRemove,
  });

  final List<String> skills;
  final TextEditingController input;
  final bool enabled;
  final VoidCallback onAdd;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: JTextField(
                label: 'Add a skill',
                controller: input,
                enabled: enabled,
                hintText: 'e.g. Plumbing',
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => onAdd(),
              ),
            ),
            const SizedBox(width: JSpacing.sm),
            Padding(
              padding: const EdgeInsets.only(top: JSpacing.xs),
              child: JButton.secondary(
                label: 'Add',
                onPressed: enabled ? onAdd : null,
              ),
            ),
          ],
        ),
        if (skills.isNotEmpty) ...[
          const SizedBox(height: JSpacing.base),
          Wrap(
            spacing: JSpacing.sm,
            runSpacing: JSpacing.sm,
            children: [
              for (final skill in skills)
                _SkillChip(
                  label: skill,
                  onRemove: enabled ? () => onRemove(skill) : null,
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _SkillChip extends StatelessWidget {
  const _SkillChip({required this.label, this.onRemove});

  final String label;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.only(
        left: JSpacing.base,
        right: JSpacing.sm,
        top: JSpacing.xs,
        bottom: JSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: JRadius.chipAll,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(color: scheme.primary),
          ),
          const SizedBox(width: JSpacing.xs),
          GestureDetector(
            onTap: onRemove,
            child: Icon(LucideIcons.x, size: 16, color: scheme.primary),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(JSpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.cloudOff, size: 36, color: scheme.onSurfaceVariant),
          const SizedBox(height: JSpacing.base),
          Text(
            "Couldn't load your profile.",
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: JSpacing.lg),
          JButton.secondary(label: 'Try again', onPressed: onRetry),
        ],
      ),
    );
  }
}
