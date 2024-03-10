import 'package:flutter/material.dart';

class CardWrapper extends StatelessWidget {
  const CardWrapper({
    super.key,
    required this.child,
    this.byHeight,
  });
  final Widget child;
  final bool? byHeight;

  Widget _build(BuildContext context, BoxConstraints constraints) {
    if (byHeight == null) {
      // try by width
      final width = constraints.maxWidth;
      final height = width * CardAspectRatio.aspectRatio;
      if (height > constraints.maxHeight) {
        return CardWrapper(
          byHeight: true,
          child: child,
        );
      }
      return SizedBox(
        width: width,
        height: height,
        child: child,
      );
    }
    if (!byHeight!) {
      final width = constraints.maxWidth;
      final height = width * CardAspectRatio.aspectRatio;
      return SizedBox(
        width: width,
        height: height,
        child: child,
      );
    }
    final height = constraints.maxHeight;
    final width = height / CardAspectRatio.aspectRatio;
    return SizedBox(
      width: width,
      height: height,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: _build);
}

class CardAspectRatio extends StatelessWidget {
  const CardAspectRatio({
    super.key,
    required this.child,
  });
  final Widget child;
  static const aspectRatio = 11.5 / 8;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: child,
    );
  }
}
