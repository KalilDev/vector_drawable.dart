import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:xml/xml.dart';
import 'package:path_parsing/path_parsing.dart';

import '../parsing/animation.dart';
import 'animated_vector_drawable.dart';
import 'resource.dart';

//https://developer.android.com/guide/topics/resources/animation-resource
class AnimationResource extends Resource {
  final AnimationNode body;

  AnimationResource(this.body, ResourceReference? source) : super(source);

  static AnimationResource parseDocument(
          XmlDocument document, ResourceReference source) =>
      parseAnimationResource(document.rootElement, source);
  static AnimationResource parseElement(XmlElement document) =>
      parseAnimationResource(document, null);
}

abstract class AnimationNode implements Diagnosticable {}

/// Name of the property being animated.
enum AnimationOrdering {
  /// Child animations should be played together.
  together,

  /// Child animations should be played sequentially, in the same order as the xml.
  sequentially,
}

class AnimationSet extends AnimationNode with DiagnosticableTreeMixin {
  final AnimationOrdering ordering;
  final List<AnimationNode> children;

  AnimationSet(this.ordering, this.children);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(EnumProperty('ordering', ordering,
        defaultValue: AnimationOrdering.together));
  }
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

class PropertyValuesHolder with Diagnosticable {
  final ValueType valueType;
  final String propertyName;
  final Object? valueFrom;
  final Object? valueTo;
  final List<Keyframe>? keyframes;

  PropertyValuesHolder({
    this.valueType = ValueType.floatType,
    required this.propertyName,
    this.valueFrom,
    this.valueTo,
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
  }
}

class Keyframe with Diagnosticable {
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
}

class Interpolator extends Resource {
  Interpolator(ResourceReference? source, String curveName) : super(source);
  final Curve curve = Curves.linear;
}

/// ValueAnimator class attributes
class Animation extends AnimationNode with Diagnosticable {
  /// Amount of time (in milliseconds) for the animation to run.
  final int duration;

  final Object valueFrom;
  final Object valueTo;

  /// Delay in milliseconds before the animation runs, once start time is reached.
  final int startOffset;

  /// Defines how many times the animation should repeat. The default value is 0.
  final int repeatCount;

  /// Defines the animation behavior when it reaches the end and the repeat count is
  /// greater than 0 or infinite. The default value is restart.
  final RepeatMode repeatMode;
  final ValueType valueType;

  Animation({
    this.duration = 300,
    required this.valueFrom,
    required this.valueTo,
    this.startOffset = 0,
    this.repeatCount = 0,
    this.repeatMode = RepeatMode.repeat,
    this.valueType = ValueType.floatType,
  });
}

/// ObjectAnimator class attributes
class ObjectAnimation extends AnimationNode with DiagnosticableTreeMixin {
  /// Name of the property being animated.
  final String? propertyName;

  /// Amount of time (in milliseconds) for the animation to run.
  final int duration;

  Object? valueFrom;
  Object? valueTo;

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
    required this.propertyName,
    this.duration = 300,
    this.valueFrom,
    this.valueTo,
    this.startOffset = 0,
    this.repeatCount = 0,
    this.repeatMode = RepeatMode.repeat,
    this.valueType = ValueType.floatType,
    this.valueHolders,
  }) : assert((valueHolders != null) ^ (valueTo != null));
  @override
  List<DiagnosticsNode> debugDescribeChildren() => valueHolders == null
      ? []
      : valueHolders!.map((e) => e.toDiagnosticsNode()).toList();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty('propertyName', propertyName));
    properties.add(DiagnosticsProperty('duration', duration));
    properties.add(DiagnosticsProperty('valueFrom', valueFrom));
    properties.add(DiagnosticsProperty('valueTo', valueTo));
    properties
        .add(DiagnosticsProperty('startOffset', startOffset, defaultValue: 0));
    properties
        .add(DiagnosticsProperty('repeatCount', repeatCount, defaultValue: 0));
    properties.add(EnumProperty('repeatMode', repeatMode,
        defaultValue: RepeatMode.repeat));
    properties.add(EnumProperty('valueType', valueType,
        defaultValue: ValueType.floatType));
  }
}
