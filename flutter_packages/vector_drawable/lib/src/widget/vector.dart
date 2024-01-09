import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:vector_drawable/src/widget/raw_vector.dart';

import '../../vector_drawable.dart';
import '../utils/compat.dart';
import '../utils/render_vector_flags.dart';
import '../utils/model_conversion.dart';

class VectorWidget extends StatelessWidget {
  const VectorWidget({
    Key? key,
    required this.vector,
    this.styleResolver = StyleResolver.empty,
    this.cachingStrategy = cachingStrategyAll,
    this.viewportClip = Clip.hardEdge,
    this.child,
  }) : super(key: key);
  final Vector vector;
  final StyleResolver styleResolver;
  final Set<RenderVectorCache> cachingStrategy;
  final Clip? viewportClip;
  final Widget? child;
  static const Set<RenderVectorCache> cachingStrategyAll = {
    RenderVectorCache.clipPath,
    RenderVectorCache.group,
    RenderVectorCache.path,
    RenderVectorCache.childOutlet,
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

  static const int _cachingStrategyAllBitset =
      PathFlag | GroupFlag | ClipPathFlag | ChildOutletFlag;

  @override
  Widget build(BuildContext context) {
    if (false) {
      return RawLeafVectorWidget(
        vector: vector,
        styleResolver: styleResolver.mergeWith(
          ColorSchemeStyleResolver(Theme.of(context).colorScheme),
        ),
        cachingStrategy: identical(cachingStrategy, cachingStrategyAll)
            ? _cachingStrategyAllBitset
            : flagsFromSet(cachingStrategy),
        viewportClip: viewportClip,
      );
    }
    return RawVectorWidget(
      vector: vector,
      styleResolver: styleResolver.mergeWith(
        ColorSchemeStyleResolver(Theme.of(context).colorScheme),
      ),
      cachingStrategy: identical(cachingStrategy, cachingStrategyAll)
          ? _cachingStrategyAllBitset
          : flagsFromSet(cachingStrategy),
      viewportClip: viewportClip,
      child: child,
    );
  }
}
