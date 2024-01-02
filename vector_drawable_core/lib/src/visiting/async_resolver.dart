import 'dart:async';

import '../model/animated_vector_drawable.dart';
import '../model/animation.dart';
import '../model/resource.dart';
import '../model/vector_drawable.dart';

abstract class AsyncResourceResolver {
  Future<R?> resolve<R extends Resource>(ResourceReference reference);
  Future<void> resolveMany(Iterable<ResourceOrReference> reference);
}

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

Iterable<R> _walkVectorPart<R>(
  VectorPart part, {
  required R Function(Path) onPath,
  required R Function(Group) onGroup,
  required R Function(ClipPath) onClipPath,
}) sync* {
  if (part is Path) {
    yield onPath(part);
  } else if (part is Group) {
    yield onGroup(part);
    for (final part in part.children) {
      yield* _walkVectorPart(
        part,
        onPath: onPath,
        onGroup: onGroup,
        onClipPath: onClipPath,
      );
    }
  } else if (part is ClipPath) {
    yield onClipPath(part);
    for (final part in part.children) {
      yield* _walkVectorPart(
        part,
        onPath: onPath,
        onGroup: onGroup,
        onClipPath: onClipPath,
      );
    }
  } else {
    throw TypeError();
  }
}

Iterable<R> walkVectorDrawable<R>(
  VectorDrawable vector, {
  required R Function(VectorDrawable) onVectorDrawable,
  required R Function(Vector) onVector,
  required R Function(Path) onPath,
  required R Function(Group) onGroup,
  required R Function(ClipPath) onClipPath,
}) sync* {
  yield onVectorDrawable(vector);
  yield onVector(vector.body);
  for (final part in vector.body.children) {
    yield* _walkVectorPart(
      part,
      onPath: onPath,
      onGroup: onGroup,
      onClipPath: onClipPath,
    );
  }
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
