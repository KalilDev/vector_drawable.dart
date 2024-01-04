// ignore_for_file: prefer_void_to_null

import '../model/animated_vector_drawable.dart';
import '../model/animation.dart';
import '../model/resource.dart';
import '../model/vector_drawable.dart';

abstract class _ResourceOrReferenceVisitorBase<R, Context> {
  R visitResourceOrReference<Res extends Resource>(
      ResourceOrReference<Res> node,
      [Context? context]);
  R visitResource<Res extends Resource>(Res node, [Context? context]);
  R visitReference(ResourceReference node, [Context? context]);
}

mixin NoopResourceOrReferenceVisitorMixin<R, Context>
    implements _ResourceOrReferenceVisitorBase<R, Context> {
  @override
  R visitResourceOrReference<Res extends Resource>(
          ResourceOrReference<Res> node,
          [Context? context]) =>
      throw UnimplementedError('NOOP');
  @override
  R visitResource<Res extends Resource>(Res node, [Context? context]) =>
      throw UnimplementedError('NOOP');
  @override
  R visitReference(ResourceReference node, [Context? context]) =>
      throw UnimplementedError('NOOP');
}

@Deprecated('use ResourceOrReferenceIsoVisitor')
abstract class ResourceOrReferenceVisitor<R extends Object>
    implements _ResourceOrReferenceVisitorBase<R, R> {}

@Deprecated(
    "You dont want to use this unless you are creating an extension on vector drawables")
typedef ResourceOrReferenceRawVisitor<R, Context>
    = _ResourceOrReferenceVisitorBase<R, Context>;

typedef ResourceOrReferenceFullVisitor<R, Context extends Object>
    = _ResourceOrReferenceVisitorBase<R, Context>;

typedef ResourceOrReferenceBasicVisitor<R>
    = _ResourceOrReferenceVisitorBase<R, Null>;

typedef ResourceOrReferenceIsoVisitor<R extends Object>
    = _ResourceOrReferenceVisitorBase<R, R>;

abstract class _VectorDrawablePartVisitorBase<R, Context> {
  @Deprecated('use node.accept')
  R visitVectorPart(VectorPart node, [Context? context]);
  R visitGroup(Group node, [Context? context]);
  R visitPath(Path node, [Context? context]);
  R visitClipPath(ClipPath node, [Context? context]);
}

@Deprecated(
    "You dont want to use this unless you are creating an extension on vector drawables")
typedef VectorDrawablePartRawVisitor<R, Context>
    = _VectorDrawablePartVisitorBase<R, Context>;

typedef VectorDrawablePartFullVisitor<R, Context extends Object>
    = _VectorDrawablePartVisitorBase<R, Context>;

typedef VectorDrawablePartBasicVisitor<R>
    = _VectorDrawablePartVisitorBase<R, Null>;

typedef VectorDrawablePartIsoVisitor<R extends Object>
    = _VectorDrawablePartVisitorBase<R, R>;

abstract class _VectorDrawableNodeVisitorBase<R, Context>
    implements _VectorDrawablePartVisitorBase<R, Context> {
  R visitVector(Vector node, [Context? context]);
}

@Deprecated(
    "You dont want to use this unless you are creating an extension on vector drawables")
typedef VectorDrawableNodeRawVisitor<R, Context>
    = _VectorDrawableNodeVisitorBase<R, Context>;

typedef VectorDrawableNodeFullVisitor<R, Context extends Object>
    = _VectorDrawableNodeVisitorBase<R, Context>;

typedef VectorDrawableNodeBasicVisitor<R>
    = _VectorDrawableNodeVisitorBase<R, Null>;

typedef VectorDrawableNodeIsoVisitor<R extends Object>
    = _VectorDrawableNodeVisitorBase<R, R>;

@Deprecated('use ResourceOrReferenceIsoVisitor')
abstract class VectorDrawableVisitor<R extends Object>
    implements _VectorDrawableVisitorBase<R, R> {}

abstract class _VectorDrawableVisitorBase<R, Context>
    implements
        _ResourceOrReferenceVisitorBase<R, Context>,
        _VectorDrawableNodeVisitorBase<R, Context> {
  R visitVectorDrawable(VectorDrawable node, [Context? context]);
}

@Deprecated(
    "You dont want to use this unless you are creating an extension on vector drawables")
typedef VectorDrawableRawVisitor<R, Context>
    = _VectorDrawableVisitorBase<R, Context>;

typedef VectorDrawableFullVisitor<R, Context extends Object>
    = _VectorDrawableVisitorBase<R, Context>;

typedef VectorDrawableBasicVisitor<R> = _VectorDrawableVisitorBase<R, Null>;

typedef VectorDrawableIsoVisitor<R extends Object>
    = _VectorDrawableVisitorBase<R, R>;

@Deprecated('use AnimationResourceIsoVisitor')
abstract class AnimationResourceVisitor<R extends Object>
    implements _AnimationResourceVisitorBase<R, R> {}

abstract class _AnimationResourceVisitorBase<R, Context>
    implements _ResourceOrReferenceVisitorBase<R, Context> {
  R visitAnimationResource(AnimationResource node, [Context? context]);
  R visitAnimationNode(AnimationNode node, [Context? context]);
  R visitAnimationSet(AnimationSet node, [Context? context]);
  R visitObjectAnimation(ObjectAnimation node, [Context? context]);
  R visitPropertyValuesHolder(PropertyValuesHolder node, [Context? context]);
  R visitInterpolator(Interpolator node, [Context? context]);
}

@Deprecated(
    "You dont want to use this unless you are creating an extension on vector drawables")
typedef AnimationResourceRawVisitor<R, Context>
    = _AnimationResourceVisitorBase<R, Context>;

typedef AnimationResourceFullVisitor<R, Context extends Object>
    = _AnimationResourceVisitorBase<R, Context>;

typedef AnimationResourceBasicVisitor<R>
    = _AnimationResourceVisitorBase<R, Null>;

typedef AnimationResourceIsoVisitor<R extends Object>
    = _AnimationResourceVisitorBase<R, R>;

@Deprecated('use AnimatedVectorDrawableIsoVisitor')
abstract class AnimatedVectorDrawableVisitor<R extends Object>
    implements _AnimatedVectorDrawableVisitorBase<R, R> {}

abstract class _AnimatedVectorDrawableVisitorBase<R, Context>
    implements _ResourceOrReferenceVisitorBase<R, Context> {
  R visitAnimatedVectorDrawable(AnimatedVectorDrawable node,
      [Context? context]);
  R visitAnimationResource(AnimationResource node, [Context? context]);
  R visitVectorDrawable(VectorDrawable node, [Context? context]);

  R visitTarget(Target node, [Context? context]);
  R visitAnimatedVector(AnimatedVector node, [Context? context]);
}

@Deprecated(
    "You dont want to use this unless you are creating an extension on vector drawables")
typedef AnimatedVectorDrawableRawVisitor<R, Context>
    = _AnimatedVectorDrawableVisitorBase<R, Context>;

typedef AnimatedVectorDrawableFullVisitor<R, Context extends Object>
    = _AnimatedVectorDrawableVisitorBase<R, Context>;

typedef AnimatedVectorDrawableBasicVisitor<R>
    = _AnimatedVectorDrawableVisitorBase<R, Null>;

typedef AnimatedVectorDrawableIsoVisitor<R extends Object>
    = _AnimatedVectorDrawableVisitorBase<R, R>;
