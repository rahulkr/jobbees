// ignore_for_file: public_member_api_docs

/// JBottomNav — the authenticated shell's bottom navigation.
///
/// A composed bar (Design Quality Charter § "no default Material widgets") built
/// on a notched [BottomAppBar] that cradles the raised centre [JPostButton]
/// (placed as the Scaffold FAB with [FloatingActionButtonLocation.centerDocked]).
/// A soft navy-tinted shadow hugs the notched silhouette so the bar reads as a
/// distinct plane above scrolling content — the flat Material 3 NavigationBar it
/// replaces had no separation.
library;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../theme/colors.dart';
import '../../tokens/tokens.dart';

/// One bottom-nav destination. Keep the destination list even in length so the
/// items split evenly to the left and right of the centre notch.
class JNavDestination {
  const JNavDestination({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

class JBottomNav extends StatelessWidget {
  const JBottomNav({
    required this.destinations,
    required this.selectedIndex,
    required this.onSelect,
    super.key,
  });

  final List<JNavDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  /// JPostButton radius (28) + notch breathing room (8). Keep in sync with the
  /// FAB and the reserved centre gap below.
  static const double _notchRadius = 36;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final mid = destinations.length ~/ 2;

    Widget item(int i) => _NavItem(
      destination: destinations[i],
      selected: selectedIndex == i,
      onTap: () => onSelect(i),
    );

    // Custom-painted (not BottomAppBar) so a crisp top hairline can follow the
    // notch — the real separator on a light layout, where a soft shadow alone is
    // invisible white-on-white and content never scrolls under the bar.
    return CustomPaint(
      painter: _NotchedBarPainter(
        surface: scheme.surface,
        border: scheme.outlineVariant,
        shadow: JobbeesColors.dark900.withValues(alpha: 0.12),
        notchRadius: _notchRadius,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 64,
            child: Row(
              children: [
                for (var i = 0; i < mid; i++) Expanded(child: item(i)),
                // Reserved gap the notch + cradled Post button sit in.
                const SizedBox(width: 72),
                for (var i = mid; i < destinations.length; i++)
                  Expanded(child: item(i)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Paints the bar surface, a soft upward shadow, and a 1px hairline — all
/// following a top-centre circular notch that cradles the Post button.
class _NotchedBarPainter extends CustomPainter {
  const _NotchedBarPainter({
    required this.surface,
    required this.border,
    required this.shadow,
    required this.notchRadius,
  });

  final Color surface;
  final Color border;
  final Color shadow;
  final double notchRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final host = Offset.zero & size;
    final guest = Rect.fromCircle(
      center: Offset(size.width / 2, 0),
      radius: notchRadius,
    );
    final path = const CircularNotchedRectangle().getOuterPath(host, guest);

    // Soft upward lift: a blurred copy of the silhouette nudged up so only the
    // top edge + notch curve cast onto the content above the bar.
    canvas.drawPath(
      path.shift(const Offset(0, -3)),
      Paint()
        ..color = shadow
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
    );
    // Surface.
    canvas.drawPath(path, Paint()..color = surface);
    // Crisp hairline along the notched top edge — the primary separator.
    canvas.drawPath(
      path,
      Paint()
        ..color = border
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(_NotchedBarPainter old) =>
      surface != old.surface ||
      border != old.border ||
      shadow != old.shadow ||
      notchRadius != old.notchRadius;
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final JNavDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final iconColor = selected ? scheme.primary : JobbeesColors.dark400;
    final labelColor = selected ? scheme.primary : JobbeesColors.dark600;

    return InkResponse(
      onTap: onTap,
      radius: 44,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Active-tab pill behind the icon (keeps the M3 indicator affordance).
          AnimatedContainer(
            duration: JMotion.pageTransition,
            curve: JMotion.easeOut,
            padding: const EdgeInsets.symmetric(
              horizontal: JSpacing.base,
              vertical: JSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: selected
                  ? scheme.primary.withValues(alpha: 0.12)
                  : Colors.transparent,
              borderRadius: JRadius.chipAll,
            ),
            child: Icon(destination.icon, size: 24, color: iconColor),
          ),
          const SizedBox(height: JSpacing.xs),
          Text(
            destination.label,
            style: textTheme.labelSmall?.copyWith(
              fontSize: 11,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              color: labelColor,
            ),
          ),
        ],
      ),
    );
  }
}

/// The raised centre Post action: a round, honey-gradient button with a coral
/// glow and press feedback, sized to seat in [JBottomNav]'s notch. Place it as
/// the Scaffold's `floatingActionButton` with `centerDocked`.
class JPostButton extends StatefulWidget {
  const JPostButton({
    required this.onPressed,
    this.semanticLabel = 'Post a job',
    super.key,
  });

  final VoidCallback onPressed;
  final String semanticLabel;

  @override
  State<JPostButton> createState() => _JPostButtonState();
}

class _JPostButtonState extends State<JPostButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: widget.semanticLabel,
      child: GestureDetector(
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        onTap: widget.onPressed,
        child: AnimatedScale(
          scale: _pressed ? 0.94 : 1.0,
          duration: const Duration(milliseconds: 90),
          curve: JMotion.easeOut,
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: gradientPrimaryButton,
              boxShadow: [
                BoxShadow(
                  color: JobbeesColors.primary.withValues(alpha: 0.40),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Faint lit-from-above sheen, matching JButton.primary.
                const Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: gradientButtonSheen,
                    ),
                  ),
                ),
                Icon(LucideIcons.plus, size: 28, color: scheme.onPrimary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
