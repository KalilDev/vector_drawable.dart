import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:md3_clock/widgets/animated_vector/model/vector_drawable.dart';
import 'package:md3_clock/widgets/animated_vector/parsing/vector_drawable.dart';
import 'package:vector_math/vector_math_64.dart' show Vector3;
import 'dart:ui' as ui;
import 'package:path_parsing/path_parsing.dart';

double convertDimension(Dimension dimension, BuildContext context) {
  switch (dimension.kind) {
    case DimensionKind.dip:
    case DimensionKind.dp:
      return dimension.value;
    case DimensionKind.px:
      return dimension.value / MediaQuery.of(context).devicePixelRatio;
    case DimensionKind.sp:
      return dimension.value * MediaQuery.of(context).textScaleFactor;
  }
}

class VectorWidget extends StatelessWidget {
  const VectorWidget({
    Key? key,
    required this.vector,
    this.styleMapping = StyleMapping.empty,
  }) : super(key: key);
  final Vector vector;
  final StyleMapping styleMapping;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty('vector', vector));
    properties.add(DiagnosticsProperty('styleMapping', styleMapping,
        defaultValue: StyleMapping.empty));
  }

  @override
  Widget build(BuildContext context) {
    return _RawVectorWidget(
      vector: vector,
      styleMapping: styleMapping
          .mergeWith(ColorSchemeStyleMapping(Theme.of(context).colorScheme)),
    );
  }
}

class _RawVectorWidget extends LeafRenderObjectWidget {
  const _RawVectorWidget({
    Key? key,
    required this.vector,
    required this.styleMapping,
  }) : super(key: key);

  final Vector vector;
  final StyleMapping styleMapping;

  @override
  RenderObject createRenderObject(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return RenderVector(
      vector: vector,
      devicePixelRatio: mediaQuery.devicePixelRatio,
      textScaleFactor: mediaQuery.textScaleFactor,
      textDirection: Directionality.of(context),
      styleMapping: styleMapping,
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
      ..styleMapping = styleMapping;
  }
}

class _MergedStyleMapping extends StyleMapping with Diagnosticable {
  final StyleMapping a;
  final StyleMapping b;

  _MergedStyleMapping(this.a, this.b);

  @override
  bool contains(StyleColor color) => a.contains(color) || b.contains(color);
  @override
  bool containsAny(Set<StyleColor> colors) =>
      a.containsAny(colors) || b.containsAny(colors);

  @override
  Color? styled(StyleColor color) => a.styled(color) ?? b.styled(color);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    a.debugFillProperties(properties);
    b.debugFillProperties(properties);
  }
}

class ColorSchemeStyleMapping extends StyleMapping with Diagnosticable {
  final ColorScheme scheme;
  ColorSchemeStyleMapping(this.scheme);
  static final _kColorSchemeColors = {
    const StyleColor('android', 'colorBackground'),
    const StyleColor('', 'colorSurface'),
    const StyleColor('', 'colorOnSurface'),
    const StyleColor('', 'colorInverseSurface'),
    const StyleColor('', 'colorOnInverseSurface'),
    const StyleColor('', 'colorInversePrimary'),
    const StyleColor('', 'colorSurfaceVariant'),
    const StyleColor('', 'colorOnSurfaceVariant'),
    const StyleColor('', 'colorOutline'),
    const StyleColor('', 'colorBackground'),
    const StyleColor('', 'colorOnBackground'),
    const StyleColor('', 'colorPrimary'),
    const StyleColor('', 'colorOnPrimary'),
    const StyleColor('', 'colorSecondary'),
    const StyleColor('', 'colorOnSecondary'),
    const StyleColor('', 'colorTertiary'),
    const StyleColor('', 'colorOnTertiary'),
    const StyleColor('', 'colorError'),
    const StyleColor('', 'colorOnError'),
  };

  @override
  bool contains(StyleColor color) => _kColorSchemeColors.contains(color);
  @override
  bool containsAny(Set<StyleColor> colors) =>
      colors.any(_kColorSchemeColors.contains);

  @override
  Color? styled(StyleColor color) {
    if (color == const StyleColor('android', 'colorBackground')) {
      return scheme.background;
    }
    if (color.namespace != '') {
      return null;
    }
    switch (color.name) {
      case 'colorSurface':
        return scheme.surface;
      case 'colorOnSurface':
        return scheme.onSurface;
      case 'colorInverseSurface':
        return scheme.inverseSurface;
      case 'colorOnInverseSurface':
        return scheme.onInverseSurface;
      case 'colorInversePrimary':
        return scheme.inversePrimary;
      case 'colorSurfaceVariant':
        return scheme.surfaceVariant;
      case 'colorOnSurfaceVariant':
        return scheme.onSurfaceVariant;
      case 'colorOutline':
        return scheme.outline;
      case 'colorBackground':
        return scheme.background;
      case 'colorOnBackground':
        return scheme.onBackground;
      case 'colorPrimary':
        return scheme.primary;
      case 'colorOnPrimary':
        return scheme.onPrimary;
      case 'colorSecondary':
        return scheme.secondary;
      case 'colorOnSecondary':
        return scheme.onSecondary;
      case 'colorTertiary':
        return scheme.tertiary;
      case 'colorOnTertiary':
        return scheme.onTertiary;
      case 'colorError':
        return scheme.error;
      case 'colorOnError':
        return scheme.onError;
      default:
        return null;
    }
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty('scheme', scheme));
  }
}

class _EmptyStyleMapping extends StyleMapping with Diagnosticable {
  const _EmptyStyleMapping();
  @override
  bool contains(StyleColor color) => false;

  @override
  bool containsAny(Set<StyleColor> colors) => false;

  @override
  Color? styled(StyleColor color) => null;
}

class DiagnosticableMapEntry<K, V> with Diagnosticable {
  final MapEntry<K, V> _store;
  final String? keyName;
  final String? valueName;

  DiagnosticableMapEntry(this._store, this.keyName, this.valueName);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty(keyName ?? 'key', _store.key));
    properties.add(DiagnosticsProperty(valueName ?? 'value', _store.value));
  }
}

class _MapStyleMapping extends StyleMapping with DiagnosticableTreeMixin {
  final Map<String, Color> map;
  final String namespace;

  _MapStyleMapping(
    this.map, {
    this.namespace = '',
  });

  @override
  bool contains(StyleColor color) =>
      color.namespace == namespace && map.containsKey(color.name);

  @override
  bool containsAny(Set<StyleColor> colors) => colors.any(contains);

  @override
  Color? styled(StyleColor color) {
    if (!contains(color)) {
      return null;
    }
    return map[color.name];
  }

  @override
  List<DiagnosticsNode> debugDescribeChildren() => map.entries
      .map(
          (e) => DiagnosticableMapEntry(e, 'name', 'color').toDiagnosticsNode())
      .toList();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty('namespace', namespace));
  }
}

abstract class StyleMapping implements Diagnosticable {
  const StyleMapping();
  static const StyleMapping empty = _EmptyStyleMapping();
  factory StyleMapping.fromMap(Map<String, Color> map, {String namespace}) =
      _MapStyleMapping;

  bool contains(StyleColor color);
  bool containsAny(Set<StyleColor> colors);
  Color? styled(StyleColor color);
  StyleMapping mergeWith(StyleMapping other) =>
      _MergedStyleMapping(this, other);
  Color? resolve(ColorOrStyleColor color) =>
      color.color ?? styled(color.styleColor!);
}

class RenderVector extends RenderBox {
  RenderVector({
    required Vector vector,
    required double devicePixelRatio,
    required double textScaleFactor,
    required TextDirection textDirection,
    required StyleMapping styleMapping,
  })  : _vector = vector,
        _devicePixelRatio = devicePixelRatio,
        _textScaleFactor = textScaleFactor,
        _textDirection = textDirection,
        _styleMapping = styleMapping;

  Vector _vector;
  Vector get vector => _vector;
  set vector(Vector vector) {
    if (identical(_vector, vector)) {
      return;
    }
    if (vector.width != _vector.width || vector.height != _vector.height) {
      markNeedsLayout();
    }
    markNeedsPaint();
    _vector = vector;
  }

  double _devicePixelRatio;
  double get devicePixelRatio => _devicePixelRatio;
  set devicePixelRatio(double devicePixelRatio) {
    if (_devicePixelRatio == devicePixelRatio) {
      return;
    }
    if (vector.width.kind == DimensionKind.px ||
        vector.height.kind == DimensionKind.px) {
      markNeedsLayout();
    }
    _devicePixelRatio = devicePixelRatio;
  }

  double _textScaleFactor;
  double get textScaleFactor => _textScaleFactor;
  set textScaleFactor(double textScaleFactor) {
    if (_textScaleFactor == textScaleFactor) {
      return;
    }
    if (vector.width.kind == DimensionKind.sp ||
        vector.height.kind == DimensionKind.sp) {
      markNeedsLayout();
    }
    _textScaleFactor = textScaleFactor;
  }

  TextDirection _textDirection;
  TextDirection get textDirection => _textDirection;
  set textDirection(TextDirection textDirection) {
    if (_textDirection == textDirection) {
      return;
    }
    if (vector.autoMirrored) markNeedsPaint();
    _textDirection = textDirection;
  }

  StyleMapping _styleMapping;
  StyleMapping get styleMapping => _styleMapping;
  set styleMapping(StyleMapping styleMapping) {
    if (_styleMapping == styleMapping) {
      return;
    }

    final currentContains = styleMapping.containsAny(vector.usedColors);
    if (currentContains ||
        currentContains != _styleMapping.containsAny(vector.usedColors)) {
      markNeedsPaint();
    }
    _styleMapping = styleMapping;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty('vector', vector));
    properties.add(DiagnosticsProperty('devicePixelRatio', devicePixelRatio));
    properties.add(DoubleProperty('textScaleFactor', textScaleFactor));
    properties.add(EnumProperty('textDirection', textDirection));
    properties.add(DiagnosticsProperty('styleMapping', styleMapping,
        defaultValue: StyleMapping.empty));
  }

  Size _layoutUnconstrained() =>
      Size(_convertDimension(vector.width), _convertDimension(vector.height));
  Size _layoutConstrained(BoxConstraints constraints) =>
      constraints.constrain(_layoutUnconstrained());

  @override
  void performLayout() {
    size = _layoutConstrained(constraints);
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) =>
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

  @override
  bool hitTestSelf(Offset position) => true;

  @override
  double computeMaxIntrinsicHeight(double width) =>
      _convertDimension(vector.height);
  @override
  double computeMinIntrinsicHeight(double width) =>
      _convertDimension(vector.height);
  @override
  double computeMaxIntrinsicWidth(double height) =>
      _convertDimension(vector.width);
  @override
  double computeMinIntrinsicWidth(double height) =>
      _convertDimension(vector.width);

  @override
  bool get needsCompositing => true;
  static bool _groupHasTransform(Group group) =>
      (group.rotation != null && group.rotation != 0) ||
      group.scaleX != null ||
      group.scaleY != null ||
      group.translateX != null ||
      group.translateY != null;

  static double _degToRad(double deg) => (deg / 360) * 2 * pi;

  // https://api.skia.org/classSkMatrix.html#a4fb81568e425b3a6fb5984dac12abb8e
  static Matrix4 _postScale(double x, double y, Matrix4 matrix) {
    final t = Matrix4.diagonal3(Vector3(x, y, 1));
    return t.multiplied(matrix);
  }

  // https://api.skia.org/classSkMatrix.html#a83c8625b53e9a511076b19b92e0f98d0
  static Matrix4 _postTranslate(double x, double y, Matrix4 matrix) {
    final t = Matrix4.translation(Vector3(x, y, 0));
    return t.multiplied(matrix);
  }

  // https://api.skia.org/classSkMatrix.html#a077a39b1cd5c1a7861562f9f20dd1395
  static Matrix4 _postRotate(double degrees, Matrix4 matrix) {
    final t = Matrix4.rotationZ(degrees);
    return t.multiplied(matrix);
  }

  //And the transformations are applied in the order of scale, rotate then translate.
  /* https://github.com/aosp-mirror/platform_frameworks_base/blob/47fed6ba6ab8a68267a9b3ac6cb9decd4ba122ed/libs/hwui/VectorDrawable.cpp
    outMatrix->reset();
    // TODO: use rotate(mRotate, mPivotX, mPivotY) and scale with pivot point, instead of
    // translating to pivot for rotating and scaling, then translating back.
    outMatrix->postTranslate(-properties.getPivotX(), -properties.getPivotY());
    outMatrix->postScale(properties.getScaleX(), properties.getScaleY());
    outMatrix->postRotate(properties.getRotation(), 0, 0);
    outMatrix->postTranslate(properties.getTranslateX() + properties.getPivotX(),
            properties.getTranslateY() + properties.getPivotY());
  */
  static Matrix4 _groupTransform(Group group) {
    var transform = Matrix4.identity();
    transform = _postTranslate(
      -(group.pivotX ?? 0.0),
      -(group.pivotY ?? 0.0),
      transform,
    );
    transform = _postScale(
      group.scaleX ?? 1.0,
      group.scaleY ?? 1.0,
      transform,
    );
    transform = _postRotate(
      _degToRad(group.rotation ?? 0.0),
      transform,
    );
    transform = _postTranslate(
      (group.translateX ?? 0.0) + (group.pivotX ?? 0.0),
      (group.translateY ?? 0.0) + (group.pivotY ?? 0.0),
      transform,
    );
    return transform;
  }

  void _paintGroup(Canvas canvas, Group group) {
    if (_groupHasTransform(group)) {
      canvas.save();
      canvas.transform(_groupTransform(group).storage);
      _paintChildren(canvas, group.children);
      canvas.restore();
    } else {
      _paintChildren(canvas, group.children);
    }
  }

  static void _copySegmentInto(
          PathSegmentData source, PathSegmentData target) =>
      target
        ..command = source.command
        ..targetPoint = source.targetPoint
        ..point1 = source.point1
        ..point2 = source.point2
        ..arcSweep = source.arcSweep
        ..arcLarge = source.arcLarge;

  static ui.Path _uiPathForPath(Path path) {
    final normalizer = SvgPathNormalizer();
    final creator = _UiPathBuilderProxy();
    final mutableSegment = PathSegmentData();
    for (final segment in path.pathData.segments) {
      _copySegmentInto(segment, mutableSegment);
      normalizer.emitSegment(mutableSegment, creator);
    }
    return creator.path;
  }

  // TODO: trimPathStart, trimPathEnd, trimPathOffset, fillType
  static Paint _paintForPath(Path path) {
    final paint = Paint()
      ..strokeWidth = path.strokeWidth
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

  void _paintPath(Canvas canvas, Path path) {
    if (path.strokeColor == null && path.fillColor == null) {
      return;
    }
    final paint = _paintForPath(path);
    final uiPath = _uiPathForPath(path);
    if (path.fillColor != null) {
      final complexColor = path.fillColor!;
      final fillColor =
          complexColor.color ?? styleMapping.styled(complexColor.styleColor!);
      paint
        ..color = fillColor?.withOpacity(path.fillAlpha) ?? Colors.transparent
        ..style = PaintingStyle.fill;
      canvas.drawPath(uiPath, paint);
    }
    if (path.strokeColor != null) {
      final complexColor = path.strokeColor!;
      final strokeColor =
          complexColor.color ?? styleMapping.styled(complexColor.styleColor!);
      paint
        ..color =
            strokeColor?.withOpacity(path.strokeAlpha) ?? Colors.transparent
        ..style = PaintingStyle.stroke;
      canvas.drawPath(uiPath, paint);
    }
  }

  void _paintChildren(Canvas canvas, List<VectorPart> children) {
    for (final child in children) {
      if (child is Group) {
        _paintGroup(canvas, child);
      } else if (child is Path) {
        _paintPath(canvas, child);
      } else {
        throw TypeError();
      }
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final transform = Matrix4.identity();
    var widthScale = size.width / vector.viewportWidth;
    if (textDirection == TextDirection.rtl && vector.autoMirrored) {
      widthScale *= -1;
    }
    var heightScale = size.height / vector.viewportHeight;
    transform.scale(widthScale, heightScale);
    context.pushOpacity(offset, (vector.opacity * 255).toInt(),
        (context, offset) {
      context.pushTransform(
        needsCompositing,
        offset,
        transform,
        (context, offset) {
          final canvas = context.canvas;
          canvas.save();
          canvas.translate(-offset.dx, -offset.dy);
          if (vector.tint != null) {
            canvas.saveLayer(
                null,
                Paint()
                  ..color = vector.tint!
                  ..blendMode = vector.tintMode);
          }
          _paintChildren(canvas, vector.children);
          if (vector.tint != null) {
            canvas.restore();
          }
          canvas.restore();
        },
      );
    });
  }
}

class _UiPathBuilderProxy extends PathProxy {
  final path = ui.Path();

  @override
  void close() => path.close();

  @override
  void cubicTo(
          double x1, double y1, double x2, double y2, double x3, double y3) =>
      path.cubicTo(x1, y1, x2, y2, x3, y3);

  @override
  void lineTo(double x, double y) => path.lineTo(x, y);

  @override
  void moveTo(double x, double y) => path.moveTo(x, y);
}
