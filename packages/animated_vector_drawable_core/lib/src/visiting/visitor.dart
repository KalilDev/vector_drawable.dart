// ignore_for_file: prefer_void_to_null
import 'package:vector_drawable_core/model.dart';
import 'package:vector_drawable_core/visiting.dart';
import '../model/animated_vector_drawable.dart';
import '../model/animation.dart';

@Deprecated('use AnimationResourceIsoVisitor')
abstract class AnimationResourceVisitor<R extends Object>
    implements _AnimationResourceVisitorBase<R, R> {}

abstract class _AnimationResourceVisitorBase<R, Context>
    implements ResourceOrReferenceRawVisitor<R, Context> {
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
    implements ResourceOrReferenceRawVisitor<R, Context> {
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
