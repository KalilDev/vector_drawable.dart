import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide Animation;
import 'package:flutter/material.dart' as flt show Animation;
import 'package:vector_drawable/src/model/style.dart';
import '../model/vector_drawable.dart';
import 'vector.dart';
import 'package:path_parsing/path_parsing.dart';
import 'package:value_notifier/value_notifier.dart';
import 'package:value_notifier/src/idisposable_change_notifier.dart';
import 'package:value_notifier/src/handle.dart';
import '../model/animated_vector_drawable.dart';
import '../model/animation.dart';

const _kThemableAttributes = {
  // <vector>
  'alpha',
  // <group>
  'rotation',
  'pivotX',
  'pivotY',
  'scaleX',
  'scaleY',
  'translateX',
  'translateY',
  // <path>
  'pathData',
  'fillColor',
  'strokeColor',
  'strokeWidth',
  'strokeAlpha',
  'fillAlpha',
  'trimPathStart',
  'trimPathEnd',
  'trimPathOffset',
// TODO: clip path
};

class _StartOffsetAndThemableAttributes {
  final int startOffset;
  final List<String> themableAttributes;

  _StartOffsetAndThemableAttributes(this.startOffset, this.themableAttributes);
}

extension on Vector {
  Object? getThemeableAttribute(String name) {
    switch (name) {
      case 'alpha':
        return opacity;
    }
  }
}

extension on Path {
  Object? getThemeableAttribute(String name) {
    switch (name) {
      case 'pathData':
        return pathData;
      case 'fillColor':
        return fillColor;
      case 'strokeColor':
        return strokeColor;
      case 'strokeWidth':
        return strokeWidth;
      case 'strokeAlpha':
        return strokeAlpha;
      case 'fillAlpha':
        return fillAlpha;
      case 'trimPathStart':
        return trimPathStart;
      case 'trimPathEnd':
        return trimPathEnd;
      case 'trimPathOffset':
        return trimPathOffset;
    }
  }
}

extension on Group {
  Object? getThemeableAttribute(String name) {
    switch (name) {
      case 'rotation':
        return rotation;
      case 'pivotX':
        return pivotX;
      case 'pivotY':
        return pivotY;
      case 'scaleX':
        return scaleX;
      case 'scaleY':
        return scaleY;
      case 'translateX':
        return translateX;
      case 'translateY':
        return translateY;
    }
  }
}

extension on VectorDrawableNode {
  Object? getThemeableAttribute(String name) {
    if (this is Group) {
      return (this as Group).getThemeableAttribute(name);
    } else if (this is Path) {
      return (this as Path).getThemeableAttribute(name);
    } else if (this is Vector) {
      return (this as Vector).getThemeableAttribute(name);
    }
  }
}

class AnimationStyleResolver extends StyleMapping with DiagnosticableTreeMixin {
  final StyleMapping parentResolver;
  final List<StyleResolvable<Object>> properties;

  AnimationStyleResolver(
    this.parentResolver,
    this.properties,
  );

  static const kNamespace = 'runtime-animation';

  @override
  T? resolve<T>(StyleProperty property) {
    if (property.namespace != kNamespace) {
      return parentResolver.resolve(property);
    }
    final index = int.parse(property.name);
    return properties[index].resolve(parentResolver) as T;
  }

  @override
  bool containsAny(Set<StyleProperty> props) =>
      props.any((e) => e.namespace == kNamespace) ||
      parentResolver.containsAny(props);

  @override
  bool contains(StyleProperty prop) =>
      prop.namespace == kNamespace || parentResolver.contains(prop);

  @override
  List<DiagnosticsNode> debugDescribeChildren() =>
      properties.map((e) => e.toDiagnosticsNode()).toList();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty('parentResolver', parentResolver));
  }
}

class _InterpolatedProperty
    with Diagnosticable
    implements StyleResolvable<Object> {
  final Object a;
  final Object b;
  final double t;

  _InterpolatedProperty(this.a, this.b, this.t);

  static Object resolveAs(
    Object value,
    StyleResolver mapping,
  ) =>
      value is StyleResolvable
          ? resolveAs(value.resolve(mapping), mapping)
          : value;

  static Object lerpValues(
    Object a,
    Object b,
    double t,
    StyleResolver resolver,
  ) {
    a = _InterpolatedProperty.resolveAs(a, resolver);
    b = _InterpolatedProperty.resolveAs(b, resolver);
    if (a is num && b is num) {
      return lerpNum(a, b, t);
    }
    if (a is PathData && b is PathData) {
      return lerpPathData(a, b, t);
    }
    if (a is Color && b is Color) {
      return Color.lerp(a, b, t)!;
    }
    throw TypeError();
  }

  Object resolve(StyleResolver resolver) => lerpValues(a, b, t, resolver);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    if (a == b) {
      properties.add(DiagnosticsProperty('value', a));
      return;
    }
    properties.add(DiagnosticsProperty('a', a));
    properties.add(DiagnosticsProperty('b', b));
    properties.add(PercentProperty('t', t));
  }
}

void _ignore(Object _) {}

class ObjectAnimator extends AnimatorWithValues with Diagnosticable {
  final ObjectAnimation animation;
  final ObjectAnimatorTween tween;
  final AnimationController controller;
  final ValueNotifier<AnimationStatus> _status;

  ObjectAnimator._({
    required this.animation,
    required this.tween,
    required this.controller,
  }) : _status = ValueNotifier(controller.status) {
    controller.addStatusListener(_status.setter);
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
    final start = forward ? 0.0 : 1.0;
    final end = forward ? 1.0 : 0.0;
    if (fromStart) {
      controller.value = start;
    }
    print(animation.repeatCount);
    final repetitionCount =
        animation.repeatCount == -1.0 ? double.infinity : animation.repeatCount;
    for (var animatedCount = 0;
        animatedCount < repetitionCount + 1;
        animatedCount++) {
      await controller.animateTo(end).catchError(_ignore);
      print(repetitionCount);
      print(animatedCount);
      if (animatedCount == repetitionCount) {
        break;
      }
      if (animation.repeatMode == RepeatMode.reverse) {
        await controller.animateTo(start).catchError(_ignore);
      } else {
        controller.value = start;
      }
    }
  }

  @override
  ValueListenable<AnimationStatus> get status => _status;

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
    final duration = controller.duration!;
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
  }

  @override
  Iterable<String> get nonUniqueAnimatedAttributes =>
      tween._holderTweens.map((e) => e.propertyName);
}

abstract class AnimatorWithValues extends Animator {
  Map<String, StyleResolvable<Object>> get values;
}

abstract class Animator with Diagnosticable {
  Future<void> start({bool forward = true, bool fromStart = false});
  void stop({bool reset = false});
  void reset({bool toFinish = false});
  void dispose();
  ValueListenable<bool> get isCompleted =>
      status.map((status) => status == AnimationStatus.completed);
  ValueListenable<bool> get isDismissed =>
      status.map((status) => status == AnimationStatus.dismissed);
  ValueListenable<AnimationStatus> get status;
  Listenable get changes;
  Duration get totalDuration;
  Iterable<String> get nonUniqueAnimatedAttributes;
}

typedef AnimationFactory = Animator Function({required TickerProvider vsync});

class StatusValueListenable extends IDisposableValueNotifier<AnimationStatus> {
  final AnimationController _controller;

  StatusValueListenable(this._controller) : super(_controller.status);

  bool _didListen = false;
  @override
  void addListener(VoidCallback listener) {
    if (!_didListen) {
      _controller.addStatusListener(_onStatus);
      _didListen = true;
    }
    super.addListener(listener);
  }

  void _onStatus(AnimationStatus status) => value = status;

  void dispose() {
    if (_didListen) {
      _controller.removeStatusListener(_onStatus);
    }
    super.dispose();
  }

  @override
  AnimationStatus get value => _didListen ? super.value : _controller.status;
}

class ListenableValueListenable extends IDisposableValueListenable<void>
    with IDisposableMixin {
  final ListenableHandle _base;

  ListenableValueListenable(Listenable base) : _base = ListenableHandle(base);
  @override
  void addListener(VoidCallback listener) => _base.addListener(listener);

  @override
  void removeListener(VoidCallback listener) => _base.removeListener(listener);

  void dispose() {
    _base.dispose();
    super.dispose();
  }

  @override
  void get value => null;
}

extension on Listenable {
  ValueListenable<void> get asValueListenable =>
      ListenableValueListenable(this);
}

class SequentialAnimatorSet extends AnimatorSet {
  final ValueNotifier<AnimatorWithValues> _current;

  SequentialAnimatorSet._(List<AnimatorWithValues> children)
      : _current = ValueNotifier(children.first),
        super._(children);
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
  ValueListenable<AnimationStatus> get status =>
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
  Map<String, StyleResolvable<Object>> get values => {..._current.value.values};
}

class EmptyAnimatorSet extends AnimatorSet {
  EmptyAnimatorSet._() : super._(const []);

  @override
  Future<void> start({bool forward = true, bool fromStart = false}) async {}

  @override
  ValueListenable<AnimationStatus> get status =>
      SingleValueListenable(AnimationStatus.dismissed);

  @override
  Duration get totalDuration => Duration.zero;

  @override
  ValueListenable<void> get changes => SingleValueListenable(null);

  @override
  Map<String, StyleResolvable<Object>> get values => const {};
}

class TogetherAnimatorSet extends AnimatorSet {
  final AnimatorWithValues _longest;

  TogetherAnimatorSet._(List<AnimatorWithValues> children)
      : _longest = children
            .reduce((a, b) => a.totalDuration > b.totalDuration ? a : b),
        super._(children);
  @override
  Future<void> start({bool forward = true, bool fromStart = false}) async {
    Future<void>? fut;
    for (final animation in children) {
      final animFut = animation
          .start(
            forward: forward,
            fromStart: fromStart,
          )
          .catchError(_ignore);
      if (animation == _longest) {
        fut = animFut;
      }
    }
    await fut!;
  }

  @override
  ValueListenable<AnimationStatus> get status => _longest.status;

  @override
  Duration get totalDuration =>
      children.fold(Duration.zero, (acc, b) => acc + b.totalDuration);

  @override
  Listenable get changes => children
      .reduce((a, b) => a.totalDuration > b.totalDuration ? a : b)
      .changes;

  @override
  Map<String, StyleResolvable<Object>> get values => {
        for (final e in children) ...e.values,
      };
}

abstract class AnimatorSet extends AnimatorWithValues
    with DiagnosticableTreeMixin {
  final List<AnimatorWithValues> children;
  AnimatorSet._(this.children);

  List<DiagnosticsNode> debugDescribeChildren() =>
      children.map((e) => e.toDiagnosticsNode()).toList();

  factory AnimatorSet({
    required AnimationSet animation,
    required AnimatorWithValues Function(AnimationNode) childFactory,
  }) {
    if (animation.children.isEmpty) {
      return EmptyAnimatorSet._();
    }
    final children = animation.children.map(childFactory).toList();
    switch (animation.ordering) {
      case AnimationOrdering.together:
        return TogetherAnimatorSet._(children);
      case AnimationOrdering.sequentially:
        return SequentialAnimatorSet._(children);
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

class CoordinateInterpolation implements ValueTween {
  final StyleOr<PathData> pathData;
  final bool isX;
  final Interpolator interpolator;

  CoordinateInterpolation({
    required this.pathData,
    required this.isX,
    required this.interpolator,
  });

  @override
  StyleResolvable<Object> lerp(double t) =>
      _CoordinateInterpolatedValue(pathData, isX, interpolator.transform(t));
}

class _CoordinateInterpolatedValue
    with Diagnosticable
    implements StyleResolvable<Object> {
  final StyleOr<PathData> pathData;
  final bool isX;
  final double t;

  _CoordinateInterpolatedValue(this.pathData, this.isX, this.t);

  @override
  Object? resolve(StyleResolver resolver) {
    final path = pathData.resolve(resolver)!;
    final result = path.evaluateAt(t);
    print(result);
    return isX ? result.dx : result.dy;
  }
}

class ObjectAnimatorTween with DiagnosticableTreeMixin {
  final List<PropertyValueHolderTween> _holderTweens;

  @override
  List<DiagnosticsNode> debugDescribeChildren() =>
      _holderTweens.map((e) => e.toDiagnosticsNode()).toList();

  ObjectAnimatorTween._(this._holderTweens);
  factory ObjectAnimatorTween(
    ObjectAnimation anim,
    Object Function(String) getBaseValue,
  ) {
    if (anim.valueHolders == null) {
      return ObjectAnimatorTween._([
        if (anim.propertyName != null)
          PropertyValueHolderTween(
            anim.propertyName!,
            Interpolation(
              begin: anim.valueFrom ?? getBaseValue(anim.propertyName!),
              end: anim.valueTo!,
              interpolator:
                  anim.interpolator?.resource ?? CurveInterpolator.easeInOut,
            ),
          ),
        if (anim.propertyXName != null)
          PropertyValueHolderTween(
            anim.propertyXName!,
            CoordinateInterpolation(
              pathData: anim.pathData!,
              isX: true,
              interpolator:
                  anim.interpolator?.resource ?? CurveInterpolator.easeInOut,
            ),
          ),
        if (anim.propertyYName != null)
          PropertyValueHolderTween(
            anim.propertyYName!,
            CoordinateInterpolation(
              pathData: anim.pathData!,
              isX: false,
              interpolator:
                  anim.interpolator?.resource ?? CurveInterpolator.easeInOut,
            ),
          ),
      ]);
    }
    return ObjectAnimatorTween._([
      for (final holder in anim.valueHolders!)
        PropertyValueHolderTween.from(
          holder,
          getBaseValue(holder.propertyName),
        ),
    ]);
  }

  Map<String, StyleResolvable<Object>> lerp(double t) =>
      {for (final tween in _holderTweens) tween.propertyName: tween.lerp(t)};
}

class PropertyValueHolderTween extends ValueTween with Diagnosticable {
  final String propertyName;
  final ValueTween _tween;

  PropertyValueHolderTween(this.propertyName, this._tween);
  factory PropertyValueHolderTween.from(
    PropertyValuesHolder holder,
    Object baseValue,
  ) {
    if (holder.keyframes != null) {
      return PropertyValueHolderTween(
        holder.propertyName,
        KeyframeGroup.from(holder.keyframes!, baseValue),
      );
    }
    return PropertyValueHolderTween(
      holder.propertyName,
      Interpolation(
        begin: holder.valueFrom ?? baseValue,
        end: holder.valueTo!,
        interpolator:
            holder.interpolator?.resource ?? CurveInterpolator.easeInOut,
      ),
    );
  }

  @override
  StyleResolvable<Object> lerp(double t) => _tween.lerp(t);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty('propertyName', propertyName));
    properties.add(DiagnosticsProperty('_tween', _tween));
  }
}

class _SingleStyleResolvable<T> extends StyleResolvable<T> with Diagnosticable {
  final T value;

  _SingleStyleResolvable(this.value);

  @override
  T resolve(StyleResolver resolver) => value;
}

abstract class ValueTween {
  StyleResolvable<Object> lerp(double t);
}

class KeyframeGroup implements ValueTween {
  final List<double> keyframeFractions;
  final List<Object> keyframeValues;
  final List<Interpolator> keyframeCurves;

  factory KeyframeGroup.from(
    List<Keyframe> keyframes,
    Object baseValue,
  ) {
    final areUniform = keyframes.every((e) => e.fraction == null);
    List<double> keyframeFractions;
    List<Object> keyframeValues;
    // 2 | 0 1
    // 3 | 0 0.5 1
    // 4 | 0 1/3 2/3 1
    if (areUniform) {
      keyframeFractions = List.generate(keyframes.length,
          (i) => (i * (1 / (keyframes.length - 1))).clamp(0.0, 1.0));
    } else {
      keyframeFractions = List.filled(keyframes.length, 0);
      for (var i = 0; i < keyframes.length; i++) {
        final frame = keyframes[i];
        if (frame.fraction != null) {
          keyframeFractions[i] = frame.fraction!;
          continue;
        }
        if (i == 0) {
          keyframeFractions[0] = 0;
        } else if (i == keyframes.length - 1) {
          keyframeFractions[i] = 1;
        } else {
          final lastIndex = i - 1;
          final prev = keyframeFractions[lastIndex];
          double next = 1;
          int nextCount = 1;
          int n;
          // interpolate between the previous and the nexts
          for (n = i + 1; n < keyframes.length; n++) {
            nextCount++;
            final nextFrame = keyframes[i];
            if (nextFrame.fraction == null) {
              continue;
            }
            next = nextFrame.fraction!;
            break;
          }
          final distancePerFrame = (prev - next) / nextCount;

          // set each previously indeterminate frame to the correct value and
          // skip i to the now defined fraction.
          for (var j = 0; i < n; j++, i++) {
            keyframeFractions[i] = j * distancePerFrame;
          }
        }
      }
    }
    keyframeValues = List.generate(
      keyframes.length,
      (i) =>
          keyframes[i].value ??
          _InterpolatedProperty(
            baseValue,
            keyframes.last.value!,
            keyframeFractions[i],
          ),
    );
    final keyframeCurves = List.generate(
        keyframes.length,
        (i) =>
            keyframes[i].interpolator?.resource ?? CurveInterpolator.easeInOut);
    return KeyframeGroup(keyframeFractions, keyframeValues, keyframeCurves);
  }

  KeyframeGroup(
    this.keyframeFractions,
    this.keyframeValues,
    this.keyframeCurves,
  );

  @override
  StyleResolvable<Object> lerp(
    double t,
  ) {
    for (var i = 0; i < keyframeFractions.length - 1; i++) {
      final frac = keyframeFractions[i];
      final nextFrac = keyframeFractions[i + 1];
      if (t < frac || t > nextFrac) {
        continue;
      }
      final delta = nextFrac - frac;
      final tFromFracToNext = (t - frac) / delta;
      final nextInterpolator = keyframeCurves[i + 1];
      final transformedT = nextInterpolator.transform(tFromFracToNext);
      return _InterpolatedProperty(
        keyframeValues[i],
        keyframeValues[i + 1],
        transformedT,
      );
    }
    return _SingleStyleResolvable(keyframeValues.last);
  }
}

num lerpNum(num a, num b, double t) {
  if (a is double && b is double) {
    return lerpDouble(a, b, t)!;
  }
  if (a is int && b is int) {
    return lerpDouble(a, b, t)!.toInt();
  }
  final toInt = (a is int && t < 0.5) || (b is int && t >= 0.5);
  final lerped = lerpDouble(a, b, t)!;
  if (toInt) {
    return lerped.toInt();
  }
  return lerped;
}

PathSegmentData lerpPathSegment(
  PathSegmentData a,
  PathSegmentData b,
  double t,
) {
  return PathSegmentData()
    ..command = t < 0.5 ? a.command : b.command
    ..targetPoint = a.targetPoint * (1.0 - t) + b.targetPoint
    ..point1 = a.point1 * (1.0 - t) + b.point1
    ..point2 = a.point2 * (1.0 - t) + b.point2
    ..arcSweep = t < 0.5 ? a.arcSweep : b.arcSweep
    ..arcLarge = t < 0.5 ? a.arcLarge : b.arcLarge;
}

PathData lerpPathData(PathData a, PathData b, double t) {
  final aSegments = a.segments;
  final bSegments = b.segments;
  return PathData.fromSegments([
    for (var i = 0; i < aSegments.length; i++)
      lerpPathSegment(aSegments[i], bSegments[i], t)
  ]);
}

class Interpolation implements ValueTween {
  final Object begin;
  final Object end;
  final Interpolator interpolator;
  Interpolation({
    required this.begin,
    required this.end,
    required this.interpolator,
  });

  @override
  StyleResolvable<Object> lerp(double t) =>
      _InterpolatedProperty(begin, end, interpolator.transform(t));
}

class AnimatedVectorWidget extends StatefulWidget {
  const AnimatedVectorWidget({
    Key? key,
    required this.animatedVector,
    this.styleMapping = StyleMapping.empty,
  }) : super(key: key);
  final AnimatedVector animatedVector;
  final StyleMapping styleMapping;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty('animatedVector', animatedVector));
    properties.add(DiagnosticsProperty('styleMapping', styleMapping,
        defaultValue: StyleMapping.empty));
  }

  @override
  AnimatedVectorState createState() => AnimatedVectorState();
}

Map<String, VectorDrawableNode> _namedBaseVectorElements(
    VectorDrawableNode node) {
  if (node is Vector) {
    return node.children.map(_namedBaseVectorElements).fold({
      if (node.name != null) node.name!: node,
      for (final node in node.children.where((child) => child.name != null))
        node.name!: node,
    }, (acc, map) => acc..addAll(map));
  }
  if (node is Group) {
    return node.children.map(_namedBaseVectorElements).fold({
      if (node.name != null) node.name!: node,
      for (final node in node.children.where((child) => child.name != null))
        node.name!: node,
    }, (acc, map) => acc..addAll(map));
  }
  // TODO: clip path
  return {
    if (node.name != null) node.name!: node,
  };
}

class AnimatedVectorState extends State<AnimatedVectorWidget>
    with TickerProviderStateMixin
    implements Animator {
  AnimatedVector? _currentVector;
  late Vector base;
  late Vector animatable;
  final Map<VectorDrawableNode, Set<ObjectAnimator>> elementAnimators = {};
  late Map<String, VectorDrawableNode> namedBaseElements;
  // owns all other animators
  late AnimatorSet root;
  final Map<VectorDrawableNode, _StartOffsetAndThemableAttributes>
      _nodePropsMap = {};
  int startOffset = 0;
  int propsLength = 0;
  void _removeStuffFromOldVector() {
    assert(_currentVector != null);
    _nodePropsMap.clear();
    startOffset = 0;
    propsLength = 0;
    elementAnimators.clear();
    root.dispose();
    _currentVector = null;
  }

  void _createStuffForVector(AnimatedVector vector) {
    assert(_currentVector == null);
    assert(elementAnimators.isEmpty);
    assert(_nodePropsMap.isEmpty);
    assert(startOffset == 0);
    assert(propsLength == 0);
    base = vector.drawable.resource!.body;
    root = widget.animatedVector.children.isEmpty
        ? EmptyAnimatorSet._()
        : _createTargetAnimators(_namedBaseVectorElements(base));
    animatable = _buildAnimatableVector();
    _currentVector = vector;
  }

  Animator? _createTargetAnimator(
      Map<String, VectorDrawableNode> namedBaseElements, Target target) {
    if (!namedBaseElements.containsKey(target.name)) {
      return null;
    }
    final targetElement = namedBaseElements[target.name]!;
    final anim = target.animation.resource!;
    AnimatorWithValues buildAnimator(AnimationNode node) {
      if (node is AnimationSet) {
        return AnimatorSet(animation: node, childFactory: buildAnimator);
      }
      if (node is ObjectAnimation) {
        final animator = ObjectAnimator.from(
          target: targetElement,
          animation: node,
          vsync: this,
        );
        final targetAnimators =
            elementAnimators.putIfAbsent(targetElement, () => {});
        targetAnimators.add(animator);
        return animator;
      }
      throw UnimplementedError();
    }

    return buildAnimator(anim.body);
  }

  AnimatorSet _createTargetAnimators(
          Map<String, VectorDrawableNode> namedBaseElements) =>
      TogetherAnimatorSet._(widget.animatedVector.children
          .map((target) => _createTargetAnimator(namedBaseElements, target))
          .where((e) => e != null)
          .toList()
          .cast());

  void initState() {
    super.initState();
    _createStuffForVector(widget.animatedVector);
  }

  @override
  void didUpdateWidget(AnimatedVectorWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animatedVector != widget.animatedVector) {
      _removeStuffFromOldVector();
      _createStuffForVector(widget.animatedVector);
    }
  }

  void dispose() {
    root.dispose();
    super.dispose();
  }

  List<String> _propertiesFromNode(
    VectorDrawableNode node,
  ) {
    if (!elementAnimators.containsKey(node)) {
      return const [];
    }
    final animators = elementAnimators[node]!;
    return animators
        .expand((e) => e.nonUniqueAnimatedAttributes)
        .toSet()
        .toList();
  }

  Iterable<StyleResolvable<Object>> _dynamicPropsFrom(
    VectorDrawableNode node,
    Set<ObjectAnimator> animators,
    List<String> themableAttrs,
  ) {
    final props = {
      for (final animator in animators) ...animator.values,
    };
    return themableAttrs.map(
      (prop) =>
          props[prop] ??
          _SingleStyleResolvable(node.getThemeableAttribute(prop)!),
    );
  }

  VectorDrawableNode buildAnimatableTargetFromProperties(
    List<String> animatableProperties,
    VectorDrawableNode target,
    VectorDrawableNode Function(
      VectorDrawableNode,
    )
        buildChild,
  ) {
    final targetStartOffset = startOffset;
    if (animatableProperties.isNotEmpty) {
      _nodePropsMap[target] = _StartOffsetAndThemableAttributes(
          targetStartOffset, animatableProperties);
    }
    startOffset += animatableProperties.length;
    propsLength += animatableProperties.length;

    StyleOr<T>? prop<T>(StyleOr<T>? otherwise, String name) {
      final i = animatableProperties.indexOf(name);
      if (i == -1) {
        return otherwise;
      }
      return StyleOr.style(
        StyleProperty(AnimationStyleResolver.kNamespace,
            (i + targetStartOffset).toString()),
      );
    }

    final t = target;
    if (t is Vector) {
      return Vector(
        name: t.name,
        width: t.width,
        height: t.height,
        viewportWidth: t.viewportWidth,
        viewportHeight: t.viewportHeight,
        tint: t.tint,
        tintMode: t.tintMode,
        autoMirrored: t.autoMirrored,
        opacity: prop(t.opacity, 'alpha')!,
        children: t.children.map(buildChild).toList().cast(),
      );
    } else if (t is Group) {
      return Group(
        name: t.name,
        rotation: prop(t.rotation, 'rotation'),
        pivotX: prop(t.pivotX, 'pivotX'),
        pivotY: prop(
          t.pivotY,
          'pivotY',
        ),
        scaleX: prop(
          t.scaleX,
          'scaleX',
        ),
        scaleY: prop(
          t.scaleY,
          'scaleY',
        ),
        translateX: prop(t.translateX, 'translateX'),
        translateY: prop(t.translateY, 'translateY'),
        children: t.children.map(buildChild).toList().cast(),
      );
    } else if (t is Path) {
      return Path(
        name: t.name,
        pathData: prop(t.pathData, 'pathData')!,
        fillColor: prop(t.fillColor, 'fillColor'),
        strokeColor: prop(t.strokeColor, 'strokeColor'),
        strokeWidth: prop(t.strokeWidth, 'strokeWidth')!,
        strokeAlpha: prop(t.strokeAlpha, 'strokeAlpha')!,
        fillAlpha: prop(t.fillAlpha, 'fillAlpha')!,
        trimPathStart: prop(t.trimPathStart, 'trimPathStart')!,
        trimPathEnd: prop(t.trimPathEnd, 'trimPathEnd')!,
        trimPathOffset: prop(t.trimPathOffset, 'trimPathOffset')!,
        strokeLineCap: t.strokeLineCap,
        strokeLineJoin: t.strokeLineJoin,
        strokeMiterLimit: t.strokeMiterLimit,
        fillType: t.fillType,
      );
    } else {
      throw UnimplementedError();
    }
  }

  VectorDrawableNode _buildNodeWithProperties(
    VectorDrawableNode node,
  ) {
    return buildAnimatableTargetFromProperties(
      _propertiesFromNode(node),
      node,
      _buildNodeWithProperties,
    );
  }

  Vector _buildAnimatableVector() {
    return _buildNodeWithProperties(base) as Vector;
  }

  AnimationStyleResolver _buildDynamicStyleResolver(StyleMapping mapping) {
    final props = List<StyleResolvable<Object>?>.filled(propsLength, null);
    for (final e in elementAnimators.entries) {
      final animationInfo = _nodePropsMap[e.key];
      if (animationInfo == null) {
        continue;
      }
      final elementProps =
          _dynamicPropsFrom(e.key, e.value, animationInfo.themableAttributes);
      var i = 0;
      for (final prop in elementProps) {
        props[i + animationInfo.startOffset] = prop;
        i++;
      }
    }
    return AnimationStyleResolver(
      mapping,
      props.cast(),
    );
  }

  Widget _buildVectorWidget(BuildContext context, StyleResolver resolver) {
    return RawVectorWidget(
      vector: animatable,
      styleMapping: resolver,
    );
  }

  @override
  Widget build(BuildContext context) {
    final styleMapping = widget.styleMapping
        .mergeWith(ColorSchemeStyleMapping(Theme.of(context).colorScheme));
    return AnimatedBuilder(
      animation: changes,
      builder: (context, _) => _buildVectorWidget(
        context,
        _buildDynamicStyleResolver(styleMapping),
      ),
    );
  }

  @override
  Listenable get changes => root.changes;

  @override
  ValueListenable<bool> get isCompleted => root.isCompleted;

  @override
  ValueListenable<bool> get isDismissed => root.isDismissed;

  @override
  Future<void> start({bool forward = true, bool fromStart = false}) =>
      root.start(
        forward: forward,
        fromStart: fromStart,
      );

  @override
  void reset({bool toFinish = false}) => root.reset(toFinish: toFinish);

  @override
  ValueListenable<AnimationStatus> get status => root.status;

  @override
  void stop({bool reset = false}) => root.stop(reset: reset);

  @override
  Duration get totalDuration => root.totalDuration;

  @override
  Iterable<String> get nonUniqueAnimatedAttributes => [];
}
