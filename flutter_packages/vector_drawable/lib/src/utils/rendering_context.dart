import 'dart:math';
import 'dart:ui' as ui;

import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide ClipPath;
import 'package:path_parsing/path_parsing.dart';
import 'package:vector_drawable/src/path_utils.dart';
import 'package:vector_drawable/src/widget/vector.dart' show VectorWidget;
import 'package:vector_drawable_core/model.dart';
import 'package:vector_math/vector_math_64.dart' hide Vector;

import 'cache.dart';
import 'model_conversion.dart';
import 'render_vector_flags.dart';

class VectorRenderingContext {
  VectorRenderingContext({
    required Vector vector,
    required double devicePixelRatio,
    required double textScaleFactor,
    required TextDirection textDirection,
    required StyleResolver styleResolver,
    required int cachingStrategy,
    required Clip? viewportClip,
  })  : _vector = vector,
        _devicePixelRatio = devicePixelRatio,
        _textScaleFactor = textScaleFactor,
        _textDirection = textDirection,
        _styleResolver = styleResolver,
        _cachingStrategy = cachingStrategy,
        _viewportClip = viewportClip {
    _debugVerifyHasAllStyles();
  }

  void _debugVerifyHasAllStyles() {
    if (!kDebugMode) {
      return;
    }
    final missing = <StyleProperty>{};
    for (final style in vector.usedStyles) {
      if (!_styleResolver.contains(style)) {
        missing.add(style);
      }
    }
    if (missing.isEmpty) {
      return;
    }
    // ignore: avoid_print
    print('The following styles are missing: ${missing.toList()}');
  }

  final Cache<Vector, VectorValues> _vectorCache = SingleCache();
  final Cache<Group, GroupValues> _groupCache = MapCache();
  final Cache<AffineGroup, GroupValues> _affineGroupCache = MapCache();
  final Cache<Path, PathValues> _pathCache = MapCache();
  final Cache<ClipPath, ClipPathValues> _clipPathCache = MapCache();
  final Cache<ChildOutlet, ChildOutletValues> _childOutletCache = SingleCache();
  final Cache<Vector, ChildOutletAndParents> _childOutletAndParentsCache =
      SingleCache();

  Vector _vector;
  Vector get vector => _vector;
  int setVector(Vector vector) {
    if (identical(_vector, vector)) {
      return needsNothing;
    }
    _vectorCache.clear();
    _groupCache.clear();
    _affineGroupCache.clear();
    _pathCache.clear();
    _clipPathCache.clear();
    _childOutletCache.clear();
    _childOutletAndParentsCache.clear();

    var needs = needsNothing;
    if (vector.width != _vector.width || vector.height != _vector.height) {
      // TODO: if there is an child outlet, we also need to layout again if the child outlet and/or transforms that are parent to it have changed
      needs |= needsLayoutFlag;
    }
    needs |= needsPaintFlag;
    _vector = vector;
    return needs;
  }

  double _devicePixelRatio;
  double get devicePixelRatio => _devicePixelRatio;
  int setDevicePixelRatio(double devicePixelRatio) {
    if (_devicePixelRatio == devicePixelRatio) {
      return needsNothing;
    }
    var needs = needsNothing;
    if (vector.width.kind == DimensionKind.px ||
        vector.height.kind == DimensionKind.px) {
      needs |= needsLayoutFlag;
    }
    _devicePixelRatio = devicePixelRatio;
    return needs;
  }

  double _textScaleFactor;
  double get textScaleFactor => _textScaleFactor;
  int setTextScaleFactor(double textScaleFactor) {
    if (_textScaleFactor == textScaleFactor) {
      return needsNothing;
    }
    var needs = needsNothing;
    if (vector.width.kind == DimensionKind.sp ||
        vector.height.kind == DimensionKind.sp) {
      needs |= needsLayoutFlag;
    }
    _textScaleFactor = textScaleFactor;
    return needs;
  }

  TextDirection _textDirection;
  TextDirection get textDirection => _textDirection;
  int setTextDirection(TextDirection textDirection) {
    if (_textDirection == textDirection) {
      return needsNothing;
    }
    var needs = needsNothing;
    if (vector.autoMirrored) needs |= needsPaintFlag;
    _textDirection = textDirection;
    return needs;
  }

  StyleResolver _styleResolver;
  StyleResolver get styleResolver => _styleResolver;
  int setStyleMapping(StyleResolver styleResolver) {
    if (cachingStrategy != 0) {
      final currentContains = styleResolver.containsAny(vector.usedStyles);
      var needs = needsNothing;
      if (currentContains ||
          currentContains != _styleResolver.containsAny(vector.usedStyles)) {
        needs |= needsPaintFlag;
      }
      if (cacheGroup(cachingStrategy)) {
        for (final g in _groupCache.keys.toList()) {
          if (styleResolver.containsAny(g.localUsedStyles)) {
            _groupCache.remove(g);
          }
        }
      }
      if (cacheAffineGroup(cachingStrategy)) {
        for (final g in _affineGroupCache.keys.toList()) {
          if (styleResolver.containsAny(g.localUsedStyles)) {
            _affineGroupCache.remove(g);
          }
        }
      }
      if (cacheClipPath(cachingStrategy)) {
        for (final cp in _clipPathCache.keys.toList()) {
          if (styleResolver.containsAny(cp.localUsedStyles)) {
            _clipPathCache.remove(cp);
          }
        }
      }
      if (cachePath(cachingStrategy)) {
        for (final p in _pathCache.keys.toList()) {
          if (styleResolver.containsAny(p.localUsedStyles)) {
            _pathCache.remove(p);
          }
        }
      }
      if (cacheChildOutlet(cachingStrategy)) {
        for (final co in _childOutletCache.keys.toList()) {
          if (styleResolver.containsAny(co.localUsedStyles)) {
            _childOutletCache.remove(co);
            needs |= needsChildLayoutFlag;
          }
        }
      }
      if (cacheVector(cachingStrategy)) {
        for (final vec in _vectorCache.keys.toList()) {
          if (styleResolver.containsAny(vec.localUsedStyles)) {
            _vectorCache.remove(vec);
          }
        }
      }
      _debugVerifyHasAllStyles();
      _styleResolver = styleResolver;
      return needs;
    } else {
      _debugVerifyHasAllStyles();
      _styleResolver = styleResolver;
      return needsPaintFlag | needsChildLayoutFlag;
    }
  }

  int _cachingStrategy;
  int get cachingStrategy => _cachingStrategy;
  set cachingStrategy(int cachingStrategy) {
    if (_cachingStrategy == cachingStrategy) {
      return;
    }
    _cachingStrategy = cachingStrategy;
    if (!cachePath(cachingStrategy)) {
      _pathCache.clear();
    }
    if (!cacheGroup(cachingStrategy)) {
      _groupCache.clear();
    }
    if (!cacheClipPath(cachingStrategy)) {
      _clipPathCache.clear();
    }
    if (!cacheChildOutlet(cachingStrategy)) {
      _childOutletCache.clear();
    }
    if (!cacheAffineGroup(cachingStrategy)) {
      _affineGroupCache.clear();
    }
  }

  Clip? _viewportClip = null;
  Clip? get viewportClip => _viewportClip;
  int setViewportClip(Clip? viewportClip) {
    if (_viewportClip == viewportClip) {
      return needsNothing;
    }
    _viewportClip = viewportClip;
    // TODO: Will not be needed always if the vector already specifies this and
    //       we were null before
    return needsPaintFlag;
  }

  PathValues pathValuesFor(Path path) {
    if (cachePath(cachingStrategy)) {
      return _pathCache.putIfAbsent(
        path,
        () => PathValues(
          path.pathData.resolve(styleResolver) ??
              _default(PathData.fromSegments([])),
          path.fillColor.resolve(styleResolver) ??
              _default(VectorColor.transparent),
          path.strokeColor.resolve(styleResolver) ??
              _default(VectorColor.transparent),
          path.strokeWidth.resolve(styleResolver) ?? _default(1.0),
          path.strokeAlpha.resolve(styleResolver) ?? _default(0.0),
          path.fillAlpha.resolve(styleResolver) ?? _default(0.0),
          path.trimPathStart.resolve(styleResolver) ?? _default(0.0),
          path.trimPathEnd.resolve(styleResolver) ?? _default(1.0),
          path.trimPathOffset.resolve(styleResolver) ?? _default(0.0),
        ),
      );
    } else {
      return PathValues(
        path.pathData.resolve(styleResolver) ??
            _default(PathData.fromSegments([])),
        path.fillColor.resolve(styleResolver) ??
            _default(VectorColor.transparent),
        path.strokeColor.resolve(styleResolver) ??
            _default(VectorColor.transparent),
        path.strokeWidth.resolve(styleResolver) ?? _default(1.0),
        path.strokeAlpha.resolve(styleResolver) ?? _default(0.0),
        path.fillAlpha.resolve(styleResolver) ?? _default(0.0),
        path.trimPathStart.resolve(styleResolver) ?? _default(0.0),
        path.trimPathEnd.resolve(styleResolver) ?? _default(1.0),
        path.trimPathOffset.resolve(styleResolver) ?? _default(0.0),
      );
    }
  }

  GroupValues groupValuesFor(Group group) {
    if (cacheGroup(cachingStrategy)) {
      return _groupCache.putIfAbsent(
        group,
        () => GroupValues(
          group.rotation.resolve(styleResolver),
          group.pivotX.resolve(styleResolver),
          group.pivotY.resolve(styleResolver),
          group.scaleX.resolve(styleResolver),
          group.scaleY.resolve(styleResolver),
          group.translateX.resolve(styleResolver),
          group.translateY.resolve(styleResolver),
        ),
      );
    }
    return GroupValues(
      group.rotation.resolve(styleResolver),
      group.pivotX.resolve(styleResolver),
      group.pivotY.resolve(styleResolver),
      group.scaleX.resolve(styleResolver),
      group.scaleY.resolve(styleResolver),
      group.translateX.resolve(styleResolver),
      group.translateY.resolve(styleResolver),
    );
  }

  GroupValues groupValuesForAffine(AffineGroup group) {
    if (cacheAffineGroup(cachingStrategy)) {
      return _affineGroupCache.putIfAbsent(
        group,
        () => GroupValues.affineTransformOrTransformList(
          group.tempTransformList.resolve(styleResolver),
        ),
      );
    }
    return GroupValues.affineTransformOrTransformList(
      group.tempTransformList.resolve(styleResolver),
    );
  }

  T _default<T extends Object>(T value) => value;

  ChildOutletValues childOutletValuesFor(ChildOutlet childOutlet) {
    if (cacheChildOutlet(cachingStrategy)) {
      return _childOutletCache.putIfAbsent(
        childOutlet,
        () => ChildOutletValues(
          childOutlet.x.resolve(styleResolver) ?? _default(0.0),
          childOutlet.y.resolve(styleResolver) ?? _default(0.0),
          childOutlet.width.resolve(styleResolver) ?? _default(20.0),
          childOutlet.height.resolve(styleResolver) ?? _default(20.0),
        ),
      );
    }
    return ChildOutletValues(
      childOutlet.x.resolve(styleResolver) ?? _default(0.0),
      childOutlet.y.resolve(styleResolver) ?? _default(0.0),
      childOutlet.width.resolve(styleResolver) ?? _default(20.0),
      childOutlet.height.resolve(styleResolver) ?? _default(20.0),
    );
  }

  ClipPathValues clipPathValuesFor(ClipPath clipPath) {
    if (cacheClipPath(cachingStrategy)) {
      return _clipPathCache.putIfAbsent(
        clipPath,
        () => ClipPathValues(
          clipPath.pathData.resolve(styleResolver) ??
              _default(PathData.fromSegments([])),
        ),
      );
    }
    return ClipPathValues(
      clipPath.pathData.resolve(styleResolver) ??
          _default(PathData.fromSegments([])),
    );
  }

  ChildOutletValues childOutletValues() =>
      childOutletValuesFor(childOutletAndParents().childOutlet);

  ChildOutletAndParents childOutletAndParents() {
    if (true) {
      return _childOutletAndParentsCache.putIfAbsent(
          vector, _computeChildOutletAndParents);
    }
    assert(false, "you really dont want to do this every frame");
  }

  ChildOutletAndParents _computeChildOutletAndParents() {
    final searchStack = _SearchStack();
    searchStack.pushRoot(vector);
    while (searchStack.canPop) {
      final el = searchStack.pop();
      if (el.node is ChildOutlet) {
        return ChildOutletAndParents(
          el.node as ChildOutlet,
          el.parents.skip(1).cast<VectorPart>().toList(),
        );
      }
      if (el.node is VectorPartWithChildren) {
        searchStack.pushChildren(
          el.node,
          el.parents,
          (el.node as VectorPartWithChildren).children,
        );
        continue;
      }
      if (el.node is Vector) {
        searchStack.pushChildren(
          el.node,
          el.parents,
          (el.node as Vector).children,
        );
        continue;
      }
    }
    throw Exception('you cant place a child in this vector');
  }

  Matrix4 neededChildOutletTransform(Size vectorWidgetSize) =>
      neededChildOutletLayers(vectorWidgetSize)
          .where((e) => e.transform != null)
          .fold(
            Matrix4.identity(),
            (acc, e) => acc
              ..multiply(
                e.transform!,
              ),
          );

  List<ChildOutletTransformOrClipPath> neededChildOutletLayers(
      Size vectorWidgetSize) {
    final cops = childOutletAndParents();
    final vectorTransform = Matrix4.identity();
    {
      var widthScale = vectorWidgetSize.width / vector.viewportWidth;
      if (textDirection == TextDirection.rtl && vector.autoMirrored) {
        widthScale *= -1;
      }
      var heightScale = vectorWidgetSize.height / vector.viewportHeight;
      vectorTransform.scale(widthScale, heightScale);
    }
    ChildOutletTransformOrClipPath? currentOperation =
        ChildOutletTransformOrClipPath(vectorTransform, null);
    final allOperations = <ChildOutletTransformOrClipPath>[];
    for (final parent in cops.parentsOtherThanRoot) {
      if (parent is Group || parent is AffineGroup) {
        final values = parent is Group
            ? groupValuesFor(parent)
            : groupValuesForAffine(parent as AffineGroup);
        final groupTransform = values.transform;
        if (groupTransform == null) {
          continue;
        }
        // There was no previous op
        if (currentOperation == null) {
          currentOperation =
              ChildOutletTransformOrClipPath(groupTransform.clone(), null);
          continue;
        }
        // The previous op was a transform
        if (currentOperation.transform != null) {
          currentOperation.transform!.multiply(groupTransform);
          continue;
        }
        // The previous op was a clipPath
        allOperations.add(currentOperation);
        currentOperation =
            ChildOutletTransformOrClipPath(groupTransform.clone(), null);
        continue;
      }
      if (parent is ClipPath) {
        final values = clipPathValuesFor(parent);
        final clipPathPath = values.pathData;
        // There was no previous op
        if (currentOperation == null) {
          currentOperation = ChildOutletTransformOrClipPath(null, clipPathPath);
          continue;
        }
        // The previous op was a clipPath
        if (currentOperation.clipPath != null) {
          currentOperation.clipPath = ui.Path.combine(PathOperation.intersect,
              currentOperation.clipPath!, clipPathPath);
          continue;
        }
        // The previous op was a transform
        allOperations.add(currentOperation);
        currentOperation = ChildOutletTransformOrClipPath(null, clipPathPath);
        continue;
      }
      throw UnimplementedError('fuck');
    }
    if (currentOperation != null) {
      allOperations.add(currentOperation);
    }
    return allOperations;
  }
}

class ClipPathValues {
  final ui.Path pathData;
  ClipPathValues(
    PathData pathData,
  ) : pathData = _uiPathForPath(pathData);
}

class GroupValues {
  final Matrix4? transform;

  factory GroupValues.affine(
    double? rotation,
    double? scaleX,
    double? scaleY,
    double? translateX,
    double? translateY,
  ) {
    if (_groupHasTransform(rotation, scaleX, scaleY, translateX, translateY)) {
      return GroupValues._(
        _affineGroupTransform(
          rotation ?? 0,
          scaleX ?? 1,
          scaleY ?? 1,
          translateX ?? 0,
          translateY ?? 0,
        ).getMatrix(),
      );
    }
    return const GroupValues._(null);
  }
  factory GroupValues.affineTransformOrTransformList(
      TransformOrTransformList? transformOrTransformList) {
    if (transformOrTransformList == null) {
      return const GroupValues._(null);
    }
    if (transformOrTransformList is NoneTransform) {
      return const GroupValues._(null);
    }
    if ((transformOrTransformList is TransformList) &&
        transformOrTransformList.transforms.isEmpty) {
      return const GroupValues._(null);
    }
    final matrix = transformOrTransformList.toMatrix();
    if (matrix.isIdentity()) {
      return const GroupValues._(null);
    }
    return GroupValues._(matrix.getMatrix());
  }
  factory GroupValues(
    double? rotation,
    double? pivotX,
    double? pivotY,
    double? scaleX,
    double? scaleY,
    double? translateX,
    double? translateY,
  ) {
    if (_groupHasTransform(rotation, scaleX, scaleY, translateX, translateY)) {
      return GroupValues._(
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
    return const GroupValues._(null);
  }

  const GroupValues._(this.transform);

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

  static AffineMatrix _affineGroupTransform(
    double rotation,
    double scaleX,
    double scaleY,
    double translateX,
    double translateY,
  ) {
    final affineMatrix = AffineMatrix.identity();
    affineMatrix
      ..translate(Vector2(
        translateX,
        translateY,
      ))
      ..rotate(rotation)
      ..scale(
        scaleX,
        scaleY,
      );
    return affineMatrix;
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

class PathValues {
  final ui.Path pathData;
  final Color fillColor;
  final Color strokeColor;
  final double strokeWidth;
  final double strokeAlpha;
  final double fillAlpha;

  PathValues(
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

class ChildOutletValues {
  final Rect rect;

  ChildOutletValues(
    double x,
    double y,
    double width,
    double height,
  ) : rect = Offset(x, y) & Size(width, height);
}

class ParentsAndNode {
  final List<VectorDrawableNode> parents;
  final VectorDrawableNode node;

  ParentsAndNode(this.parents, this.node);
}

// FIFO
class _SearchStack {
  final Queue<ParentsAndNode> _stack = Queue();
  void pushRoot(VectorDrawableNode child) {
    final entry = ParentsAndNode([], child);
    _stack.addLast(entry);
  }

  void push(VectorDrawableNode immediateParent,
      List<VectorDrawableNode> parents, VectorDrawableNode child) {
    final entry = ParentsAndNode([...parents, immediateParent], child);
    _stack.addLast(entry);
  }

  void pushChildren(VectorDrawableNode immediateParent,
      List<VectorDrawableNode> parents, Iterable<VectorPart> children) {
    for (final child in children) {
      push(immediateParent, parents, child);
    }
  }

  bool get canPop => _stack.isNotEmpty;

  ParentsAndNode pop() => _stack.removeFirst();
}

class VectorValues {}

class ChildOutletAndParents {
  final ChildOutlet childOutlet;
  final List<VectorPart> parentsOtherThanRoot;

  ChildOutletAndParents(this.childOutlet, this.parentsOtherThanRoot);
}

class ChildOutletTransformOrClipPath {
  final Matrix4? transform;
  ui.Path? _clipPath;

  ChildOutletTransformOrClipPath(this.transform, this._clipPath);

  ui.Path? get clipPath => _clipPath;
  set clipPath(ui.Path? clipPath) {
    if (transform != null) {
      throw Exception('fuuuuck you');
    }
    if (clipPath == null) {
      throw Exception('fuuuuck you too');
    }
    _clipPath = clipPath;
  }
}

ui.Path _uiPathForPath(PathData pathData) {
  final creator = _UiPathBuilderProxy();
  pathData.emitTo(creator);
  return creator.path;
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

const int _false = 0;
const int _true = 1;
const int needsNothing = _false;
const int needsLayoutFlag = _true << 0;
const int needsPaintFlag = _true << 1;
const int needsChildLayoutFlag = _true << 2;
