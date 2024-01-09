import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:vector_drawable_core/vector_drawable_core.dart';
import 'package:value_listenables/value_listenables.dart';

abstract class Animator with Diagnosticable {
  Map<String, StyleResolvable<Object>> values(Duration timeFromStart);
  AnimatorStatus status(Duration timeFromStart);
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

class TickerView extends IDisposableBase {
  final ValueListenable<Duration> _tickerTime;
  ValueListenable<Duration> get tickerTime => _tickerTime.view();

  TickerView(this._tickerTime);

  @override
  void dispose() {
    IDisposable.disposeObj(_tickerTime);
    super.dispose();
  }
}

abstract class ICreateTickerViews implements IDisposable {
  TickerView createView();
}

class Animated<T extends Animator> extends IDisposableBase {
  T? _animator;
  Animated(this._animator, ICreateTickerViews vsync)
      : _ticker = vsync.createView();
  TickerView? _ticker;

  @override
  void dispose() {
    _ticker!.dispose();
    _animator = null;
    _ticker = null;
    super.dispose();
  }

  ValueListenable<Map<String, StyleResolvable<Object>>> get values =>
      _ticker!.tickerTime.map(_animator!.values);
  ValueListenable<AnimatorStatus> get status =>
      _ticker!.tickerTime.map(_animator!.status);
  Duration get totalDuration => _animator!.totalDuration;
  Iterable<String> get nonUniqueAnimatedAttributes =>
      _animator!.nonUniqueAnimatedAttributes;
}

class AnimatorController extends IDisposableBase implements ICreateTickerViews {
  final AnimationController _controller;
  final ValueNotifier<Duration?> _totalDuration = ValueNotifier(null);
  final ValueNotifier<Animated?> _animated = ValueNotifier(null);

  AnimatorController({required TickerProvider vsync})
      : _controller = AnimationController(vsync: vsync);

  /// Animate an [Animator]. BEWARE: Only an single valid [Animated] can live
  /// off an [AnimatorController] at any given time
  Animated<T> animate<T extends Animator>(T animator) {
    _totalDuration.value = animator.totalDuration;
    _controller.duration = animator.totalDuration;

    return _animated.value = Animated<T>(animator, this);
  }

  void start({bool fromStart = true}) =>
      _controller.forward(from: fromStart ? 0.0 : null);

  void stop({bool reset = false}) {
    _controller.stop();
    if (reset) {
      this.reset();
    }
  }

  void reset() => _controller.value = 0;

  ValueListenable<Duration> get _timeFromStart =>
      _totalDuration.view().bind((totalDuration) => _controller.view
          .view()
          .map((t) => (totalDuration ?? Duration.zero) * t));

  ValueListenable<Map<String, StyleResolvable<Object>>> get values => _animated
      .view()
      .bind((animated) => animated?.values ?? SingleValueListenable(const {}));

  ValueListenable<AnimatorStatus> get status =>
      _animated.view().bind((animated) =>
          animated?.status ?? SingleValueListenable(AnimatorStatus.dismissed));

  ValueListenable<Duration> get totalDuration =>
      _totalDuration.view().withDefault(Duration.zero);

  ValueListenable<Iterable<String>> get nonUniqueAnimatedAttributes => _animated
      .view()
      .map((animated) => animated?.nonUniqueAnimatedAttributes ?? []);

  @override
  TickerView createView() => TickerView(_timeFromStart);

  @override
  void dispose() {
    _animated.dispose();
    _controller.dispose();
    super.dispose();
  }
}
