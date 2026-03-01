import 'dart:ui';
import 'package:flutter/material.dart';

class GlassContainer extends StatelessWidget {
  final double? width;
  final double? height;
  final double blur;
  final double opacity;
  final Color color;
  final BorderRadius borderRadius;
  final BoxBorder? border;
  final Widget? child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final List<BoxShadow>? boxShadow;
  final LinearGradient? gradient;

  const GlassContainer({
    super.key,
    this.width,
    this.height,
    this.blur = 10.0,
    this.opacity = 0.1,
    this.color = Colors.white,
    this.borderRadius = const BorderRadius.all(Radius.circular(16.0)),
    this.border,
    this.child,
    this.padding,
    this.margin,
    this.boxShadow,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        boxShadow: boxShadow,
        borderRadius: borderRadius,
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            width: width,
            height: height,
            padding: padding,
            decoration: BoxDecoration(
              color: gradient == null ? color.withOpacity(opacity) : null,
              gradient: gradient,
              borderRadius: borderRadius,
              border: border ??
                  Border.all(
                    color: color.withOpacity(0.2), // Default subtle border
                    width: 1.5,
                  ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
