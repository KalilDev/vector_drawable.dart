import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:vector_drawable/src/widget/raw_vector.dart';

import '../../vector_drawable.dart';
import '../utils/compat.dart';
import '../utils/render_vector_flags.dart';
import '../utils/model_conversion.dart';

class VectorWidget extends StatelessWidget {
  static bool renderUseAffine = false;
  const VectorWidget({
    Key? key,
    required this.vector,
    this.styleResolver = StyleResolver.empty,
    this.cachingStrategy = cachingStrategyAll,
    this.viewportClip = Clip.hardEdge,
    this.usingColorSchemeColors = false,
    this.child,
  }) : super(key: key);
  final Vector vector;
  final StyleResolver styleResolver;
  final Set<RenderVectorCache> cachingStrategy;
  final Clip? viewportClip;
  final bool usingColorSchemeColors;
  final Widget? child;
  static const Set<RenderVectorCache> cachingStrategyAll = {
    RenderVectorCache.clipPath,
    RenderVectorCache.group,
    RenderVectorCache.path,
    RenderVectorCache.childOutlet,
    RenderVectorCache.vector,
  };

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsNodeVectorDiagnosticsNodeAdapter(
        VectorProperty('vector', vector)));
    properties.add(DiagnosticsNodeVectorDiagnosticsNodeAdapter(VectorProperty(
        'styleMapping', styleResolver,
        defaultValue: StyleMapping)));
  }

  static const int _cachingStrategyAllBitset = -1;

  @override
  Widget build(BuildContext context) {
    final int cachingStrategyBitset =
        identical(cachingStrategy, cachingStrategyAll)
            ? _cachingStrategyAllBitset
            : flagsFromSet(cachingStrategy);
    final styleResolver = usingColorSchemeColors
        ? this.styleResolver.mergeWith(
              ColorSchemeStyleResolver(Theme.of(context).colorScheme),
            )
        : this.styleResolver;
    if (child == null) {
      return RawLeafVectorWidget(
        vector: vector,
        styleResolver: styleResolver,
        cachingStrategy: cachingStrategyBitset,
        viewportClip: viewportClip,
      );
    }
    return RawVectorWidget(
      vector: vector,
      styleResolver: styleResolver,
      cachingStrategy: cachingStrategyBitset,
      viewportClip: viewportClip,
      child: child,
    );
  }
}
