
import 'package:flutter/foundation.dart';

import '../../../model/style.dart';
import 'animator.dart';

class TargetAndPropertyName {
  final String target;
  final String propertyName;

  const TargetAndPropertyName(this.target, this.propertyName);
}

class TargetAndAnimator {
  final String target;
  final Animator animator;

  TargetAndAnimator(this.target, this.animator);
  String encodePropertyName(String propertyName) => '$target::$propertyName';
  static TargetAndPropertyName decodePropertyName(String targetedPropertyName) {
    final split = targetedPropertyName.split('::');
    assert(split.length == 2);
    return TargetAndPropertyName(split[0], split[1]);
  }
}

class TargetsAnimator extends Animator with DiagnosticableTreeMixin {
  final List<TargetAndAnimator> children;

  TargetsAnimator(this.children);
  @override
  Duration get totalDuration =>
      children.fold<Duration>(Duration.zero, (max, e) {
        final duration = e.animator.totalDuration;
        return max > duration ? max : duration;
      });

  @override
  Iterable<String> get nonUniqueAnimatedAttributes => [];

  @override
  AnimatorStatus status(Duration timeFromStart) {
    if (timeFromStart == Duration.zero) {
      return AnimatorStatus.dismissed;
    }
    if (timeFromStart >= totalDuration) {
      return AnimatorStatus.completed;
    }
    return AnimatorStatus.forward;
  }

  @override
  Map<String, StyleResolvable<Object>> values(Duration timeFromStart) => {
        for (final child in children)
          ...child.animator.values(timeFromStart).map(
              (key, value) => MapEntry(child.encodePropertyName(key), value)),
      };
}
