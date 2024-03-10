import 'package:vector_drawable_core/src/visiting/visitor.dart';
import 'package:vector_math/vector_math_64.dart' hide Vector;

import '../../vector_drawable_core.dart';

class TransformContextAndViewportScalarScale {
  final BasicTransformContext transformContext;
  final double? viewportScalarScale;

  TransformContextAndViewportScalarScale(
    this.transformContext,
    this.viewportScalarScale,
  );
}

class VectorTransformInlinerVisitor extends VectorDrawableNodeFullVisitor<
    VectorDrawableNode, TransformContextAndViewportScalarScale> {
  @override
  VectorDrawableNode visitAffineGroup(AffineGroup node,
      [TransformContextAndViewportScalarScale? context]) {
    context!;
    if (node.tempTransformList is Property) {
      throw UnimplementedError('fuck you');
    }
    final tempTransformList =
        (node.tempTransformList as Value<TransformOrTransformList>).value;
    context.transformContext.save();
    tempTransformList.applyToProxy(context.transformContext);
    final children = node.children
        .map((e) => e.accept(this, context) as VectorPart)
        .toList();
    context.transformContext.restore();
    return AffineGroup(children: children);
  }

  @override
  VectorDrawableNode visitChildOutlet(ChildOutlet node,
      [TransformContextAndViewportScalarScale? context]) {
    context!;
    if (node.localUsedStyles.isNotEmpty) {
      throw UnimplementedError('fuck you');
    }
    var x = (node.x as Value<double>).value;
    var y = (node.y as Value<double>).value;
    var w = (node.width as Value<double>).value;
    var h = (node.height as Value<double>).value;
    final tl = Vector2(x, y);
    final br = Vector2(x + w, y + h);
    context.transformContext.transformPoint(tl);
    context.transformContext.transformPoint(br);
    final dt = br.clone()..sub(tl);
    x = tl.x;
    y = tl.y;
    w = dt.x;
    h = dt.y;
    return ChildOutlet(
      name: node.name,
      x: Value(x),
      y: Value(y),
      width: Value(w),
      height: Value(h),
    );
  }

  @override
  VectorDrawableNode visitClipPath(ClipPath node,
      [TransformContextAndViewportScalarScale? context]) {
    context!;
    if (node.localUsedStyles.isNotEmpty) {
      throw UnimplementedError('fuck you');
    }
    var pathData = (node.pathData as Value<PathData>).value;
    pathData = context.transformContext.transformPath(pathData);
    return ClipPath(
      pathData: Value(pathData),
      children: node.children
          .map((e) => e.accept(this, context) as VectorPart)
          .toList(),
    );
  }

  @override
  VectorDrawableNode visitGroup(Group node,
      [TransformContextAndViewportScalarScale? context]) {
    context!;
    if (node.localUsedStyles.isNotEmpty) {
      throw UnimplementedError('fuck you');
    }
    final pivotX = (node.pivotX as Value<double>).value;
    final pivotY = (node.pivotY as Value<double>).value;
    final translateX = (node.translateX as Value<double>).value;
    final translateY = (node.translateY as Value<double>).value;
    final scaleX = (node.scaleX as Value<double>).value;
    final scaleY = (node.scaleY as Value<double>).value;
    final rotation = (node.rotation as Value<double>).value;
    context.transformContext.save();
    context.transformContext
      ..translate(Vector2(-pivotX, -pivotY))
      ..scale(Vector2(scaleX, scaleY))
      ..rotate(degrees2Radians * rotation)
      ..translate(Vector2(
        translateX + pivotX,
        translateY + pivotY,
      ));
    final children = node.children
        .map((e) => e.accept(this, context) as VectorPart)
        .toList();
    context.transformContext.restore();
    return Group(
      name: node.name,
      children: children,
    );
  }

  @override
  VectorDrawableNode visitPath(Path node,
      [TransformContextAndViewportScalarScale? context]) {
    context!;
    // use epsilon
    if (context.transformContext.isIdentity() &&
        context.viewportScalarScale == 1.0) {
      return node;
    }
    if ((context.viewportScalarScale != null && node.strokeWidth is Property) ||
        node.pathData is Property) {
      throw UnimplementedError('fuck you');
    }
    var pathData = (node.pathData as Value<PathData>).value;
    pathData = context.transformContext.transformPath(pathData);
    var strokeWidth = (node.strokeWidth as Value<double>).value;
    strokeWidth /= context.viewportScalarScale ?? 1.0;
    return Path(
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

  @override
  VectorDrawableNode visitVector(Vector node,
      [TransformContextAndViewportScalarScale? context]) {
    final transformContext =
        context?.transformContext ?? BasicTransformContext.identity();
    final initialScalarScale = context?.viewportScalarScale ?? 1.0;
    final scaleX = node.width.value / node.viewportWidth;
    final scaleY = node.width.value / node.viewportWidth;
    context = TransformContextAndViewportScalarScale(
        transformContext, initialScalarScale * ((scaleX + scaleY) / 2));
    transformContext.save();
    transformContext.scale(Vector2(scaleX, scaleY));
    final children = node.children
        .map((e) => e.accept(this, context) as VectorPart)
        .toList();
    transformContext.restore();

    return Vector(
      name: node.name,
      width: node.width,
      height: node.height,
      viewportWidth: node.width.value,
      viewportHeight: node.height.value,
      tint: node.tint,
      tintMode: node.tintMode,
      autoMirrored: node.autoMirrored,
      opacity: node.opacity,
      children: children,
    );
  }

  @override
  VectorDrawableNode visitVectorPart(VectorPart node,
          [TransformContextAndViewportScalarScale? context]) =>
      node.accept(this, context);
}
