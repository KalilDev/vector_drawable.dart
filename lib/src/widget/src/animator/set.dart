import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:vector_drawable/src/model/style.dart';
import 'package:value_notifier/value_notifier.dart';
import 'package:vector_drawable/src/widget/src/util.dart';
import 'package:vector_drawable/vector_drawable.dart';

import 'animator.dart';
import 'object.dart';

abstract class AnimatorSet extends AnimatorWithValues
    with DiagnosticableTreeMixin {
  final List<AnimatorWithValues> children;
  AnimatorSet._(this.children);

  @override
  List<DiagnosticsNode> debugDescribeChildren() =>
      children.map((e) => e.toDiagnosticsNode()).toList();

  factory AnimatorSet({
    required AnimationSet animation,
    required AnimatorWithValues Function(AnimationNode) childFactory,
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
  void dispose() {
    for (final animation in children) {
      animation.dispose();
    }
  }

  @override
  void reset({bool toFinish = false}) {
    for (final animation in children) {
      animation.reset(toFinish: toFinish);
    }
  }

  @override
  void stop({bool reset = false}) {
    for (final animation in children) {
      animation.stop(reset: reset);
    }
  }

  @override
  Iterable<String> get nonUniqueAnimatedAttributes =>
      children.expand((e) => e.nonUniqueAnimatedAttributes);
}

class SequentialAnimatorSet extends AnimatorSet {
  final ValueNotifier<AnimatorWithValues> _current;

  SequentialAnimatorSet(List<AnimatorWithValues> children)
      : _current = ValueNotifier(children.first),
        super._(children);
  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty('current', _current.value));
  }

  @override
  void reset({bool toFinish = false}) {
    super.reset(toFinish: toFinish);
    _current.value = toFinish ? children.last : children.first;
  }

  @override
  Future<void> start({bool forward = true, bool fromStart = false}) async {
    if (fromStart) {
      reset(toFinish: !forward);
    }
    for (final animation in forward ? children : children.reversed) {
      _current.value = animation;
      try {
        await animation.start(forward: forward, fromStart: fromStart);
      } on TickerCanceled {
        break;
      }
    }
  }

  @override
  ValueListenable<AnimatorStatus> get status =>
      _current.view().bind((current) => current.status);

  void dispose() {
    _current.dispose();
    super.dispose();
  }

  @override
  Duration get totalDuration =>
      children.fold(Duration.zero, (acc, b) => acc + b.totalDuration);

  @override
  Listenable get changes =>
      _current.view().bind((c) => c.changes.asValueListenable);

  @override
  Map<String, StyleResolvable<Object>> get values {
    final finishedState = status.value == AnimatorStatus.forward
        ? AnimatorStatus.completed
        : status.value == AnimatorStatus.reverse
            ? AnimatorStatus.dismissed
            : status.value;
    final delayed = <String, StyleResolvable<Object>>{};
    for (final delayedChild
        in children.where((e) => e.status.value == AnimatorStatus.delay)) {
      final childValues = delayedChild.values;
      for (final key in childValues.keys)
        delayed.putIfAbsent(key, () => childValues[key]!);
    }
    final finished = <String, StyleResolvable<Object>>{};
    // Walk the children backwards in the finish order
    for (final finishedChild
        in (children.where((e) => e.status.value == finishedState).toList()
          ..sort(_byLargestDuration))) {
      final childValues = finishedChild.values;
      for (final key in childValues.keys)
        finished.putIfAbsent(key, () => childValues[key]!);
    }
    final active = <String, StyleResolvable<Object>>{};
    for (final activeChild
        in children.where((e) => e.status.value == status.value)) {
      final childValues = activeChild.values;
      for (final key in childValues.keys)
        active.putIfAbsent(key, () => childValues[key]!);
    }
    return {
      for (final key
          in active.keys.followedBy(finished.keys).followedBy(delayed.keys))
        key: (active[key] ?? finished[key] ?? delayed[key])!,
    };
  }
}

class EmptyAnimatorSet extends AnimatorSet {
  EmptyAnimatorSet() : super._(const []);

  @override
  Future<void> start({bool forward = true, bool fromStart = false}) async {}

  @override
  ValueListenable<AnimatorStatus> get status =>
      SingleValueListenable(AnimatorStatus.dismissed);

  @override
  Duration get totalDuration => Duration.zero;

  @override
  ValueListenable<void> get changes => SingleValueListenable(null);

  @override
  Map<String, StyleResolvable<Object>> get values => const {};
}

int _sortBySmallestStartDelay(AnimatorWithValues a, AnimatorWithValues b) {
  Duration aDelay = a is ObjectAnimator ? a.startDelay : Duration.zero;
  Duration bDelay = b is ObjectAnimator ? b.startDelay : Duration.zero;
  return aDelay.compareTo(bDelay);
}

int _byLargestDuration(AnimatorWithValues a, AnimatorWithValues b) {
  Duration aDuration = a.totalDuration;
  Duration bDuration = b.totalDuration;
  return aDuration.compareTo(bDuration);
}

class TogetherAnimatorSet extends AnimatorSet {
  final AnimatorWithValues _longest;
  final ValueNotifier<AnimatorStatus> _status;

  TogetherAnimatorSet(List<AnimatorWithValues> children)
      : _longest = children
            .reduce((a, b) => a.totalDuration > b.totalDuration ? a : b),
        _status = ValueNotifier(AnimatorStatus.dismissed),
        super._(children.toList()..sort(_sortBySmallestStartDelay));
  @override
  Future<void> start({bool forward = true, bool fromStart = false}) async {
    _status.value = forward ? AnimatorStatus.forward : AnimatorStatus.reverse;
    Future<void>? fut;
    for (final animation in children) {
      final animFut = animation
          .start(
            forward: forward,
            fromStart: fromStart,
          )
          .catchError(ignore);
      if (animation == _longest) {
        fut = animFut;
      }
    }
    await fut!;
    _status.value =
        forward ? AnimatorStatus.completed : AnimatorStatus.dismissed;
  }

  @override
  ValueListenable<AnimatorStatus> get status => _longest.status;

  @override
  Duration get totalDuration =>
      children.fold(Duration.zero, (acc, b) => acc + b.totalDuration);

  @override
  Listenable get changes =>
      Listenable.merge(children.map((e) => e.changes).toList());

  @override
  Map<String, StyleResolvable<Object>> get values {
    final finishedState = _status.value == AnimatorStatus.forward
        ? AnimatorStatus.completed
        : _status.value == AnimatorStatus.reverse
            ? AnimatorStatus.dismissed
            : _status.value;
    final delayed = <String, StyleResolvable<Object>>{};
    for (final delayedChild
        in children.where((e) => e.status.value == AnimatorStatus.delay)) {
      final childValues = delayedChild.values;
      for (final key in childValues.keys)
        delayed.putIfAbsent(key, () => childValues[key]!);
    }
    final finished = <String, StyleResolvable<Object>>{};
    // Walk the children backwards in the finish order
    for (final finishedChild
        in (children.where((e) => e.status.value == finishedState).toList()
          ..sort(_byLargestDuration))) {
      final childValues = finishedChild.values;
      for (final key in childValues.keys)
        finished.putIfAbsent(key, () => childValues[key]!);
    }
    final active = <String, StyleResolvable<Object>>{};
    for (final activeChild
        in children.where((e) => e.status.value == _status.value)) {
      final childValues = activeChild.values;
      for (final key in childValues.keys)
        active.putIfAbsent(key, () => childValues[key]!);
    }
    return {
      for (final key
          in active.keys.followedBy(finished.keys).followedBy(delayed.keys))
        key: (active[key] ?? finished[key] ?? delayed[key])!,
    };
  }
}
