import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:vector_drawable/vector_drawable.dart';
import 'package:xml/xml.dart';
import 'package:path_parsing/path_parsing.dart';

import '../parsing/animation.dart';
import '../parsing/interpolator.dart';
import 'animated_vector_drawable.dart';
import 'resource.dart';
import 'vector_drawable.dart';

//https://developer.android.com/guide/topics/resources/animation-resource
class AnimationResource extends Resource
    implements Clonable<AnimationResource> {
  final AnimationNode body;

  AnimationResource(this.body, ResourceReference? source) : super(source);

  static AnimationResource parseDocument(
          XmlDocument document, ResourceReference source) =>
      parseAnimationResource(document.rootElement, source);
  static AnimationResource parseElement(XmlElement document) =>
      parseAnimationResource(document, null);

  @override
  AnimationResource clone() =>
      AnimationResource(AnimationNode.cloneNode(body), source);
}

abstract class AnimationNode implements Diagnosticable {
  static AnimationNode cloneNode(AnimationNode node) => node is AnimationSet
      ? node.clone()
      : node is ObjectAnimation
          ? node.clone()
          : (throw TypeError()) as AnimationNode;
}

/// Name of the property being animated.
enum AnimationOrdering {
  /// Child animations should be played together.
  together,

  /// Child animations should be played sequentially, in the same order as the xml.
  sequentially,
}

class AnimationSet extends AnimationNode
    with DiagnosticableTreeMixin
    implements Clonable<AnimationSet> {
  final AnimationOrdering ordering;
  final List<AnimationNode> children;

  AnimationSet(this.ordering, this.children);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(EnumProperty('ordering', ordering,
        defaultValue: AnimationOrdering.together));
  }

  @override
  AnimationSet clone() =>
      AnimationSet(ordering, children.map(AnimationNode.cloneNode).toList());
}

enum RepeatMode {
  repeat,
  reverse,
}

/// The type of valueFrom and valueTo.
enum ValueType {
  /// The given values are floats. This is the default value if valueType is
  /// unspecified. Note that if any value attribute has a color value
  /// (beginning with "#"), then this attribute is ignored and the color values are
  /// interpreted as integers.
  floatType,

  /// values are integers.
  intType,
}

class PropertyValuesHolder
    with Diagnosticable
    implements Clonable<PropertyValuesHolder> {
  final ValueType valueType;
  final String propertyName;
  final Object? valueFrom;
  final Object? valueTo;
  final ResourceOrReference<Interpolator>? interpolator;
  final List<Keyframe>? keyframes;

  PropertyValuesHolder({
    this.valueType = ValueType.floatType,
    required this.propertyName,
    this.valueFrom,
    this.valueTo,
    this.interpolator,
    this.keyframes,
  }) : assert((keyframes != null) ^ (valueTo != null));

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(EnumProperty('valueType', valueType,
        defaultValue: ValueType.floatType));
    properties.add(DiagnosticsProperty('propertyName', propertyName));
    properties.add(DiagnosticsProperty('valueFrom', valueFrom,
        ifNull: 'interpolated from drawable'));
    properties.add(DiagnosticsProperty('valueTo', valueTo,
        ifNull: 'interpolated from drawable'));
    properties.add(DiagnosticsProperty('interpolator', interpolator));
  }

  @override
  PropertyValuesHolder clone() => PropertyValuesHolder(
        valueType: valueType,
        propertyName: propertyName,
        valueFrom: valueFrom,
        valueTo: valueTo,
        interpolator: interpolator?.clone(),
        keyframes: keyframes?.map(cloneAn).toList(),
      );
}

class Keyframe with Diagnosticable implements Clonable<Keyframe> {
  final ValueType valueType;
  final Object? value;
  final double? fraction;
  final ResourceOrReference<Interpolator>? interpolator;

  Keyframe({
    this.valueType = ValueType.floatType,
    this.value,
    this.fraction,
    this.interpolator,
  });
  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(EnumProperty('valueType', valueType,
        defaultValue: ValueType.floatType));
    properties.add(DiagnosticsProperty('value', value));
    properties.add(DoubleProperty('fraction', fraction, ifNull: 'uniform'));
    properties.add(
        DiagnosticsProperty('interpolator', interpolator, missingIfNull: true));
  }

  @override
  Keyframe clone() => Keyframe(
        valueType: valueType,
        value: value,
        fraction: fraction,
        interpolator: interpolator?.clone(),
      );
}

class PathInterpolator extends Interpolator {
  final PathData pathData;
  PathInterpolator({
    required this.pathData,
    ResourceReference? source,
  }) : super(source);

  @override
  double transform(double t) => pathData.evaluateAt(t).dy;
}

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

abstract class Interpolator extends Resource {
  Interpolator(ResourceReference? source) : super(source);
  factory Interpolator.parseDocument(
          XmlDocument element, ResourceReference source) =>
      parseInterpolatorElement(element.rootElement, source);
  factory Interpolator.parseElement(XmlElement element) =>
      parseInterpolatorElement(element, null);
  double transform(double t);
}

/// ObjectAnimator class attributes
class ObjectAnimation extends AnimationNode
    with DiagnosticableTreeMixin
    implements Clonable<ObjectAnimation> {
  /// Name of the property being animated.
  final String? propertyName;

  final String? propertyXName;
  final String? propertyYName;
  final StyleOr<PathData>? pathData;

  /// Amount of time (in milliseconds) for the animation to run.
  final int duration;

  StyleOr<Object>? valueFrom;
  StyleOr<Object>? valueTo;
  ResourceOrReference<Interpolator>? interpolator;

  /// Delay in milliseconds before the animation runs, once start time is reached.
  final int startOffset;

  /// Defines how many times the animation should repeat. The default value is 0.
  final int repeatCount;

  /// Defines the animation behavior when it reaches the end and the repeat count is
  /// greater than 0 or infinite. The default value is restart.
  final RepeatMode repeatMode;
  final ValueType valueType;

  final List<PropertyValuesHolder>? valueHolders;

  ObjectAnimation({
    this.propertyName,
    this.propertyXName,
    this.propertyYName,
    this.pathData,
    this.duration = 300,
    this.valueFrom,
    this.valueTo,
    this.interpolator,
    this.startOffset = 0,
    this.repeatCount = 0,
    this.repeatMode = RepeatMode.repeat,
    this.valueType = ValueType.floatType,
    this.valueHolders,
  }) : assert((valueHolders != null) ^ (valueTo != null || pathData != null));
  @override
  List<DiagnosticsNode> debugDescribeChildren() => valueHolders == null
      ? []
      : valueHolders!.map((e) => e.toDiagnosticsNode()).toList();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty('propertyName', propertyName));
    properties.add(DiagnosticsProperty('propertyXName', propertyXName));
    properties.add(DiagnosticsProperty('propertyYName', propertyYName));
    properties.add(DiagnosticsProperty('pathData', pathData));
    properties.add(DiagnosticsProperty('duration', duration));
    properties.add(DiagnosticsProperty('valueFrom', valueFrom));
    properties.add(DiagnosticsProperty('valueTo', valueTo));
    properties.add(DiagnosticsProperty('interpolator', interpolator));
    properties
        .add(DiagnosticsProperty('startOffset', startOffset, defaultValue: 0));
    properties
        .add(DiagnosticsProperty('repeatCount', repeatCount, defaultValue: 0));
    properties.add(EnumProperty('repeatMode', repeatMode,
        defaultValue: RepeatMode.repeat));
    properties.add(EnumProperty('valueType', valueType,
        defaultValue: ValueType.floatType));
  }

  @override
  ObjectAnimation clone() => ObjectAnimation(
        propertyName: propertyName,
        propertyXName: propertyXName,
        propertyYName: propertyYName,
        pathData: pathData,
        duration: duration,
        valueFrom: valueFrom,
        valueTo: valueTo,
        interpolator: interpolator?.clone(),
        startOffset: startOffset,
        repeatCount: repeatCount,
        repeatMode: repeatMode,
        valueType: valueType,
        valueHolders: valueHolders?.map(cloneAn).toList(),
      );
}
