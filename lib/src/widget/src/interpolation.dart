import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide Animation, ClipPath;
import 'package:flutter/material.dart' as flt show Animation, ClipPath;
import 'package:flutter/scheduler.dart';
import 'package:vector_drawable/src/model/diagnostics.dart';
import 'package:vector_drawable/src/model/style.dart';
import 'package:path_parsing/path_parsing.dart';
import 'package:value_listenables/value_listenables.dart';
import 'package:value_listenables/src/idisposable_change_notifier.dart';
import 'package:value_listenables/src/handle.dart';
import 'package:vector_drawable/src/path_utils.dart';

import '../../model/animation.dart';
import '../../model/path.dart';
import '../../model/resource.dart';
import '../../model/vector_drawable.dart';

class CurveInterpolator extends Interpolator {
  final Curve curve;
  CurveInterpolator({
    required this.curve,
    ResourceReference? source,
  }) : super(source);

  static final linear = CurveInterpolator(
      curve: Curves.linear,
      source: ResourceReference('anim', 'linear', 'android'));
  static final easeInOut = CurveInterpolator(
      curve: Curves.easeInOut,
      source: ResourceReference('anim', 'accelerate_interpolator', 'android'));
  static final accelerateCubic = CurveInterpolator(
      curve: Curves.easeInCubic,
      source: ResourceReference('interpolator', 'accelerate_cubic', 'android'));
  static final decelerateCubic = CurveInterpolator(
      curve: Curves.easeOutCubic,
      source: ResourceReference('interpolator', 'decelerate_cubic', 'android'));

  @override
  double transform(double t) => curve.transform(t);
}

class SingleStyleResolvable<T> extends StyleResolvable<T>
    with VectorDiagnosticableMixin {
  final T value;

  SingleStyleResolvable(this.value);

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
    return SingleStyleResolvable(keyframeValues.last);
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

Object resolveStyledAs(
  Object value,
  StyleResolver mapping,
) =>
    value is StyleResolvable
        ? resolveStyledAs(value.resolve(mapping), mapping)
        : value;

class _InterpolatedProperty
    with VectorDiagnosticableMixin
    implements StyleResolvable<Object> {
  final Object a;
  final Object b;
  final double t;

  _InterpolatedProperty(this.a, this.b, this.t);

  static Object lerpValues(
    Object a,
    Object b,
    double t,
    StyleResolver resolver,
  ) {
    a = resolveStyledAs(a, resolver);
    b = resolveStyledAs(b, resolver);
    if (a is num && b is num) {
      return lerpNum(a, b, t);
    }
    if (a is PathData && b is PathData) {
      return PathData.lerp(a, b, t);
    }
    if (a is Color && b is Color) {
      return Color.lerp(a, b, t)!;
    }
    throw TypeError();
  }

  Object resolve(StyleResolver resolver) => lerpValues(a, b, t, resolver);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    //super.debugFillProperties(properties);
    if (a == b) {
      properties.add(DiagnosticsProperty('value', a));
      return;
    }
    properties.add(DiagnosticsProperty('a', a));
    properties.add(DiagnosticsProperty('b', b));
    properties.add(PercentProperty('t', t));
  }
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
    with VectorDiagnosticableMixin
    implements StyleResolvable<Object> {
  final StyleOr<PathData> pathData;
  final bool isX;
  final double t;

  _CoordinateInterpolatedValue(this.pathData, this.isX, this.t);

  @override
  Object? resolve(StyleResolver resolver) {
    final path = pathData.resolve(resolver)!;
    final result = path.evaluateAt(t);
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

  @override
  Iterable<String> get nonUniqueAnimatedAttributes =>
      _holderTweens.map((e) => e.propertyName);
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
