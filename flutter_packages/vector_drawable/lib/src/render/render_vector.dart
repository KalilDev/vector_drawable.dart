import 'package:vector_drawable/src/render/mixins.dart';
import 'package:flutter/rendering.dart';

import 'package:vector_drawable_core/model.dart';
import 'package:vector_math/vector_math_64.dart' show Vector4;

import '../utils/rendering_context.dart';

class RenderVector extends RenderProxyBox with RenderVectorBaseMixin {
  RenderVector({
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
  void performLayout() {
    defaultPerformLayout();
    final child = this.child;
    if (child != null) {
      final childOutletAndParents = _renderingContext.childOutletAndParents();
      final childOutlet = childOutletAndParents.childOutlet;
      final values = _renderingContext.childOutletValuesFor(childOutlet);
      final neededTransform =
          _renderingContext.neededChildOutletTransform(size);
      final childTopLeft = values.rect.topLeft;
      final vec = Vector4(childTopLeft.dx, childTopLeft.dy, 0, 0);
      neededTransform.transform(vec);
      final childSize = values.rect.size;
      final childConstraints = BoxConstraints.tight(childSize);
      child.layout(childConstraints, parentUsesSize: false);
    }
  }

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

    if (usingLayers) {
      context.pushTransform(
        needsCompositing,
        offset,
        transform,
        paintInsideGroup,
      );
    } else {
      final canvas = context.canvas;
      canvas.save();
      canvas.transform(transform.storage);
      paintInsideGroup(context, offset);
      canvas.restore();
    }
  }

  static const usingLayers = true;

  // According to https://github.com/aosp-mirror/platform_frameworks_base/blob/47fed6ba6ab8a68267a9b3ac6cb9decd4ba122ed/libs/hwui/VectorDrawable.cpp#L264
  // there is no save layer and restore layer.
  @override
  void paintClipPath(
      PaintingContext context, Offset offset, ClipPath clipPath) {
    final values = _renderingContext.clipPathValuesFor(clipPath);
    final uiPath = values.pathData;
    void paintInsideClipPath(PaintingContext context, Offset offset) {
      defaultPaintInsideClipPath(context, offset, clipPath);
    }

    if (usingLayers) {
      // TODO
      final Rect bounds = Rect.zero;
      context.pushClipPath(
        needsCompositing,
        offset,
        bounds,
        values.pathData,
        paintInsideClipPath,
      );
    } else {
      // android does not save and restore the canvas
      context.canvas.clipPath(uiPath);
      paintInsideClipPath(context, offset);
    }
  }

  @override
  void paintPath(PaintingContext context, Offset offset, Path path) =>
      defaultPaintPath(context, offset, path);

  @override
  double? computeDistanceToActualBaseline(TextBaseline baseline) {
    double? result;
    if (child != null) {
      assert(!debugNeedsLayout);
      result = child!.getDistanceToActualBaseline(baseline);
      final BoxParentData childParentData = child!.parentData! as BoxParentData;
      if (result != null) {
        result += childParentData.offset.dy;
      }
    } else {
      result = super.computeDistanceToActualBaseline(baseline);
    }
    return result;
  }

  void _paintChildAfterPushingLayers(
      PaintingContext context, Offset offset, ChildOutlet childOutlet) {
    final child = this.child;
    assert(child != null);
    final values = _renderingContext.childOutletValues();
    context.paintChild(
      child!,
      values.rect.topLeft + offset,
    );
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    if (child != null) {
      final r = result.addWithPaintTransform(
        transform: _renderingContext.neededChildOutletTransform(size),
        position: position,
        hitTest: (BoxHitTestResult result, Offset transformed) {
          final values = _renderingContext.childOutletValues();
          final childOutletOffset = values.rect.topLeft;
          return child!.hitTest(
            result,
            position: transformed - childOutletOffset,
          );
        },
      );
      return r;
    }
    return false;
  }

  void _pushLayersThenPaintChild(
    PaintingContext context,
    Offset offset,
    Iterable<ChildOutletTransformOrClipPath> neededLayers,
    ChildOutlet childOutlet,
  ) {
    if (neededLayers.isEmpty) {
      _paintChildAfterPushingLayers(context, Offset.zero, childOutlet);
      return;
    }
    final firstLayer = neededLayers.first;
    if (firstLayer.clipPath != null) {
      throw UnimplementedError('not yet');
    }
    final transform = firstLayer.transform!;
    void paint(PaintingContext context, Offset offset) =>
        _pushLayersThenPaintChild(
          context,
          offset,
          neededLayers.skip(1),
          childOutlet,
        );
    context.pushTransform(
      needsCompositing,
      offset,
      transform,
      paint,
    );
  }

  @override
  void paintChildOutlet(
      PaintingContext context, Offset offset, ChildOutlet childOutlet) {
    //if (!usingLayers) {
    //print('sorry');
    //assert(false, 'fuck off');
    //}
    _paintChildAfterPushingLayers(context, offset, childOutlet);
    return;
  }

  @override
  void paintChildren(
          PaintingContext context, Offset offset, List<VectorPart> children) =>
      defaultPaintChildren(context, offset, children);

  @override
  void paintPart(PaintingContext context, Offset offset, VectorPart part) =>
      defaultPaintPart(context, offset, part);

  @override
  void paintVector(PaintingContext context, Offset offset, Vector vector) =>
      defaultPaintVector(context, offset, vector);

  @override
  void paint(PaintingContext context, Offset offset) =>
      paintVector(context, offset, vector);

  @override
  void paintInsideOfVector(PaintingContext context, Offset offset) =>
      defaultPaintInsideOfVector(context, offset);

  @override
  void transformPaintAndBlendVector(PaintingContext context, Offset offset) =>
      defaultTransformPaintAndBlendVector(context, offset);

  @override
  void applyInvalidationFlags(int flags) {
    defaultApplyInvalidationFlags(flags);
    if ((flags & needsChildLayoutFlag) == needsChildLayoutFlag) {
      //child?.markNeedsLayout();
      markNeedsLayout();
    }
  }
}
