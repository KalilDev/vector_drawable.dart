import 'dart:async';
import 'package:vector_drawable_core/visiting.dart';

import '../../model.dart';
import '../model/animated_vector_drawable.dart';
import '../model/animation.dart';

Iterable<R> _walkAnimationNode<R>(
  AnimationNode animation, {
  required R Function(AnimationSet) onAnimationSet,
  required R Function(ObjectAnimation) onObjectAnimation,
}) sync* {
  if (animation is AnimationSet) {
    yield onAnimationSet(animation);
    for (final node in animation.children) {
      yield* _walkAnimationNode(
        node,
        onAnimationSet: onAnimationSet,
        onObjectAnimation: onObjectAnimation,
      );
    }
  } else if (animation is ObjectAnimation) {
    yield onObjectAnimation(animation);
  } else {
    throw TypeError();
  }
}

Iterable<R> walkAnimationResource<R>(
  AnimationResource animation, {
  required R Function(AnimationResource) onAnimationResource,
  required R Function(AnimationSet) onAnimationSet,
  required R Function(ObjectAnimation) onObjectAnimation,
}) sync* {
  yield onAnimationResource(animation);
  yield* _walkAnimationNode(
    animation.body,
    onAnimationSet: onAnimationSet,
    onObjectAnimation: onObjectAnimation,
  );
}

Iterable<R> walkAnimatedVector<R>(
  AnimatedVector vector, {
  required R Function(AnimatedVector) onAnimatedVector,
  required R Function(ResourceOrReference<VectorDrawable>) onDrawable,
  required R Function(ResourceOrReference<AnimationResource>) onAnimation,
  required R Function(Target) onTarget,
}) sync* {
  yield onAnimatedVector(vector);
  yield onDrawable(vector.drawable);
  for (final target in vector.children) {
    yield onTarget(target);
    yield onAnimation(target.animation);
  }
}

Iterable<T> _empty<T>(_) => <T>[];
Iterable<ResourceOrReference> findAllUnresolvedReferencesInAnimationResource(
  AnimationResource anim,
) =>
    walkAnimationResource<Iterable<ResourceOrReference>>(
      anim,
      onAnimationResource: _empty,
      onAnimationSet: _empty,
      onObjectAnimation: (e) => <ResourceOrReference>[
        if (e.interpolator != null) e.interpolator!,
        ...(e.valueHolders?.map((e) => e.interpolator).whereType() ?? []),
        ...(e.valueHolders
                ?.expand((e) =>
                    e.keyframes?.map((e) => e.interpolator).whereType() ?? [])
                .whereType() ??
            [])
      ].where((e) => !e.isResolved),
    ).expand((e) => e);
Iterable<ResourceOrReference> findAllUnresolvedReferencesInAnimatedVector(
  AnimatedVector vec,
) =>
    walkAnimatedVector<Iterable<ResourceOrReference>>(
      vec,
      onAnimatedVector: _empty,
      onDrawable: (d) => d.isResolved ? [] : [d],
      onAnimation: (d) => d.isResolved
          ? findAllUnresolvedReferencesInAnimationResource(d.resource!)
          : [d],
      onTarget: _empty,
    ).expand((e) => e);
