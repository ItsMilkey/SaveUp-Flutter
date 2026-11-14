import 'package:flutter/material.dart';

import '../../theme/saveup_colors.dart';
import '../../theme/saveup_shadows.dart';
import '../../tokens/app_borders.dart';
import '../../tokens/app_colors.dart';
import '../../tokens/app_motion.dart';
import '../../tokens/app_radii.dart';
import '../../tokens/app_spacing.dart';
import '../../tokens/app_typography.dart';

class NeoBottomDestination {
  const NeoBottomDestination({
    required this.label,
    required this.icon,
    this.selectedIcon,
    this.dragSelectable = true,
  });

  final String label;
  final IconData icon;
  final IconData? selectedIcon;
  final bool dragSelectable;
}

/// Barra inferior flotante neo-brutalista con selección controlada por el padre.
class NeoBottomNav extends StatefulWidget {
  const NeoBottomNav({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<NeoBottomDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  State<NeoBottomNav> createState() => _NeoBottomNavState();
}

class _NeoBottomNavState extends State<NeoBottomNav> {
  static const double _itemInset = 12;
  static const double _barHeight = 72;
  static const double _railTop = 12;
  static const double _indicatorSize = 44;

  int? _previewIndex;
  bool _dragging = false;

  @override
  void didUpdateWidget(covariant NeoBottomNav oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex) {
      _previewIndex = null;
      _dragging = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final MediaQueryData mediaQuery = MediaQuery.of(context);
    final bool disableAnimations = mediaQuery.disableAnimations;
    final Duration duration = disableAnimations
        ? Duration.zero
        : AppMotion.fast;
    final ThemeData theme = Theme.of(context);
    final SaveUpColors colors = theme.extension<SaveUpColors>()!;
    final SaveUpShadows shadows = theme.extension<SaveUpShadows>()!;
    if (widget.destinations.isEmpty) {
      return const SizedBox.shrink();
    }
    final int visualIndex = (_previewIndex ?? widget.selectedIndex).clamp(
      0,
      widget.destinations.length - 1,
    );

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double width = constraints.maxWidth;
          final double itemWidth =
              (width - (_itemInset * 2)) / widget.destinations.length;
          final double indicatorLeft =
              _itemInset +
              (visualIndex + 0.5) * itemWidth -
              (_indicatorSize / 2);

          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragStart: (DragStartDetails details) {
              _dragging = true;
              _setPreviewForPosition(details.localPosition, width);
            },
            onHorizontalDragUpdate: (DragUpdateDetails details) {
              _setPreviewForPosition(details.localPosition, width);
            },
            onHorizontalDragEnd: (DragEndDetails details) {
              final int? destination = _previewIndex;
              if (_dragging && destination != null) {
                if (destination != widget.selectedIndex) {
                  widget.onSelected(destination);
                }
              }
              if (mounted) {
                setState(() {
                  _previewIndex = null;
                  _dragging = false;
                });
              }
            },
            onHorizontalDragCancel: _cancelDrag,
            child: SizedBox(
              height: _barHeight,
              width: width,
              child: Stack(
                clipBehavior: Clip.none,
                children: <Widget>[
                  Positioned(
                    top: _railTop,
                    left: 6,
                    right: 6,
                    bottom: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: AppRadii.pillAll,
                        border: Border.all(
                          color: colors.border,
                          width: AppBorders.regular,
                        ),
                        boxShadow: shadows.lg,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    left: _itemInset,
                    right: _itemInset,
                    bottom: 0,
                    child: Material(
                      color: Colors.transparent,
                      child: Row(
                        children: <Widget>[
                          for (int i = 0; i < widget.destinations.length; i++)
                            Expanded(
                              child: _NeoNavItem(
                                destination: widget.destinations[i],
                                selected: i == widget.selectedIndex,
                                visualSelected: i == visualIndex,
                                onTap: () => widget.onSelected(i),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  AnimatedPositioned(
                    key: const ValueKey<String>('neo-bottom-nav-indicator'),
                    duration: duration,
                    curve: AppMotion.curve,
                    top: 0,
                    left: indicatorLeft,
                    child: IgnorePointer(
                      child: Container(
                        key: const ValueKey<String>(
                          'neo-bottom-nav-indicator-circle',
                        ),
                        width: _indicatorSize,
                        height: _indicatorSize,
                        decoration: BoxDecoration(
                          color: AppColors.yellow,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: colors.border,
                            width: AppBorders.regular,
                          ),
                          boxShadow: shadows.md,
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          _iconFor(widget.destinations[visualIndex]),
                          size: 28,
                          color: colors.ink,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  IconData _iconFor(NeoBottomDestination destination) =>
      destination.selectedIcon ?? destination.icon;

  void _setPreviewForPosition(Offset position, double width) {
    if (!_dragging || widget.destinations.isEmpty) {
      return;
    }
    final double contentWidth = width - (_itemInset * 2);
    final double x = position.dx - _itemInset;
    final bool insideNavigationArea =
        position.dy >= 0 &&
        position.dy <= _barHeight &&
        x >= 0 &&
        x < contentWidth;

    int? destination;
    if (insideNavigationArea && contentWidth > 0) {
      final double itemWidth = contentWidth / widget.destinations.length;
      final int index = (x / itemWidth).floor();
      if (widget.destinations[index].dragSelectable) {
        destination = index;
      }
    }

    if (_previewIndex != destination && mounted) {
      setState(() => _previewIndex = destination);
    }
  }

  void _cancelDrag() {
    if (!_dragging && _previewIndex == null) {
      return;
    }
    setState(() {
      _previewIndex = null;
      _dragging = false;
    });
  }
}

class _NeoNavItem extends StatelessWidget {
  const _NeoNavItem({
    required this.destination,
    required this.selected,
    required this.visualSelected,
    required this.onTap,
  });

  final NeoBottomDestination destination;
  final bool selected;
  final bool visualSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final SaveUpColors colors = theme.extension<SaveUpColors>()!;

    return Semantics(
      label: destination.label,
      button: true,
      selected: selected,
      onTap: onTap,
      child: ExcludeSemantics(
        child: InkWell(
          borderRadius: AppRadii.pillAll,
          onTap: onTap,
          child: SizedBox.expand(
            child: Stack(
              alignment: Alignment.topCenter,
              children: <Widget>[
                if (!visualSelected)
                  Positioned(
                    top: 20,
                    child: Icon(
                      destination.icon,
                      size: 20,
                      color: selected ? colors.ink : colors.muted,
                    ),
                  ),
                Positioned(
                  left: 1,
                  right: 1,
                  bottom: 6,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      destination.label,
                      maxLines: 1,
                      style: AppTypography.text(
                        size: 10,
                        weight: visualSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: visualSelected ? colors.ink : colors.muted,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
