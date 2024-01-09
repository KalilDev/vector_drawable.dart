import 'dart:ui' as ui;

import 'package:flutter/material.dart' show Colors;
import 'package:vector_drawable/src/render/mixins.dart';
import 'package:flutter/rendering.dart';
import 'package:vector_drawable_core/model.dart';
import 'package:vector_math/vector_math_64.dart' show Vector4;

import '../utils/rendering_context.dart';

class RenderLeafVector extends RenderBox with RenderVectorBaseMixin {
  RenderLeafVector({
    required Vector vector,
    required double devicePixelRatio,
    required double textScaleFactor,
    required TextDirection textDirection,
    required StyleResolver styleResolver,
    required int cachingStrategy,
    required Clip? viewportClip,
  }) : _renderingContext = VectorRenderingContext(
          vector: vector,
          devicePixelRatio: devicePixelRatio,
          textScaleFactor: textScaleFactor,
          textDirection: textDirection,
          styleResolver: styleResolver,
          cachingStrategy: cachingStrategy,
          viewportClip: viewportClip,
        );

  final VectorRenderingContext _renderingContext;
  @override
  VectorRenderingContext get protectedRenderingContext => _renderingContext;
  @override
  void performLayout() => defaultPerformLayout();

  @override
  Size computeDryLayout(BoxConstraints constraints) =>
      defaultComputeDryLayout(constraints);

  @override
  // TODO: check that the position hits the vector
  bool hitTestSelf(Offset position) => true;

  @override
  double computeMaxIntrinsicHeight(double width) =>
      defaultComputeMaxIntrinsicHeight(width);
  @override
  double computeMinIntrinsicHeight(double width) =>
      defaultComputeMinIntrinsicHeight(width);
  @override
  double computeMaxIntrinsicWidth(double height) =>
      defaultComputeMaxIntrinsicWidth(height);
  @override
  double computeMinIntrinsicWidth(double height) =>
      defaultComputeMinIntrinsicWidth(height);

  @override
  bool get needsCompositing => true;

  @override
  void paintGroup(PaintingContext context, Offset offset, Group group) {
    final values = _renderingContext.groupValuesFor(group);
    final transform = values.transform;
    //if (group.name == 'g28') print(transform);
    if (transform == null) {
      defaultPaintInsideGroup(context, offset, group);
      return;
    }

    void paintInsideGroup(PaintingContext context, Offset offset) {
      defaultPaintInsideGroup(context, offset, group);
    }

    final canvas = context.canvas;
    canvas.save();
    canvas.transform(transform.storage);
    paintInsideGroup(context, offset);
    canvas.restore();
  }

  // According to https://github.com/aosp-mirror/platform_frameworks_base/blob/47fed6ba6ab8a68267a9b3ac6cb9decd4ba122ed/libs/hwui/VectorDrawable.cpp#L264
  // there is no save layer and restore layer.
  @override
  void paintClipPath(
      PaintingContext context, Offset offset, ClipPath clipPath) {
    final values = _renderingContext.clipPathValuesFor(clipPath);
    final uiPath = values.pathData;

    // android does not save and restore the canvas
    context.canvas.clipPath(uiPath);
    defaultPaintInsideClipPath(context, offset, clipPath);
  }

  @override
  void paintPath(PaintingContext context, Offset offset, Path path) =>
      defaultPaintPath(context, Offset.zero, path);

  @override
  void paintChildren(
      PaintingContext context, Offset offset, List<VectorPart> children) {
    defaultPaintChildren(context, offset, children);
  }

  @override
  void paintPart(PaintingContext context, Offset offset, VectorPart part) =>
      defaultPaintPart(context, offset, part);

  @override
  void paintVector(PaintingContext context, Offset offset, Vector vector) {
    defaultPaintVector(context, offset, vector);
  }

  @override
  void paintChildOutlet(
      PaintingContext context, Offset offset, ChildOutlet childOutlet) {
    defaultPaintChildOutlet(context, Offset.zero, childOutlet);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    defaultPaintVector(context, offset, vector);
  }

  @override
  void paintInsideOfVector(PaintingContext context, Offset offset) {
    final canvas = context.canvas;
    canvas.save();
    canvas.translate(offset.dx, offset.dy);
    defaultPaintInsideOfVector(context, offset);
    canvas.restore();
  }

  @override
  void transformPaintAndBlendVector(PaintingContext context, Offset offset) =>
      defaultTransformPaintAndBlendVector(context, offset);

  @override
  void applyInvalidationFlags(int flags) {
    defaultApplyInvalidationFlags(flags);
  }
}
