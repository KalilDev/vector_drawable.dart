import 'dart:math';

import 'package:vector_drawable_core/src/visiting/visitor.dart';
import 'package:vector_math/vector_math_64.dart' hide Vector;

import '../../vector_drawable_core.dart';

class ChildAndViewportTransformIdGenerator {
  int _viewportTransformNumber = 0;
  int _childNumber = 0;
  int claimChild() => _childNumber++;
  int claimViewportTransform() => _viewportTransformNumber++;
}

class ViewportTransform {
  final ReadableTransformProxyWithTransformList transform;
  final bool isRoot;
  final ChildAndViewportTransformIdGenerator idGenerator;

  ViewportTransform(this.transform, this.isRoot, this.idGenerator);

  ViewportTransform forkNotRoot() => ViewportTransform(
      transform.clone() as ReadableTransformProxyWithTransformList,
      false,
      idGenerator);
}

class VectorViewportTransformerVisitor extends VectorDrawableNodeFullVisitor<
    VectorDrawableNode, ViewportTransform> {
  @override
  VectorDrawableNode visitAffineGroup(AffineGroup node,
      [ViewportTransform? context]) {
    if (context == null) {
      return node;
    }
    final ValueOrProperty<TransformOrTransformList> tempTransformList;
    final bool needsFallbackGroup;
    if (context.isRoot) {
      needsFallbackGroup =
          node.tempTransformList is Property<TransformOrTransformList>;
      if (!needsFallbackGroup) {
        var transformList =
            (node.tempTransformList as Value<TransformOrTransformList>).value;
        transformList = TransformList([
          ...context.transform.protectedTransformList.transforms,
          if (transformList is TransformList)
            ...transformList.transforms
          else
            transformList as Transform
        ]);
        tempTransformList = Value(transformList);
      } else {
        tempTransformList = node.tempTransformList;
      }
    } else {
      needsFallbackGroup = false;
      tempTransformList = node.tempTransformList;
    }
    final childrenContext = context.forkNotRoot();
    return AffineGroup(
      name: node.name,
      tempTransformList: tempTransformList,
      children: node.children
          .map((e) => e.accept(this, childrenContext) as VectorPart)
          .toList(),
    );
  }

  @override
  VectorDrawableNode visitChildOutlet(ChildOutlet node,
      [ViewportTransform? context]) {
    if (context == null) {
      return node;
    }
    if (node.localUsedStyles.isNotEmpty) {
      return makeFallbackGroup(node, context);
    }
    var x = (node.x as Value<double>).value;
    var y = (node.y as Value<double>).value;
    var w = (node.width as Value<double>).value;
    var h = (node.height as Value<double>).value;
    final tl = Vector2(x, y);
    final br = Vector2(x + w, y + h);
    context.transform.transformPoint(tl);
    context.transform.transformPoint(br);
    final l = min(tl.x, br.x);
    final t = min(tl.y, br.y);
    final r = max(tl.x, br.x);
    final b = max(tl.y, br.y);
    return ChildOutlet(
      name: node.name,
      x: Value(l),
      y: Value(t),
      width: Value(r - l),
      height: Value(b - t),
    );
  }

  @override
  VectorDrawableNode visitClipPath(ClipPath node,
      [ViewportTransform? context]) {
    if (context == null) {
      return node;
    }
    final childrenContext = context.forkNotRoot();
    if (node.pathData is Property) {
      return makeFallbackGroup(node, childrenContext);
    }
    var pathData = (node.pathData as Value<PathData>).value;
    if (context.isRoot) {
      pathData = context.transform.transformPath(pathData);
    }
    return ClipPath(
      name: node.name,
      pathData: Value(pathData),
      children: node.children
          .map((e) => e.accept(this, childrenContext) as VectorPart)
          .toList(),
    );
  }

  VectorDrawableNode makeFallbackGroup(
    VectorPart child,
    ViewportTransform context,
  ) {
    if (!context.isRoot) {
      return child;
    }
    final childName = child.name ?? 'child-${context.idGenerator.claimChild()}';
    final affineName =
        'synthetic-viewport-transform-${context.idGenerator.claimViewportTransform()}-for-$childName';
    return AffineGroup(
      name: affineName,
      tempTransformList: Value(
        TransformList(
          context.transform.protectedTransformList.transforms.toList(),
        ),
      ),
      children: [
        child,
      ],
    );
  }

  @override
  VectorDrawableNode visitGroup(Group node, [ViewportTransform? context]) {
    if (context == null) {
      return node;
    }
    final childrenContext = context.forkNotRoot();
    final out = Group(
      name: node.name,
      rotation: node.rotation,
      pivotX: node.pivotX,
      pivotY: node.pivotY,
      scaleX: node.scaleX,
      scaleY: node.scaleY,
      translateX: node.translateX,
      translateY: node.translateY,
      children: node.children
          .map((e) => e.accept(this, childrenContext) as VectorPart)
          .toList(),
    );
    return makeFallbackGroup(out, context);
  }

  @override
  VectorDrawableNode visitPath(Path node, [ViewportTransform? context]) {
    if (context == null) {
      return node;
    }
    if (context.transform.isIdentity()) {
      return node;
    }
    if (node.pathData is Property) {
      return makeFallbackGroup(node, context);
    }
    if (node.strokeWidth is Property) {
      throw UnimplementedError('fuck you');
    }
    var pathData = (node.pathData as Value<PathData>).value;
    var strokeWidth = (node.strokeWidth as Value<double>).value;
    if (context.isRoot) {
      pathData = context.transform.transformPath(pathData);
    }
    // TODO: do i need this
    //strokeWidth /= context.transform.getScalarScale();
    return Path(
      name: node.name,
      pathData: Value(pathData),
      fillColor: node.fillColor,
      strokeColor: node.strokeColor,
      strokeWidth: Value(strokeWidth),
      strokeAlpha: node.strokeAlpha,
      fillAlpha: node.fillAlpha,
      trimPathStart: node.trimPathStart,
      trimPathEnd: node.trimPathEnd,
      trimPathOffset: node.trimPathOffset,
      strokeLineCap: node.strokeLineCap,
      strokeLineJoin: node.strokeLineJoin,
      strokeMiterLimit: node.strokeMiterLimit,
      fillType: node.fillType,
    );
  }

  static BasicTransformContext _viewportTransformFor(Vector node) {
    final scaleX = node.width.value / node.viewportWidth;
    final scaleY = node.height.value / node.viewportHeight;
    return BasicTransformContext.identity()..scale(Vector2(scaleX, scaleY));
  }

  @override
  VectorDrawableNode visitVector(Vector node, [ViewportTransform? context]) {
    context ??= ViewportTransform(_viewportTransformFor(node), true,
        ChildAndViewportTransformIdGenerator());
    final transformScale = context.transform.getScale();
    final viewportWidth = node.viewportWidth * transformScale.x;
    final viewportHeight = node.viewportHeight * transformScale.y;
    return Vector(
      name: node.name,
      width: node.width,
      height: node.height,
      viewportWidth: viewportWidth,
      viewportHeight: viewportHeight,
      tint: node.tint,
      tintMode: node.tintMode,
      autoMirrored: node.autoMirrored,
      opacity: node.opacity,
      children: node.children
          .map((e) => e.accept(this, context) as VectorPart)
          .toList(),
    );
  }

  @override
  VectorDrawableNode visitVectorPart(VectorPart node,
          [ViewportTransform? context]) =>
      node.accept(this, context);
}
