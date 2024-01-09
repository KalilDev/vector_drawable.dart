import 'package:flutter/material.dart';
import 'package:vector_drawable_core/model.dart';

import '../render/render_leaf_vector.dart';
import '../render/render_vector.dart';

class RawVectorWidget extends SingleChildRenderObjectWidget {
  const RawVectorWidget({
    Key? key,
    required this.vector,
    required this.styleResolver,
    this.cachingStrategy = 0, // 0b0000
    required this.viewportClip,
    Widget? child,
  }) : super(
          key: key,
          child: child,
        );

  final Vector vector;
  final StyleResolver styleResolver;
  final int cachingStrategy;
  final Clip? viewportClip;

  @override
  RenderObject createRenderObject(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return RenderVector(
      vector: vector,
      devicePixelRatio: mediaQuery.devicePixelRatio,
      textScaleFactor: mediaQuery.textScaleFactor,
      textDirection: Directionality.of(context),
      styleResolver: styleResolver,
      cachingStrategy: cachingStrategy,
      viewportClip: viewportClip,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderVector renderObject) {
    final mediaQuery = MediaQuery.of(context);
    renderObject
      ..vector = vector
      ..devicePixelRatio = mediaQuery.devicePixelRatio
      ..textScaleFactor = mediaQuery.textScaleFactor
      ..textDirection = Directionality.of(context)
      ..styleResolver = styleResolver
      ..cachingStrategy = cachingStrategy
      ..viewportClip = viewportClip;
  }
}

class RawLeafVectorWidget extends LeafRenderObjectWidget {
  const RawLeafVectorWidget({
    Key? key,
    required this.vector,
    required this.styleResolver,
    this.cachingStrategy = 0, // 0b0000
    required this.viewportClip,
  }) : super(key: key);

  final Vector vector;
  final StyleResolver styleResolver;
  final int cachingStrategy;
  final Clip? viewportClip;

  @override
  RenderLeafVector createRenderObject(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return RenderLeafVector(
      vector: vector,
      devicePixelRatio: mediaQuery.devicePixelRatio,
      textScaleFactor: mediaQuery.textScaleFactor,
      textDirection: Directionality.of(context),
      styleResolver: styleResolver,
      cachingStrategy: cachingStrategy,
      viewportClip: viewportClip,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderLeafVector renderObject) {
    final mediaQuery = MediaQuery.of(context);
    renderObject
      ..vector = vector
      ..devicePixelRatio = mediaQuery.devicePixelRatio
      ..textScaleFactor = mediaQuery.textScaleFactor
      ..textDirection = Directionality.of(context)
      ..styleResolver = styleResolver
      ..cachingStrategy = cachingStrategy
      ..viewportClip = viewportClip;
  }
}
