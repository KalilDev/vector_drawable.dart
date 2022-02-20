import 'dart:async';
import 'dart:io';
import 'dart:ui';

import '../model/animated_vector_drawable.dart';
import '../model/animation.dart';
import '../model/resource.dart';
import '../model/style.dart';
import '../model/vector_drawable.dart';
import '../parsing/vector_drawable.dart';
import 'visitor.dart';

abstract class AsyncResourceResolver {
  Future<R?> resolve<R extends Resource>(ResourceReference reference);
  Future<void> resolveMany(Iterable<ResourceOrReference> reference);
}

R _walkAnimationNode<R>(
  AnimationNode animation, {
  required R Function(AnimationSet) onAnimationSet,
  required R Function(ObjectAnimation) onObjectAnimation,
  required R Function(R, R) reducer,
}) =>
    animation is AnimationSet
        ? reducer(
            onAnimationSet(animation),
            animation.children
                .map(
                  (node) => _walkAnimationNode(
                    node,
                    onAnimationSet: onAnimationSet,
                    onObjectAnimation: onObjectAnimation,
                    reducer: reducer,
                  ),
                )
                .reduce(reducer),
          )
        : animation is ObjectAnimation
            ? onObjectAnimation(animation)
            : throw TypeError();

R walkAnimationResource<R>(
  AnimationResource animation, {
  required R Function(AnimationResource) onAnimationResource,
  required R Function(AnimationSet) onAnimationSet,
  required R Function(ObjectAnimation) onObjectAnimation,
  required R Function(R, R) reducer,
}) =>
    reducer(
      onAnimationResource(animation),
      _walkAnimationNode(
        animation.body,
        onAnimationSet: onAnimationSet,
        onObjectAnimation: onObjectAnimation,
        reducer: reducer,
      ),
    );
R _walkVectorPart<R>(
  VectorPart part, {
  required R Function(Path) onPath,
  required R Function(Group) onGroup,
  required R Function(ClipPath) onClipPath,
  required R Function(R, R) reducer,
}) =>
    part is Path
        ? onPath(part)
        : part is Group
            ? reducer(
                onGroup(part),
                part.children
                    .map((e) => _walkVectorPart(
                          part,
                          onPath: onPath,
                          onGroup: onGroup,
                          onClipPath: onClipPath,
                          reducer: reducer,
                        ))
                    .reduce(reducer))
            : part is ClipPath
                ? reducer(
                    onClipPath(part),
                    part.children
                        .map((e) => _walkVectorPart(
                              part,
                              onPath: onPath,
                              onGroup: onGroup,
                              onClipPath: onClipPath,
                              reducer: reducer,
                            ))
                        .reduce(reducer))
                : throw TypeError();
R walkVectorDrawable<R>(
  VectorDrawable vector, {
  required R Function(VectorDrawable) onVectorDrawable,
  required R Function(Vector) onVector,
  required R Function(Path) onPath,
  required R Function(Group) onGroup,
  required R Function(ClipPath) onClipPath,
  required R Function(R, R) reducer,
}) =>
    reducer(
        onVectorDrawable(vector),
        reducer(
          onVector(vector.body),
          vector.body.children
              .map((part) => _walkVectorPart(
                    part,
                    onPath: onPath,
                    onGroup: onGroup,
                    onClipPath: onClipPath,
                    reducer: reducer,
                  ))
              .reduce(reducer),
        ));

R walkAnimatedVector<R>(
  AnimatedVector vector, {
  required R Function(AnimatedVector) onAnimatedVector,
  required R Function(ResourceOrReference<VectorDrawable>) onDrawable,
  required R Function(ResourceOrReference<AnimationResource>) onAnimation,
  required R Function(Target) onTarget,
  required R Function(R, R) reducer,
}) =>
    reducer(
      onAnimatedVector(vector),
      reducer(
        onDrawable(vector.drawable),
        vector.children
            .map(
              (target) => reducer(
                onTarget(target),
                onAnimation(target.animation),
              ),
            )
            .reduce(reducer),
      ),
    );
Iterable<T> _empty<T>(_) => <T>[];
Iterable<ResourceOrReference> findAllUnresolvedReferencesInVectorDrawable(
  VectorDrawable vec,
) =>
    walkVectorDrawable(
      vec,
      onVectorDrawable: _empty,
      onVector: _empty,
      onPath: _empty,
      onGroup: _empty,
      onClipPath: _empty,
      reducer: (a, b) => a.followedBy(b),
    );
Iterable<ResourceOrReference> findAllUnresolvedReferencesInAnimationResource(
  AnimationResource anim,
) =>
    walkAnimationResource(
      anim,
      reducer: (a, b) => a.followedBy(b),
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
    );
Iterable<ResourceOrReference> findAllUnresolvedReferencesInAnimatedVector(
  AnimatedVector vec,
) =>
    walkAnimatedVector(
      vec,
      onAnimatedVector: _empty,
      onDrawable: (d) => d.isResolved
          ? findAllUnresolvedReferencesInVectorDrawable(d.resource!)
          : [d],
      onAnimation: (d) => d.isResolved
          ? findAllUnresolvedReferencesInAnimationResource(d.resource!)
          : [d],
      onTarget: _empty,
      reducer: (a, b) => a.followedBy(b),
    );
