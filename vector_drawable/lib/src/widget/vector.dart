import 'dart:developer';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide ClipPath;
import 'package:flutter/rendering.dart';
import 'package:vector_drawable/src/path_utils.dart';
import 'package:vector_drawable/src/widget/model_conversion.dart';
import 'package:vector_math/vector_math_64.dart' show Vector3;
import 'dart:ui' as ui;
import 'package:path_parsing/path_parsing.dart';
import 'package:vector_drawable_core/vector_drawable_core.dart';

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
    this.cachingStrategy = cachingStrategyAll,
    this.viewportClip = Clip.hardEdge,
  }) : super(key: key);
  final Vector vector;
  final StyleMapping styleMapping;
  final Set<RenderVectorCache> cachingStrategy;
  final Clip? viewportClip;
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
        'styleMapping', styleMapping,
        defaultValue: StyleMapping)));
  }

  static const int _cachingStrategyAllBitset =
      _PathFlag | _GroupFlag | _ClipPathFlag | _ChildOutletFlag;

  @override
  Widget build(BuildContext context) {
    return RawVectorWidget(
      vector: vector,
      styleMapping: styleMapping.mergeWith(
        ColorSchemeStyleMapping(Theme.of(context).colorScheme),
      ),
      cachingStrategy: identical(cachingStrategy, cachingStrategyAll)
          ? _cachingStrategyAllBitset
          : _flagsFromSet(cachingStrategy),
      viewportClip: viewportClip,
    );
  }
}

class RawVectorWidget extends LeafRenderObjectWidget {
  const RawVectorWidget({
    Key? key,
    required this.vector,
    required this.styleMapping,
    this.cachingStrategy = 0, // 0b0000
    required this.viewportClip,
  }) : super(key: key);

  final Vector vector;
  final StyleResolver styleMapping;
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
      styleMapping: styleMapping,
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
      ..styleMapping = styleMapping
      ..cachingStrategy = cachingStrategy
      .._viewportClip = viewportClip;
  }
}

class ColorSchemeStyleMapping extends StyleResolverWithEfficientContains
    with Diagnosticable {
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
  bool containsAny(Iterable<StyleProperty> colors) =>
      colors.any(_kColorSchemeColors.contains);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty('scheme', scheme));
  }

  @override
  Object? resolveUntyped(StyleProperty color) {
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

typedef StyleMapping = StyleResolverWithEfficientContains;

class _ClipPathValues {
  final ui.Path pathData;
  _ClipPathValues(
    PathData pathData,
  ) : pathData = _uiPathForPath(pathData);
}

class _PathValues {
  final ui.Path pathData;
  final Color fillColor;
  final Color strokeColor;
  final double strokeWidth;
  final double strokeAlpha;
  final double fillAlpha;

  _PathValues(
    PathData pathData,
    VectorColor fillColor,
    VectorColor strokeColor,
    this.strokeWidth,
    this.strokeAlpha,
    this.fillAlpha,
    double trimPathStart,
    double trimPathEnd,
    double trimPathOffset,
  )   : fillColor = colorFromVectorColor(fillColor),
        strokeColor = colorFromVectorColor(strokeColor),
        pathData = _uiPathForPath(pathData.segmentsFrom(
          (trimPathStart + trimPathOffset)
              .clamp(0.0, (trimPathEnd + trimPathOffset).clamp(0.0, 1.0)),
          (trimPathEnd + trimPathOffset).clamp(0.0, 1.0),
        ));
}

ui.Path _uiPathForPath(PathData pathData) {
  final creator = _UiPathBuilderProxy();
  pathData.emitTo(creator);
  return creator.path;
}

int _flagsFromSet(Set<RenderVectorCache> parts) {
  int result = 0;
  if (parts.contains(RenderVectorCache.clipPath)) {
    result |= 1;
  }
  if (parts.contains(RenderVectorCache.group)) {
    result |= 2;
  }
  if (parts.contains(RenderVectorCache.path)) {
    result |= 4;
  }
  return result;
}

Set<RenderVectorCache> _setFromFlags(int flags) => {
      if (_cacheClipPath(flags)) RenderVectorCache.clipPath,
      if (_cacheGroup(flags)) RenderVectorCache.group,
      if (_cachePath(flags)) RenderVectorCache.path,
      if (_cacheChildOutlet(flags)) RenderVectorCache.childOutlet,
    };
const int _true = 1;
const int _ClipPathFlag = _true >> 0;
const int _GroupFlag = _true >> 1;
const int _PathFlag = _true >> 2;
const int _ChildOutletFlag = _true >> 2;
bool _cacheClipPath(int cacheFlags) =>
    (cacheFlags & _ClipPathFlag) == _ClipPathFlag;
bool _cacheGroup(int cacheFlags) => (cacheFlags & _GroupFlag) == _GroupFlag;
bool _cachePath(int cacheFlags) => (cacheFlags & _PathFlag) == _PathFlag;
bool _cacheChildOutlet(int cacheFlags) =>
    (cacheFlags & _ChildOutletFlag) == _ChildOutletFlag;

enum RenderVectorCache {
  clipPath,
  group,
  path,
  childOutlet,
}

class RenderVector extends RenderBox {
  final Map<Group, _GroupValues> _groupCache = {};
  final Map<Path, _PathValues> _pathCache = {};
  final Map<ClipPath, _ClipPathValues> _clipPathCache = {};
  //final Map<ChildOutlet, _ChildOutletValues> _childOutletValuesCache = {};

  RenderVector({
    required Vector vector,
    required double devicePixelRatio,
    required double textScaleFactor,
    required TextDirection textDirection,
    required StyleResolver styleMapping,
    required int cachingStrategy,
    required Clip? viewportClip,
  })  : _vector = vector,
        _devicePixelRatio = devicePixelRatio,
        _textScaleFactor = textScaleFactor,
        _textDirection = textDirection,
        _styleMapping = styleMapping,
        _cachingStrategy = cachingStrategy,
        _viewportClip = viewportClip;

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
    if (cachingStrategy != 0) {
      final currentContains = styleMapping.containsAny(vector.usedStyles);
      if (currentContains ||
          currentContains != _styleMapping.containsAny(vector.usedStyles)) {
        markNeedsPaint();
      }
      if (_cacheGroup(cachingStrategy)) {
        for (final g in _groupCache.keys.toList()) {
          if (styleMapping.containsAny(g.localUsedStyles)) {
            _groupCache.remove(g);
          }
        }
      }
      if (_cacheClipPath(cachingStrategy)) {
        for (final cp in _clipPathCache.keys.toList()) {
          if (styleMapping.containsAny(cp.localUsedStyles)) {
            _clipPathCache.remove(cp);
          }
        }
      }
      if (_cachePath(cachingStrategy)) {
        for (final p in _pathCache.keys.toList()) {
          if (styleMapping.containsAny(p.localUsedStyles)) {
            _pathCache.remove(p);
          }
        }
      }
    } else {
      markNeedsPaint();
    }
  }

  int _cachingStrategy;
  int get cachingStrategy => _cachingStrategy;
  set cachingStrategy(int cachingStrategy) {
    if (_cachingStrategy == cachingStrategy) {
      return;
    }
    _cachingStrategy = cachingStrategy;
    if (!_cachePath(cachingStrategy)) {
      _pathCache.clear();
    }
    if (!_cacheGroup(cachingStrategy)) {
      _groupCache.clear();
    }
    if (!_cacheClipPath(cachingStrategy)) {
      _clipPathCache.clear();
    }
  }

  Clip? _viewportClip = null;
  Clip? get viewportClip => _viewportClip;
  set viewportClip(Clip? viewportClip) {
    if (_viewportClip == viewportClip) {
      return;
    }
    _viewportClip = viewportClip;
    // TODO: Will not be needed always if the vector already specifies this and
    //       we were null before
    markNeedsPaint();
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
    properties.add(DiagnosticsProperty('viewportClip', viewportClip));
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
  // TODO: check that the position hits the vector
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
    if (_cacheGroup(cachingStrategy)) {
      values = _groupCache.putIfAbsent(
        group,
        () => _GroupValues(
          group.rotation.resolve(styleMapping),
          group.pivotX.resolve(styleMapping),
          group.pivotY.resolve(styleMapping),
          group.scaleX.resolve(styleMapping),
          group.scaleY.resolve(styleMapping),
          group.translateX.resolve(styleMapping),
          group.translateY.resolve(styleMapping),
        ),
      );
    } else {
      values = _GroupValues(
        group.rotation.resolve(styleMapping),
        group.pivotX.resolve(styleMapping),
        group.pivotY.resolve(styleMapping),
        group.scaleX.resolve(styleMapping),
        group.scaleY.resolve(styleMapping),
        group.translateX.resolve(styleMapping),
        group.translateY.resolve(styleMapping),
      );
    }

    final transform = values.transform;
    if (transform == null) {
      _paintChildren(canvas, group.children);
      return;
    }
    canvas.save();
    canvas.transform(transform.storage);
    _paintChildren(canvas, group.children);
    canvas.restore();
  }

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
    _ClipPathValues values;
    if (_cacheClipPath(cachingStrategy)) {
      values = _clipPathCache.putIfAbsent(
          path, () => _ClipPathValues(path.pathData.resolve(styleMapping)!));
    } else {
      values = _ClipPathValues(path.pathData.resolve(styleMapping)!);
    }
    final uiPath = values.pathData;
    // android does not save and restore the canvas
    canvas.clipPath(uiPath);
    _paintChildren(canvas, path.children);
  }

  void _paintPath(Canvas canvas, Path path) {
    if (path.strokeColor == const Value<VectorColor>(VectorColor.transparent) &&
        path.fillColor == const Value<VectorColor>(VectorColor.transparent)) {
      return;
    }
    _PathValues values;
    if (_cachePath(cachingStrategy)) {
      values = _pathCache.putIfAbsent(
        path,
        () => _PathValues(
          path.pathData.resolve(styleMapping)!,
          path.fillColor.resolve(styleMapping)!,
          path.strokeColor.resolve(styleMapping)!,
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
        path.fillColor.resolve(styleMapping)!,
        path.strokeColor.resolve(styleMapping)!,
        path.strokeWidth.resolve(styleMapping)!,
        path.strokeAlpha.resolve(styleMapping)!,
        path.fillAlpha.resolve(styleMapping)!,
        path.trimPathStart.resolve(styleMapping)!,
        path.trimPathEnd.resolve(styleMapping)!,
        path.trimPathOffset.resolve(styleMapping)!,
      );
    }

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

  void _paintWithClippedViewport(PaintingContext context, Offset offset) {
    final transform = Matrix4.identity();
    var widthScale = size.width / vector.viewportWidth;
    if (textDirection == TextDirection.rtl && vector.autoMirrored) {
      widthScale *= -1;
    }
    var heightScale = size.height / vector.viewportHeight;
    transform.scale(widthScale, heightScale);
    final vectorTintRaw =
        vector.tint.resolve(styleMapping) ?? VectorColor.transparent;
    final vectorTint = vectorTintRaw.asColor;
    context.pushTransform(
      needsCompositing,
      offset,
      transform,
      (context, offset) {
        final canvas = context.canvas;
        canvas.save();
        canvas.translate(offset.dx, offset.dy);
        if (vectorTint != Colors.transparent) {
          canvas.saveLayer(
              null,
              Paint()
                ..color = vectorTint
                ..blendMode = vector.tintMode.asBlendMode);
        }
        _paintChildren(canvas, vector.children);
        if (vectorTint != Colors.transparent) {
          // canvas.saveLayer
          canvas.restore();
        }
        // canvas.translate
        canvas.restore();
      },
    );
  }

  final LayerHandle<ClipRectLayer> _viewportClipLayer =
      LayerHandle<ClipRectLayer>();

  void _paintWithOpacity(PaintingContext context, Offset offset) {
    final viewportClip = this.viewportClip;
    if (viewportClip == null /* remove this */ || viewportClip == Clip.none) {
      final removedLayer = _viewportClipLayer.layer;
      _viewportClipLayer.layer = null;
      removedLayer?.dispose();
      _paintWithClippedViewport(context, offset);
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
      _paintWithClippedViewport,
      clipBehavior: viewportClip,
      oldLayer: _viewportClipLayer.layer,
    );
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final vectorAlpha =
        ((vector.opacity.resolve(styleMapping) ?? 1.0) * 255).toInt();

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
