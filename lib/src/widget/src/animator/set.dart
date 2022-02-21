import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:vector_drawable/src/model/style.dart';
import 'package:value_notifier/value_notifier.dart';
import 'package:vector_drawable/src/widget/src/util.dart';
import 'package:vector_drawable/vector_drawable.dart';

import 'animator.dart';

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
      final startTime = DateTime.now();
      print('$startTime Starting $animation');
      try {
        await animation.start(forward: forward, fromStart: fromStart);
        final finishTime = DateTime.now();
        print(
            '$finishTime Finished $animation, took ${finishTime.difference(startTime).inMilliseconds}ms');
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
    final current = _current.value;
    bool didPassCurrent = false;
    final result = <String, StyleResolvable<Object>>{};
    for (final child in children) {
      if (didPassCurrent || child.status.value == AnimatorStatus.delay) {
        // Only add if the value was not present
        final vs = child.values;
        for (final key in vs.keys) {
          if (result.containsKey(key)) {
            continue;
          }
          result[key] = vs[key]!;
        }
      } else {
        // Add everything
        final vs = child.values;
        result.addAll(vs);
      }
      if (child == current) {
        didPassCurrent = true;
      }
    }
    return result;
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

class TogetherAnimatorSet extends AnimatorSet {
  final AnimatorWithValues _longest;
  final ValueNotifier<AnimatorStatus> _status;

  TogetherAnimatorSet(List<AnimatorWithValues> children)
      : _longest = children
            .reduce((a, b) => a.totalDuration > b.totalDuration ? a : b),
        _status = ValueNotifier(AnimatorStatus.dismissed),
        super._(children);
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
    final result = <String, StyleResolvable<Object>>{};
    for (final child
        in children.where((child) => child.status.value == _status.value)) {
      // Add everything
      final vs = child.values;
      result.addAll(vs);
    }

    /*for (final child
        in children.where((child) => child.status.value != _status.value)) {
      // Only add if the value was not present
      final vs = child.values;
      for (final key in vs.keys) {
        if (result.containsKey(key)) {
          continue;
        }
        result[key] = vs[key]!;
      }
    }*/
    return result;
  }
}
