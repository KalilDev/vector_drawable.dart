import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:vector_drawable/src/model/style.dart';
import 'package:vector_drawable/vector_drawable.dart';
import 'package:value_notifier/value_notifier.dart';

abstract class AnimatorWithValues extends Animator {
  Map<String, StyleResolvable<Object>> get values;
}

abstract class Animator with Diagnosticable {
  Future<void> start({bool forward = true, bool fromStart = false});
  void stop({bool reset = false});
  void reset({bool toFinish = false});
  void dispose();
  ValueListenable<bool> get isCompleted =>
      status.map((status) => status == AnimatorStatus.completed);
  ValueListenable<bool> get isDismissed =>
      status.map((status) => status == AnimatorStatus.dismissed);
  ValueListenable<AnimatorStatus> get status;
  Listenable get changes;
  Duration get totalDuration;
  Iterable<String> get nonUniqueAnimatedAttributes;
}

AnimatorStatus animationStatusToAnimatorStatus(AnimationStatus status) {
  switch (status) {
    case AnimationStatus.dismissed:
      return AnimatorStatus.dismissed;
    case AnimationStatus.forward:
      return AnimatorStatus.forward;
    case AnimationStatus.reverse:
      return AnimatorStatus.reverse;
    case AnimationStatus.completed:
      return AnimatorStatus.completed;
  }
}

enum AnimatorStatus {
  forward,
  reverse,
  dismissed,
  completed,
  delay,
}
