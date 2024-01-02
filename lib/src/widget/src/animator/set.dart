import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:vector_drawable/src/model/style.dart';
import 'package:value_listenables/value_listenables.dart';
import 'package:vector_drawable/src/widget/src/util.dart';
import 'package:vector_drawable/vector_drawable.dart';

import 'animator.dart';
import 'object.dart';

abstract class AnimatorSet extends Animator with DiagnosticableTreeMixin {
  final List<Animator> children;
  AnimatorSet._(this.children);

  @override
  List<DiagnosticsNode> debugDescribeChildren() =>
      children.map((e) => e.toDiagnosticsNode()).toList();

  factory AnimatorSet({
    required AnimationSet animation,
    required Animator Function(AnimationNode) childFactory,
  }) {
    if (animation.children.isEmpty) {
      return EmptyAnimatorSet();
    }
    final children = animation.children.map(childFactory).toList();
    switch (animation.ordering) {
      case AnimationOrdering.together:
        return TogetherAnimatorSet(children);
      case AnimationOrdering.sequentially:
        return SequentialAnimatorSet(children);
    }
  }

  @override
  Iterable<String> get nonUniqueAnimatedAttributes =>
      children.expand((e) => e.nonUniqueAnimatedAttributes);
}

class SequentialAnimatorSet extends AnimatorSet {
  SequentialAnimatorSet(List<Animator> children) : super._(children);
  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
  }

  @override
  Duration get totalDuration =>
      children.fold(Duration.zero, (acc, b) => acc + b.totalDuration);

  @override
  Map<String, StyleResolvable<Object>> values(Duration timeFromStart) {
    Duration elapsedDuration = Duration.zero;
    final result = <String, StyleResolvable<Object>>{};
    for (final child in children) {
      if (elapsedDuration > timeFromStart) {
        break;
      }
      result.addAll(child.values(timeFromStart - elapsedDuration));
      elapsedDuration += child.totalDuration;
    }
    return result;
  }

  @override
  AnimatorStatus status(Duration timeFromStart) {
    Duration elapsedDuration = Duration.zero;
    AnimatorStatus result = AnimatorStatus.dismissed;
    for (final child in children) {
      if (child.totalDuration + elapsedDuration < timeFromStart) {
        elapsedDuration += child.totalDuration;
        continue;
      }
      result = child.status((timeFromStart - elapsedDuration));
      break;
    }
    return result;
  }
}

class EmptyAnimatorSet extends AnimatorSet {
  EmptyAnimatorSet() : super._(const []);

  @override
  AnimatorStatus status(Duration timeFromStart) => AnimatorStatus.dismissed;

  @override
  Duration get totalDuration => Duration.zero;

  @override
  Map<String, StyleResolvable<Object>> values(Duration timeFromStart) =>
      const {};
}

/// When sorting with this order, in order to find the value at any point
/// becomes as simple as walking the children in sorted order and adding the
/// values for Animators at the correct state (forward, reverse or completed),
/// while overriding the already stored result value.
///
/// Take the following example:
/// |---*-------*----------*---------------------------------+---------------|
/// <---1--->   1          1                                 1
/// <---2-------2----------2------------------------------>  2
///    <3-------3--->      3                                 3
///     -       -  <-------4--------------------------->     4
///     -       -  <-------5---------------------------------5--------------->
///
int _byTraverseOrder(Animator a, Animator b) {
  Duration aDelay = a is ObjectAnimator ? a.startDelay : Duration.zero;
  Duration bDelay = b is ObjectAnimator ? b.startDelay : Duration.zero;
  final delayResult = aDelay.compareTo(bDelay);
  if (delayResult != 0) {
    return delayResult;
  }

  Duration aDuration = a.totalDuration;
  Duration bDuration = b.totalDuration;
  return aDuration.compareTo(bDuration);
}

class TogetherAnimatorSet extends AnimatorSet {
  final Duration _duration;
  final Duration _delayDuration;
  final ValueNotifier<AnimatorStatus> _status;

  TogetherAnimatorSet(List<Animator> children)
      : _duration = children
            .reduce((a, b) => a.totalDuration > b.totalDuration ? a : b)
            .totalDuration,
        _delayDuration = children.fold<Duration>(Duration.zero, (max, e) {
          final delay = (e is ObjectAnimator) ? e.startDelay : Duration.zero;
          return max > delay ? delay : max;
        }),
        _status = ValueNotifier(AnimatorStatus.dismissed),
        super._(children.toList()..sort(_byTraverseOrder));

  @override
  AnimatorStatus status(Duration timeFromStart) {
    if (timeFromStart == Duration.zero) {
      return AnimatorStatus.dismissed;
    }
    if (timeFromStart >= _duration) {
      return AnimatorStatus.completed;
    }
    if (timeFromStart <= _delayDuration) {
      return AnimatorStatus.delay;
    }
    return AnimatorStatus.forward;
  }

  @override
  Duration get totalDuration => _duration;

  @override
  Map<String, StyleResolvable<Object>> values(Duration timeFromStart) {
    final ignoredStates = {AnimatorStatus.delay, AnimatorStatus.dismissed};
    final result = <String, StyleResolvable<Object>>{};
    // The children are sorted in the traverse order already.
    for (final activeChild in children
        .where((e) => !ignoredStates.contains(e.status(timeFromStart)))) {
      result.addAll(activeChild.values(timeFromStart));
    }

    return result;
  }
}
