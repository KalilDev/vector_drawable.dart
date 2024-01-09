import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide ClipPath;
import 'package:flutter/rendering.dart';
import 'package:vector_drawable/src/utils/model_conversion.dart';
import 'package:vector_drawable/vector_drawable.dart';

import '../utils/rendering_context.dart';

mixin RenderVectorBaseMixin on RenderBox {
  @protected
  VectorRenderingContext get protectedRenderingContext;
  Vector get vector => protectedRenderingContext.vector;
  void applyInvalidationFlags(int flags);
  void defaultApplyInvalidationFlags(int flags) {
    if ((flags & needsLayoutFlag) == needsLayoutFlag) {
      markNeedsLayout();
    }
    if ((flags & needsPaintFlag) == needsPaintFlag) {
      markNeedsPaint();
    }
  }

  set vector(Vector vector) =>
      applyInvalidationFlags(protectedRenderingContext.setVector(vector));
  double get devicePixelRatio => protectedRenderingContext.devicePixelRatio;
  set devicePixelRatio(double devicePixelRatio) => applyInvalidationFlags(
      protectedRenderingContext.setDevicePixelRatio(devicePixelRatio));

  double get textScaleFactor => protectedRenderingContext.textScaleFactor;
  set textScaleFactor(double textScaleFactor) => applyInvalidationFlags(
      protectedRenderingContext.setTextScaleFactor(textScaleFactor));

  TextDirection get textDirection => protectedRenderingContext.textDirection;
  set textDirection(TextDirection textDirection) => applyInvalidationFlags(
      protectedRenderingContext.setTextDirection(textDirection));

  StyleResolver get styleResolver => protectedRenderingContext.styleResolver;
  set styleResolver(StyleResolver styleResolver) => applyInvalidationFlags(
      protectedRenderingContext.setStyleMapping(styleResolver));

  int get cachingStrategy => protectedRenderingContext.cachingStrategy;
  set cachingStrategy(int cachingStrategy) =>
      protectedRenderingContext.cachingStrategy = cachingStrategy;

  Clip? get viewportClip => protectedRenderingContext.viewportClip;
  set viewportClip(Clip? viewportClip) => applyInvalidationFlags(
      protectedRenderingContext.setViewportClip(viewportClip));

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty('vector', vector));
    properties.add(DiagnosticsProperty('devicePixelRatio', devicePixelRatio));
    properties.add(DoubleProperty('textScaleFactor', textScaleFactor));
    properties.add(EnumProperty('textDirection', textDirection));
    properties.add(DiagnosticsProperty('styleResolver', styleResolver,
        defaultValue: StyleResolver.empty, style: DiagnosticsTreeStyle.sparse));
    properties.add(DiagnosticsProperty('viewportClip', viewportClip));
  }

  void paintPart(
    PaintingContext context,
    Offset offset,
    VectorPart part,
  );
  void paintVector(
    PaintingContext context,
    Offset offset,
    Vector vector,
  );
  void paintPath(
    PaintingContext context,
    Offset offset,
    Path path,
  );
  void paintClipPath(
    PaintingContext context,
    Offset offset,
    ClipPath path,
  );

  void paintChildOutlet(
    PaintingContext context,
    Offset offset,
    ChildOutlet childOutlet,
  );

  void paintGroup(
    PaintingContext context,
    Offset offset,
    Group group,
  );

  void paintChildren(
    PaintingContext context,
    Offset offset,
    List<VectorPart> children,
  );

  Size _layoutUnconstrained() =>
      Size(_convertDimension(vector.width), _convertDimension(vector.height));
  Size _layoutConstrained(BoxConstraints constraints) =>
      constraints.constrain(_layoutUnconstrained());

  void defaultPerformLayout() {
    size = _layoutConstrained(constraints);
  }

  Size defaultComputeDryLayout(BoxConstraints constraints) =>
      _layoutConstrained(constraints);

  double _convertDimension(Dimension dimension) {
    switch (dimension.kind) {
      case DimensionKind.dip:
      case DimensionKind.dp:
        return dimension.value;
      case DimensionKind.px:
        return dimension.value / devicePixelRatio;
      case DimensionKind.sp:
        return dimension.value * textScaleFactor;
    }
  }

  double defaultComputeMaxIntrinsicHeight(double width) =>
      _convertDimension(vector.height);
  double defaultComputeMinIntrinsicHeight(double width) =>
      _convertDimension(vector.height);
  double defaultComputeMaxIntrinsicWidth(double height) =>
      _convertDimension(vector.width);
  double defaultComputeMinIntrinsicWidth(double height) =>
      _convertDimension(vector.width);

  @override
  bool get needsCompositing => true;

  void defaultPaintInsideGroup(
      PaintingContext context, Offset offset, Group group) {
    paintChildren(context, offset, group.children);
  }

  void defaultPaintInsideClipPath(
      PaintingContext context, Offset offset, ClipPath clipPath) {
    paintChildren(context, offset, clipPath.children);
  }

  void defaultPaintPath(PaintingContext context, Offset offset, Path path) {
    _paintPath(context.canvas, offset, path);
  }

  static Paint _paintForPath(Path path, PathValues values) {
    final paint = Paint()
      ..strokeWidth = values.strokeWidth
      ..strokeMiterLimit = path.strokeMiterLimit;

    switch (path.strokeLineCap) {
      case StrokeLineCap.butt:
        paint.strokeCap = ui.StrokeCap.butt;
        break;
      case StrokeLineCap.round:
        paint.strokeCap = ui.StrokeCap.round;
        break;
      case StrokeLineCap.square:
        paint.strokeCap = ui.StrokeCap.square;
        break;
    }
    switch (path.strokeLineJoin) {
      case StrokeLineJoin.miter:
        paint.strokeJoin = ui.StrokeJoin.miter;
        break;
      case StrokeLineJoin.round:
        paint.strokeJoin = ui.StrokeJoin.round;
        break;
      case StrokeLineJoin.bevel:
        paint.strokeJoin = ui.StrokeJoin.bevel;
        break;
    }
    return paint;
  }

  void _paintPath(Canvas canvas, Offset offset, Path path) {
    if (path.strokeColor == const Value<VectorColor>(VectorColor.transparent) &&
        path.fillColor == const Value<VectorColor>(VectorColor.transparent)) {
      return;
    }
    canvas.save();
    canvas.translate(offset.dx, offset.dy);
    final values = protectedRenderingContext.pathValuesFor(path);

    if (values.strokeColor == Colors.transparent &&
        values.fillColor == Colors.transparent) {
      return;
    }
    final paint = _paintForPath(path, values);
    final uiPath = values.pathData;
    if (values.fillColor != Colors.transparent) {
      paint
        ..color = values.fillColor.withOpacity(values.fillAlpha)
        ..style = PaintingStyle.fill;
      canvas.drawPath(uiPath, paint);
    }
    if (values.strokeColor != Colors.transparent) {
      paint
        ..color = values.strokeColor.withOpacity(values.strokeAlpha)
        ..style = PaintingStyle.stroke;
      canvas.drawPath(uiPath, paint);
    }
    canvas.restore();
  }

  void defaultPaintPart(
      PaintingContext context, Offset offset, VectorPart part) {
    if (part is Group) {
      paintGroup(context, offset, part);
    } else if (part is Path) {
      paintPath(context, offset, part);
    } else if (part is ClipPath) {
      paintClipPath(context, offset, part);
    } else if (part is ChildOutlet) {
      paintChildOutlet(context, offset, part);
    } else {
      throw TypeError();
    }
  }

  void defaultPaintChildren(
    PaintingContext context,
    Offset offset,
    List<VectorPart> children,
  ) {
    for (final child in children) {
      paintPart(context, offset, child);
    }
  }

  void defaultPaintChildOutlet(
      PaintingContext context, Offset offset, ChildOutlet childOutlet) {
    final vals = protectedRenderingContext.childOutletValuesFor(childOutlet);
    final rect = vals.rect.shift(offset);

    final paint = Paint()
      ..color = const Color(0xFF455A64)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    final path = ui.Path()
      ..addRect(rect)
      ..addPolygon(<Offset>[rect.topRight, rect.bottomLeft], false)
      ..addPolygon(<Offset>[rect.topLeft, rect.bottomRight], false);
    context.canvas.drawPath(path, paint);
    final tp = TextPainter(
      textDirection: textDirection,
      textScaleFactor: textScaleFactor,
      text: TextSpan(
        text: 'CHILD',
        style: TextStyle(
          color: Colors.red,
          fontSize: 24.0,
        ),
      ),
    );
    tp.layout(minWidth: 0, maxWidth: rect.width);
    final textSize = tp.size;
    final deltaSize = (rect.size - textSize) as Offset;
    final textTl = rect.topLeft + deltaSize / 2;
    tp.paint(context.canvas, textTl);
  }

  void defaultPaintVector(
    PaintingContext context,
    Offset offset,
    Vector vector,
  ) {
    final vectorAlpha =
        ((vector.opacity.resolve(styleResolver) ?? 1.0) * 255).toInt();

    if (vectorAlpha != 255) {
      context.pushOpacity(
        offset,
        vectorAlpha,
        _paintWithOpacity,
      );
      return;
    }

    if (vectorAlpha != 0) {
      _paintWithOpacity(context, offset);
      return;
    }

    // fall thruogh, we dont need an opacity layer, and we dont need to paint
    // because the opacity is zero, therefore the vector is invisible
  }

  void paintInsideOfVector(PaintingContext context, Offset offset);
  void defaultPaintInsideOfVector(PaintingContext context, Offset offset) {
    paintChildren(context, offset, vector.children);
  }

  void transformPaintAndBlendVector(PaintingContext context, Offset offset);

  void defaultTransformPaintAndBlendVector(
      PaintingContext context, Offset offset) {
    final transform = Matrix4.identity();
    var widthScale = size.width / vector.viewportWidth;
    if (textDirection == TextDirection.rtl && vector.autoMirrored) {
      widthScale *= -1;
    }
    var heightScale = size.height / vector.viewportHeight;
    transform.scale(widthScale, heightScale);
    final vectorTintRaw =
        vector.tint.resolve(styleResolver) ?? VectorColor.transparent;
    final vectorTint = vectorTintRaw.asColor;
    context.pushTransform(
      needsCompositing,
      offset,
      transform,
      (context, offset) {
        if (vectorTint != Colors.transparent) {
          context.pushColorFilter(
            offset,
            ColorFilter.mode(
              vectorTint,
              vector.tintMode.asBlendMode,
            ),
            paintInsideOfVector,
          );
        } else {
          paintInsideOfVector(context, offset);
        }
      },
    );
  }

  final LayerHandle<ClipRectLayer> _viewportClipLayer =
      LayerHandle<ClipRectLayer>();

  void _paintWithOpacity(PaintingContext context, Offset offset) {
    final viewportClip = this.viewportClip;
    // TODO

    if (viewportClip == null /* remove this */ || viewportClip == Clip.none) {
      final removedLayer = _viewportClipLayer.layer;
      _viewportClipLayer.layer = null;
      removedLayer?.dispose();
      transformPaintAndBlendVector(context, offset);
      return;
    }
    _viewportClipLayer.layer = context.pushClipRect(
      needsCompositing,
      offset,
      Rect.fromLTWH(
        0,
        0,
        size.width,
        size.height,
      ),
      transformPaintAndBlendVector,
      clipBehavior: viewportClip ?? Clip.none,
      oldLayer: _viewportClipLayer.layer,
    );
  }
}
