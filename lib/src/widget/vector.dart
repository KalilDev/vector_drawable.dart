import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide ClipPath;
import 'package:flutter/rendering.dart';
import '../model/path.dart';
import '../model/style.dart';
import '../model/vector_drawable.dart';
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
    return RawVectorWidget(
      vector: vector,
      styleMapping: styleMapping.mergeWith(
        ColorSchemeStyleMapping(Theme.of(context).colorScheme),
      ),
      cachingStrategy: RenderVectorCachingStrategy.groupAndPath,
    );
  }
}

class RawVectorWidget extends LeafRenderObjectWidget {
  const RawVectorWidget({
    Key? key,
    required this.vector,
    required this.styleMapping,
    this.cachingStrategy = RenderVectorCachingStrategy.none,
  }) : super(key: key);

  final Vector vector;
  final StyleResolver styleMapping;
  final RenderVectorCachingStrategy cachingStrategy;

  @override
  RenderObject createRenderObject(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return RenderVector(
      vector: vector,
      devicePixelRatio: mediaQuery.devicePixelRatio,
      textScaleFactor: mediaQuery.textScaleFactor,
      textDirection: Directionality.of(context),
      styleMapping: styleMapping,
      cachingStrategy: cachingStrategy,
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
      ..styleMapping = styleMapping
      ..cachingStrategy = cachingStrategy;
  }
}

class _MergedStyleMapping extends StyleMapping with Diagnosticable {
  final StyleMapping a;
  final StyleMapping b;

  _MergedStyleMapping(this.a, this.b);

  @override
  bool contains(StyleProperty color) => a.contains(color) || b.contains(color);
  @override
  bool containsAny(Set<StyleProperty> colors) =>
      a.containsAny(colors) || b.containsAny(colors);

  @override
  T? resolve<T>(StyleProperty color) => a.resolve(color) ?? b.resolve(color);

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
    const StyleProperty('android', 'colorBackground'),
    const StyleProperty('', 'colorSurface'),
    const StyleProperty('', 'colorOnSurface'),
    const StyleProperty('', 'colorInverseSurface'),
    const StyleProperty('', 'colorOnInverseSurface'),
    const StyleProperty('', 'colorInversePrimary'),
    const StyleProperty('', 'colorSurfaceVariant'),
    const StyleProperty('', 'colorOnSurfaceVariant'),
    const StyleProperty('', 'colorOutline'),
    const StyleProperty('', 'colorBackground'),
    const StyleProperty('', 'colorOnBackground'),
    const StyleProperty('', 'colorPrimary'),
    const StyleProperty('', 'colorOnPrimary'),
    const StyleProperty('', 'colorSecondary'),
    const StyleProperty('', 'colorOnSecondary'),
    const StyleProperty('', 'colorTertiary'),
    const StyleProperty('', 'colorOnTertiary'),
    const StyleProperty('', 'colorError'),
    const StyleProperty('', 'colorOnError'),
  };

  @override
  bool contains(StyleProperty color) => _kColorSchemeColors.contains(color);
  @override
  bool containsAny(Set<StyleProperty> colors) =>
      colors.any(_kColorSchemeColors.contains);

  @override
  T? resolve<T>(StyleProperty color) {
    if (T != Color) {
      return null;
    }
    Color? _resolveColor() {
      if (color == const StyleProperty('android', 'colorBackground')) {
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
        case 'colorPrimaryContainer':
          return scheme.primaryContainer;
        case 'colorOnPrimaryContainer':
          return scheme.onPrimaryContainer;
        case 'colorSecondary':
          return scheme.secondary;
        case 'colorOnSecondary':
          return scheme.onSecondary;
        case 'colorSecondaryContainer':
          return scheme.secondaryContainer;
        case 'colorOnSecondaryContainer':
          return scheme.onSecondaryContainer;
        case 'colorTertiary':
          return scheme.tertiary;
        case 'colorOnTertiary':
          return scheme.onTertiary;
        case 'colorTertiaryContainer':
          return scheme.tertiaryContainer;
        case 'colorOnTertiaryContainer':
          return scheme.onTertiaryContainer;
        case 'colorError':
          return scheme.error;
        case 'colorOnError':
          return scheme.onError;
        default:
          return null;
      }
    }

    return _resolveColor() as T;
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
  bool contains(StyleProperty color) => false;

  @override
  bool containsAny(Set<StyleProperty> colors) => false;

  @override
  T? resolve<T>(StyleProperty color) => null;
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
  final Map<String, Object> map;
  final String namespace;

  _MapStyleMapping(
    this.map, {
    this.namespace = '',
  });

  @override
  bool contains(StyleProperty color) =>
      color.namespace == namespace && map.containsKey(color.name);

  @override
  bool containsAny(Set<StyleProperty> colors) => colors.any(contains);

  @override
  T? resolve<T>(StyleProperty prop) {
    if (!contains(prop)) {
      return null;
    }
    return map[prop.name] as T?;
  }

  @override
  List<DiagnosticsNode> debugDescribeChildren() => map.entries
      .map((e) => DiagnosticableMapEntry(e, 'name', 'styledProperty')
          .toDiagnosticsNode())
      .toList();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty('namespace', namespace));
  }
}

class _GroupValues {
  final Matrix4? transform;

  factory _GroupValues(
    double? rotation,
    double? pivotX,
    double? pivotY,
    double? scaleX,
    double? scaleY,
    double? translateX,
    double? translateY,
  ) {
    if (_groupHasTransform(rotation, scaleX, scaleY, translateX, translateY)) {
      return _GroupValues._(
        _groupTransform(
          rotation ?? 0,
          pivotX ?? 0,
          pivotY ?? 0,
          scaleX ?? 1,
          scaleY ?? 1,
          translateX ?? 0,
          translateY ?? 0,
        ),
      );
    }
    return const _GroupValues._(null);
  }

  const _GroupValues._(this.transform);

  static bool _groupHasTransform(
    double? rotation,
    double? scaleX,
    double? scaleY,
    double? translateX,
    double? translateY,
  ) =>
      (rotation != null && rotation != 0) ||
      (scaleX != null && scaleX != 1) ||
      (scaleY != null && scaleY != 1) ||
      (translateX != null && translateX != 0) ||
      (translateY != null && translateY != 0);

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
  static Matrix4 _groupTransform(
    double rotation,
    double pivotX,
    double pivotY,
    double scaleX,
    double scaleY,
    double translateX,
    double translateY,
  ) {
    var transform = Matrix4.identity();
    transform = _postTranslate(
      -pivotX,
      -pivotY,
      transform,
    );
    transform = _postScale(
      scaleX,
      scaleY,
      transform,
    );
    transform = _postRotate(
      _degToRad(rotation),
      transform,
    );
    transform = _postTranslate(
      translateX + pivotX,
      translateY + pivotY,
      transform,
    );
    return transform;
  }
}

abstract class StyleMapping implements StyleResolver, Diagnosticable {
  const StyleMapping();
  static const StyleMapping empty = _EmptyStyleMapping();
  factory StyleMapping.fromMap(Map<String, Object> map, {String namespace}) =
      _MapStyleMapping;

  bool contains(StyleProperty prop);
  bool containsAny(Set<StyleProperty> props);
  StyleMapping mergeWith(StyleMapping other) =>
      _MergedStyleMapping(this, other);
}

class _PathValues {
  final PathData pathData;
  final Color? fillColor;
  final Color? strokeColor;
  final double strokeWidth;
  final double strokeAlpha;
  final double fillAlpha;

  _PathValues(
    PathData pathData,
    this.fillColor,
    this.strokeColor,
    this.strokeWidth,
    this.strokeAlpha,
    this.fillAlpha,
    double trimPathStart,
    double trimPathEnd,
    double trimPathOffset,
  ) : pathData = pathData.segmentsFrom(
          (trimPathStart + trimPathOffset)
              .clamp(0.0, (trimPathEnd + trimPathOffset).clamp(0.0, 1.0)),
          (trimPathEnd + trimPathOffset).clamp(0.0, 1.0),
        );
}

enum RenderVectorCachingStrategy {
  groupAndPath,
  group,
  path,
  none,
}

class RenderVector extends RenderBox {
  final Map<Group, _GroupValues> _groupCache = {};
  final Map<Path, _PathValues> _pathCache = {};
  RenderVector({
    required Vector vector,
    required double devicePixelRatio,
    required double textScaleFactor,
    required TextDirection textDirection,
    required StyleResolver styleMapping,
    required RenderVectorCachingStrategy cachingStrategy,
  })  : _vector = vector,
        _devicePixelRatio = devicePixelRatio,
        _textScaleFactor = textScaleFactor,
        _textDirection = textDirection,
        _styleMapping = styleMapping,
        _cachingStrategy = cachingStrategy;

  Vector _vector;
  Vector get vector => _vector;
  set vector(Vector vector) {
    if (identical(_vector, vector)) {
      return;
    }
    _groupCache.clear();
    _pathCache.clear();
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

  StyleResolver _styleMapping;
  StyleResolver get styleMapping => _styleMapping;
  set styleMapping(StyleResolver styleMapping) {
    if (_styleMapping == styleMapping) {
      return;
    }

    if (cachingStrategy != RenderVectorCachingStrategy.none) {
      final currentContains = styleMapping.containsAny(vector.usedStyles);
      if (currentContains ||
          currentContains != _styleMapping.containsAny(vector.usedStyles)) {
        markNeedsPaint();
      }
      if (cachingStrategy == RenderVectorCachingStrategy.group ||
          cachingStrategy == RenderVectorCachingStrategy.groupAndPath) {
        for (final g in _groupCache.keys.toList()) {
          if (styleMapping.containsAny(g.localUsedStyles)) {
            _groupCache.remove(g);
          }
        }
      }
      if (cachingStrategy == RenderVectorCachingStrategy.path ||
          cachingStrategy == RenderVectorCachingStrategy.groupAndPath) {
        for (final p in _pathCache.keys.toList()) {
          if (styleMapping.containsAny(p.usedStyles)) {
            _pathCache.remove(p);
          }
        }
      }
    } else {
      markNeedsPaint();
    }
    _styleMapping = styleMapping;
  }

  RenderVectorCachingStrategy _cachingStrategy;
  RenderVectorCachingStrategy get cachingStrategy => _cachingStrategy;
  set cachingStrategy(RenderVectorCachingStrategy cachingStrategy) {
    if (_cachingStrategy == cachingStrategy) {
      return;
    }
    _cachingStrategy = cachingStrategy;
    if (cachingStrategy == RenderVectorCachingStrategy.group) {
      _pathCache.clear();
    } else if (cachingStrategy == RenderVectorCachingStrategy.path) {
      _groupCache.clear();
    } else if (cachingStrategy == RenderVectorCachingStrategy.none) {
      _pathCache.clear();
      _groupCache.clear();
    }
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty('vector', vector));
    properties.add(DiagnosticsProperty('devicePixelRatio', devicePixelRatio));
    properties.add(DoubleProperty('textScaleFactor', textScaleFactor));
    properties.add(EnumProperty('textDirection', textDirection));
    properties.add(DiagnosticsProperty('styleMapping', styleMapping,
        defaultValue: StyleMapping.empty, style: DiagnosticsTreeStyle.sparse));
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

  void _paintGroup(Canvas canvas, Group group) {
    _GroupValues values;
    if (cachingStrategy == RenderVectorCachingStrategy.group ||
        cachingStrategy == RenderVectorCachingStrategy.groupAndPath) {
      values = _groupCache.putIfAbsent(
        group,
        () => _GroupValues(
          group.rotation?.resolve(styleMapping),
          group.pivotX?.resolve(styleMapping),
          group.pivotY?.resolve(styleMapping),
          group.scaleX?.resolve(styleMapping),
          group.scaleY?.resolve(styleMapping),
          group.translateX?.resolve(styleMapping),
          group.translateY?.resolve(styleMapping),
        ),
      );
    } else {
      values = _GroupValues(
        group.rotation?.resolve(styleMapping),
        group.pivotX?.resolve(styleMapping),
        group.pivotY?.resolve(styleMapping),
        group.scaleX?.resolve(styleMapping),
        group.scaleY?.resolve(styleMapping),
        group.translateX?.resolve(styleMapping),
        group.translateY?.resolve(styleMapping),
      );
    }

    final transform = values.transform;
    if (transform != null) {
      canvas.save();
      canvas.transform(transform.storage);
      _paintChildren(canvas, group.children);
      canvas.restore();
    } else {
      _paintChildren(canvas, group.children);
    }
  }

  static ui.Path _uiPathForPath(PathData pathData) {
    final creator = _UiPathBuilderProxy();
    pathData.emitTo(creator);
    return creator.path;
  }

  // TODO: trimPathStart, trimPathEnd, trimPathOffset, fillType
  static Paint _paintForPath(Path path, _PathValues values) {
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

  // According to https://github.com/aosp-mirror/platform_frameworks_base/blob/47fed6ba6ab8a68267a9b3ac6cb9decd4ba122ed/libs/hwui/VectorDrawable.cpp#L264
  // there is no save layer and restore layer.
  void _paintClipPath(Canvas canvas, ClipPath path) {
    final uiPath = _uiPathForPath(path.pathData.resolve(styleMapping)!);
    canvas.clipPath(uiPath);
    _paintChildren(canvas, path.children);
  }

  void _paintPath(Canvas canvas, Path path) {
    if (path.strokeColor == null && path.fillColor == null) {
      return;
    }
    _PathValues values;
    if (cachingStrategy == RenderVectorCachingStrategy.path ||
        cachingStrategy == RenderVectorCachingStrategy.groupAndPath) {
      values = _pathCache.putIfAbsent(
        path,
        () => _PathValues(
          path.pathData.resolve(styleMapping)!,
          path.fillColor?.resolve(styleMapping),
          path.strokeColor?.resolve(styleMapping),
          path.strokeWidth.resolve(styleMapping)!,
          path.strokeAlpha.resolve(styleMapping)!,
          path.fillAlpha.resolve(styleMapping)!,
          path.trimPathStart.resolve(styleMapping)!,
          path.trimPathEnd.resolve(styleMapping)!,
          path.trimPathOffset.resolve(styleMapping)!,
        ),
      );
    } else {
      values = _PathValues(
        path.pathData.resolve(styleMapping)!,
        path.fillColor?.resolve(styleMapping),
        path.strokeColor?.resolve(styleMapping),
        path.strokeWidth.resolve(styleMapping)!,
        path.strokeAlpha.resolve(styleMapping)!,
        path.fillAlpha.resolve(styleMapping)!,
        path.trimPathStart.resolve(styleMapping)!,
        path.trimPathEnd.resolve(styleMapping)!,
        path.trimPathOffset.resolve(styleMapping)!,
      );
    }
    if (values.strokeColor == null && values.fillColor == null) {
      return;
    }

    if (values.strokeColor == Colors.transparent &&
        values.fillColor == Colors.transparent) {
      return;
    }
    final paint = _paintForPath(path, values);
    final uiPath = _uiPathForPath(values.pathData);
    if (values.fillColor != null) {
      paint
        ..color = values.fillColor?.withOpacity(values.fillAlpha) ??
            Colors.transparent
        ..style = PaintingStyle.fill;
      canvas.drawPath(uiPath, paint);
    }
    if (path.strokeColor != null) {
      paint
        ..color = values.strokeColor?.withOpacity(values.strokeAlpha) ??
            Colors.transparent
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
      } else if (child is ClipPath) {
        _paintClipPath(canvas, child);
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
    context.pushOpacity(
        offset, (vector.opacity.resolve(styleMapping)! * 255).toInt(),
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
                  ..color = vector.tint!.resolve(styleMapping)!
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
