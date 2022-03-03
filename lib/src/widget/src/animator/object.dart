import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:vector_drawable/src/model/animation.dart';
import 'package:vector_drawable/src/model/style.dart';
import 'package:vector_drawable/src/model/vector_drawable.dart';
import 'package:vector_drawable/src/widget/src/animator/animator.dart';
import 'package:vector_drawable/src/widget/src/attributes.dart';
import 'package:value_notifier/value_notifier.dart';
import '../interpolation.dart';
import '../util.dart';

class ObjectAnimator extends AnimatorWithValues with Diagnosticable {
  final ObjectAnimation animation;
  final ObjectAnimatorTween tween;
  final AnimationController controller;
  final Duration startDelay;
  final ValueNotifier<AnimatorStatus> _status;

  ObjectAnimator._({
    required this.startDelay,
    required this.animation,
    required this.tween,
    required this.controller,
  }) : _status =
            ValueNotifier(animationStatusToAnimatorStatus(controller.status)) {
    controller.addStatusListener(_onControllerStatus);
  }
  void _onControllerStatus(AnimationStatus status) {
    _status.value = animationStatusToAnimatorStatus(status);
  }

  factory ObjectAnimator.from({
    required VectorDrawableNode target,
    required ObjectAnimation animation,
    required TickerProvider vsync,
  }) {
    final controller = AnimationController(
      vsync: vsync,
      duration: Duration(milliseconds: animation.duration),
    );
    return ObjectAnimator._(
      startDelay: Duration(milliseconds: animation.startOffset),
      animation: animation,
      controller: controller,
      tween: ObjectAnimatorTween(
        animation,
        (name) => target.getThemeableAttribute(name)!,
      ),
    );
  }

  Map<String, StyleResolvable<Object>> get values =>
      tween.lerp(controller.value);

  void dispose() {
    _status.dispose();
    controller.dispose();
  }

  @override
  void reset({bool toFinish = false}) {
    controller.reset();
    if (toFinish) {
      controller.value = 1;
    }
  }

  @override
  Future<void> start({bool forward = true, bool fromStart = false}) async {
    if (startDelay != Duration.zero) {
      _status.value = AnimatorStatus.delay;
      // TODO: cancel?
      await Future.delayed(startDelay);
    }
    final start = forward ? 0.0 : 1.0;
    final end = forward ? 1.0 : 0.0;
    if (fromStart) {
      controller.value = start;
    }
    final repetitionCount =
        animation.repeatCount == -1.0 ? double.infinity : animation.repeatCount;
    for (var animatedCount = 0;
        animatedCount < repetitionCount + 1;
        animatedCount++) {
      await controller.animateTo(end).catchError(ignore);
      if (animatedCount == repetitionCount) {
        break;
      }
      if (animation.repeatMode == RepeatMode.reverse) {
        await controller.animateTo(start).catchError(ignore);
      } else {
        controller.value = start;
      }
    }
  }

  @override
  ValueListenable<AnimatorStatus> get status => _status.view();

  @override
  void stop({bool reset = false}) {
    controller.stop(canceled: true);
    if (reset) {
      this.reset();
    }
  }

  @override
  Duration get totalDuration {
    if (animation.repeatCount == -1) {
      return const Duration(days: 365);
    }
    final duration = startDelay + controller.duration!;
    final repeatCycles = animation.repeatMode == RepeatMode.reverse ? 2 : 1;
    return duration * (animation.repeatCount * repeatCycles + 1);
  }

  @override
  ValueListenable<void> get changes => controller.view.view();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty('animation', animation));
    properties.add(DiagnosticsProperty('tween', tween));
    properties.add(DiagnosticsProperty('controller', controller));
    properties.add(DiagnosticsProperty('status', _status.value));
    properties.add(DiagnosticsProperty('startDelay', startDelay));
  }

  @override
  Iterable<String> get nonUniqueAnimatedAttributes =>
      tween.nonUniqueAnimatedAttributes;
}
