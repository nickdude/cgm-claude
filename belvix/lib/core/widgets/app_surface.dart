import 'package:flutter/material.dart';

/// A card-like surface that renders via [Material] (PhysicalShape) instead of
/// a `Container`+`BoxDecoration`.
///
/// Some low-end Android GPUs fail to paint `BoxDecoration` fills/shadows
/// under the Impeller renderer (the whole surface renders transparent).
/// Material's PhysicalModel path renders correctly on those devices, so all
/// app surfaces (cards, sheets, the bottom nav, the week-strip pills) route
/// through this widget.
class AppSurface extends StatelessWidget {
  const AppSurface({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.color = Colors.white,
    this.radius = 16,
    this.elevation = 1.5,
    this.shadowColor = const Color(0x14000000),
    this.borderColor,
    this.width = double.infinity,
    this.clip = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  final double radius;
  final double elevation;
  final Color shadowColor;
  final Color? borderColor;
  final double? width;
  final bool clip;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      surfaceTintColor: Colors.transparent,
      elevation: elevation,
      shadowColor: shadowColor,
      clipBehavior: clip ? Clip.antiAlias : Clip.none,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
        side: borderColor != null
            ? BorderSide(color: borderColor!)
            : BorderSide.none,
      ),
      child: SizedBox(
        width: width,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}
