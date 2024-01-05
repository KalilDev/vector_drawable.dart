import 'package:animated_vector_drawable/src/widget/src/attributes.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:animated_vector_drawable_core/model.dart';
import '../interpolation.dart';
import 'animator.dart';

class ObjectAnimator extends Animator with Diagnosticable {
  final ObjectAnimation animation;
  final ObjectAnimatorTween tween;
  final Duration duration;
  final Duration startDelay;

  ObjectAnimator._({
    required this.animation,
    required this.tween,
    required this.duration,
    required this.startDelay,
  });

  factory ObjectAnimator.from({
    required VectorDrawableNode target,
    required ObjectAnimation animation,
  }) {
    return ObjectAnimator._(
      animation: animation,
      tween: ObjectAnimatorTween(
        animation,
        (name) => target.getThemeableAttribute(name)!,
      ),
      duration: Duration(milliseconds: animation.duration),
      startDelay: Duration(milliseconds: animation.startOffset),
    );
  }

  @override
  Map<String, StyleResolvable<Object>> values(Duration timeFromStart) =>
      tween.lerp(t(timeFromStart));

  @override
  AnimatorStatus status(Duration timeFromStart) {
    if (timeFromStart > totalDuration) {
      return AnimatorStatus.completed;
    }
    if (timeFromStart == Duration.zero) {
      return AnimatorStatus.dismissed;
    }
    if (timeFromStart <= startDelay) {
      return AnimatorStatus.delay;
    }
    timeFromStart -= startDelay;
    if (animation.repeatMode == RepeatMode.reverse) {
      // each repeat takes 2 cycles.
      final cycleDuration = 2 * duration.inMicroseconds;
      final t = (timeFromStart.inMicroseconds % cycleDuration) / cycleDuration;
      if (t > 0.5) {
        return AnimatorStatus.reverse;
      }
    }
    return AnimatorStatus.forward;
  }

  @override
  Duration get totalDuration {
    if (animation.repeatCount == -1) {
      return const Duration(days: 365);
    }
    final repeatCycles = animation.repeatMode == RepeatMode.reverse ? 2 : 1;
    return duration * (animation.repeatCount * repeatCycles + 1) + startDelay;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty('animation', animation));
    properties.add(DiagnosticsProperty('tween', tween));
    properties.add(DiagnosticsProperty('duration', duration));
    properties.add(DiagnosticsProperty('startDelay', startDelay));
  }

  @override
  Iterable<String> get nonUniqueAnimatedAttributes =>
      tween.nonUniqueAnimatedAttributes;

  double t(Duration timeFromStart) {
    if (timeFromStart > totalDuration) {
      return 1.0;
    }
    timeFromStart -= startDelay;
    double t;
    if (animation.repeatCount == 0) {
      t = timeFromStart.inMicroseconds / duration.inMicroseconds;
    } else if (animation.repeatMode == RepeatMode.reverse) {
      // each repeat takes 2 cycles.
      final cycleDuration = 2 * duration.inMicroseconds;
      t = (timeFromStart.inMicroseconds % cycleDuration) / cycleDuration;
      // we are going from 0 to 1 in 2 cycles, but we want to go from 0 to 1 to
      // 0 in 2 cycles, do do it.
      t = (t * 2) - (t > 0.5 ? 1.0 : 0.0);
    } else {
      // each repeat takes one cycle.
      t = (timeFromStart.inMicroseconds % duration.inMicroseconds) /
          duration.inMicroseconds;
    }

    return t.clamp(0.0, 1.0);
  }
}
