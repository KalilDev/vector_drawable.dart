import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide Animation;
import 'package:flutter/material.dart' as flt show Animation;
import '../model/vector_drawable.dart';
import 'vector.dart';
import 'package:path_parsing/path_parsing.dart';
import 'package:value_notifier/value_notifier.dart';

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

class _InterpolatedProperty {
  final Object a;
  final Object b;
  final double t;

  _InterpolatedProperty(this.a, this.b, this.t);

  static Object resolveAs(
    Object value,
    StyleMapping mapping,
  ) =>
      value is _InterpolatedProperty ? value.resolve(mapping) : value;
  Object resolve(StyleMapping mapping) => lerpValues(a, b, t, mapping);
}

class ObjectAnimator extends Animator with Diagnosticable {
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

  Map<String, Object> values(StyleMapping styleMapping) =>
      tween.lerp(controller.value, styleMapping);

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

  static void _ignore(Object _) {}

  @override
  Future<void> start({bool forward = true, bool fromStart = false}) async {
    final start = forward ? 0.0 : 1.0;
    final end = forward ? 1.0 : 0.0;
    if (fromStart) {
      controller.value = start;
    }
    final repetitionCount =
        animation.repeatCount == -1 ? double.infinity : animation.repeatCount;
    for (var animatedCount = 0;
        animatedCount < repetitionCount + 1;
        animatedCount++) {
      await controller.animateTo(end).catchError(_ignore);
      if (animatedCount == repetitionCount) {
        break;
      }
      if (animation.repeatMode == RepeatMode.reverse) {
        await controller.animateTo(start).catchError(_ignore);
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
  ValueListenable<void> get changes;
  Duration get totalDuration;
}

typedef AnimationFactory = Animator Function({required TickerProvider vsync});

class SequentialAnimatorSet extends AnimatorSet {
  final ProxyValueListenable<AnimationStatus> _status;

  SequentialAnimatorSet._(List<Animator> children)
      : _status = ProxyValueListenable(
          children.first.status,
        ),
        super._(children);
  @override
  void reset({bool toFinish = false}) {
    super.reset(toFinish: toFinish);
    _status.base = toFinish ? children.last.status : children.first.status;
  }

  @override
  Future<void> start({bool forward = true, bool fromStart = false}) async {
    if (fromStart) {
      reset(toFinish: !forward);
    }
    for (final animation in forward ? children : children.reversed) {
      _status.base = animation.status;
      try {
        await animation.start(forward: forward, fromStart: fromStart);
      } on TickerCanceled {
        break;
      }
    }
  }

  @override
  ValueListenable<AnimationStatus> get status => _status.view();

  @override
  Duration get totalDuration =>
      children.fold(Duration.zero, (acc, b) => acc + b.totalDuration);

  @override
  ValueListenable<void> get changes => children.fold(
      SingleValueListenable(null), (acc, e) => acc.bind((_) => e.changes));
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
}

class TogetherAnimatorSet extends AnimatorSet {
  final ValueListenable<AnimationStatus> _status;

  TogetherAnimatorSet._(List<Animator> children)
      : _status = children
            .reduce((a, b) => a.totalDuration > b.totalDuration ? a : b)
            .status,
        super._(children);
  @override
  Future<void> start({bool forward = true, bool fromStart = false}) async {
    for (final animation in children) {
      animation.start(forward: forward, fromStart: fromStart).ignore();
    }
  }

  @override
  ValueListenable<AnimationStatus> get status => _status.view();

  @override
  Duration get totalDuration =>
      children.fold(Duration.zero, (acc, b) => acc + b.totalDuration);

  @override
  ValueListenable<void> get changes => children
      .reduce((a, b) => a.totalDuration > b.totalDuration ? a : b)
      .changes;
}

VectorDrawableNode buildTargetFromProperties(
  StyleMapping styleMapping,
  Map<String, Object> targetProperties,
  VectorDrawableNode target,
  VectorDrawableNode Function(
    VectorDrawableNode,
    StyleMapping,
  )
      buildChild,
) {
  T prop<T>(T otherwise, String name) {
    assert(_kThemableAttributes.contains(name));
    if (targetProperties.containsKey(name)) {
      return targetProperties[name] as T;
    }
    return otherwise;
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
      opacity: prop(t.opacity, 'alpha'),
      children: t.children
          .map((child) => buildChild(child, styleMapping))
          .toList()
          .cast(),
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
      children: t.children
          .map((child) => buildChild(child, styleMapping))
          .toList()
          .cast(),
    );
  } else if (t is Path) {
    return Path(
      name: t.name,
      pathData: prop(t.pathData, 'pathData'),
      fillColor: prop(t.fillColor, 'fillColor'),
      strokeColor: prop(t.strokeColor, 'strokeColor'),
      strokeWidth: prop(t.strokeWidth, 'strokeWidth'),
      strokeAlpha: prop(t.strokeAlpha, 'strokeAlpha'),
      fillAlpha: prop(t.fillAlpha, 'fillAlpha'),
      trimPathStart: prop(t.trimPathStart, 'trimPathStart'),
      trimPathEnd: prop(t.trimPathEnd, 'trimPathEnd'),
      trimPathOffset: prop(t.trimPathOffset, 'trimPathOffset'),
      strokeLineCap: t.strokeLineCap,
      strokeLineJoin: t.strokeLineJoin,
      strokeMiterLimit: t.strokeMiterLimit,
      fillType: t.fillType,
    );
  } else {
    throw UnimplementedError();
  }
}

abstract class AnimatorSet extends Animator with DiagnosticableTreeMixin {
  final List<Animator> children;
  AnimatorSet._(this.children);

  List<DiagnosticsNode> debugDescribeChildren() =>
      children.map((e) => e.toDiagnosticsNode()).toList();

  factory AnimatorSet({
    required AnimationSet animation,
    required Animator Function(AnimationNode) childFactory,
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
}

class ObjectAnimatorTween {
  final List<PropertyValueHolderTween> _holderTweens;

  ObjectAnimatorTween._(this._holderTweens);
  factory ObjectAnimatorTween(
    ObjectAnimation anim,
    Object Function(String) getBaseValue,
  ) {
    if (anim.valueHolders == null) {
      return ObjectAnimatorTween._([
        PropertyValueHolderTween(
          anim.propertyName!,
          Interpolation(
              begin: anim.valueFrom ?? getBaseValue(anim.propertyName!),
              end: anim.valueTo!),
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

  Map<String, Object> lerp(double t, StyleMapping styleMapping) => {
        for (final tween in _holderTweens)
          tween.propertyName: tween.lerp(t, styleMapping)
      };
}

class PropertyValueHolderTween extends ValueTween {
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
      Interpolation(begin: holder.valueFrom ?? baseValue, end: holder.valueTo!),
    );
  }

  @override
  Object lerp(double t, StyleMapping s) => _tween.lerp(t, s);
}

abstract class ValueTween {
  Object lerp(double t, StyleMapping s);
}

class KeyframeGroup implements ValueTween {
  final List<double> keyframeFractions;
  final List<Object> keyframeValues;
  final List<Curve> keyframeCurves;

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
    final keyframeCurves = List.generate(keyframes.length,
        (i) => keyframes[i].interpolator?.resource?.curve ?? Curves.easeInOut);
    return KeyframeGroup(keyframeFractions, keyframeValues, keyframeCurves);
  }

  KeyframeGroup(
    this.keyframeFractions,
    this.keyframeValues,
    this.keyframeCurves,
  );

  @override
  Object lerp(
    double t,
    StyleMapping mapping,
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
      return lerpValues(
        keyframeValues[i],
        keyframeValues[i + 1],
        transformedT,
        mapping,
      );
    }
    return keyframeValues.last;
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

Object lerpValues(
  Object a,
  Object b,
  double t,
  StyleMapping mapping,
) {
  a = _InterpolatedProperty.resolveAs(a, mapping);
  b = _InterpolatedProperty.resolveAs(b, mapping);
  if (a is num && b is num) {
    return lerpNum(a, b, t);
  }
  if (a is PathData && b is PathData) {
    return lerpPathData(a, b, t);
  }
  if (a is ColorOrStyleColor && b is ColorOrStyleColor) {
    final colorA = mapping.resolve(a);
    final colorB = mapping.resolve(b);
    return Color.lerp(colorA, colorB, t)!;
  }
  throw TypeError();
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
  final Curve curve;
  Interpolation({
    required this.begin,
    required this.end,
    this.curve = Curves.linear,
  });

  @override
  Object lerp(double t, StyleMapping s) => lerpValues(begin, end, t, s);
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
  late final Vector base = widget.animatedVector.drawable.resource!.body;
  final Map<VectorDrawableNode, Set<ObjectAnimator>> elementAnimators = {};
  late final Map<String, VectorDrawableNode> namedBaseElements =
      _namedBaseVectorElements(base);
  // owns all other animators
  late final AnimatorSet root;
  Animator? _createTargetAnimator(Target target) {
    if (!namedBaseElements.containsKey(target.name)) {
      return null;
    }
    final targetElement = namedBaseElements[target.name]!;
    final anim = target.animation.resource!;
    Animator buildAnimator(AnimationNode node) {
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

  AnimatorSet _createTargetAnimators() =>
      TogetherAnimatorSet._(widget.animatedVector.children
          .map(_createTargetAnimator)
          .where((e) => e != null)
          .toList()
          .cast());

  void initState() {
    super.initState();
    root = widget.animatedVector.children.isEmpty
        ? EmptyAnimatorSet._()
        : _createTargetAnimators();
  }

  void dispose() {
    root.dispose();
    super.dispose();
  }

  Map<String, Object> _propertiesFromNode(
    VectorDrawableNode node,
    StyleMapping styleMapping,
  ) {
    if (!elementAnimators.containsKey(node)) {
      return const {};
    }
    final animators = elementAnimators[node]!;
    return animators.fold(
        {},
        (acc, e) => e.status.value == root.status.value
            ? (acc..addAll(e.values(styleMapping)))
            : acc);
  }

  VectorDrawableNode _buildNodeWithProperties(
    VectorDrawableNode node,
    StyleMapping styleMapping,
  ) {
    return buildTargetFromProperties(
      styleMapping,
      _propertiesFromNode(node, styleMapping),
      node,
      _buildNodeWithProperties,
    );
  }

  Vector _buildVector(StyleMapping styleMapping) =>
      _buildNodeWithProperties(base, styleMapping) as Vector;

  Widget _buildVectorWidget(BuildContext context, Vector vector) {
    return VectorWidget(
      vector: vector,
    );
  }

  @override
  Widget build(BuildContext context) {
    final styleMapping = widget.styleMapping
        .mergeWith(ColorSchemeStyleMapping(Theme.of(context).colorScheme));
    return changes.map((_) => _buildVector(styleMapping)).build(
        builder: (context, vector, __) => _buildVectorWidget(context, vector));
  }

  @override
  ValueListenable<void> get changes => root.changes;

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
}
