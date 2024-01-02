import 'package:path_parsing/path_parsing.dart';
import 'package:path_parsing/src/path_segment_type.dart';
import 'package:path_parsing/src/path_parsing.dart';
import 'package:vector_drawable/src/model/diagnostics.dart';
import 'package:vector_drawable/src/path_evaluator.dart';
import 'package:vector_drawable/vector_drawable.dart';
import 'package:vector_math/vector_math_64.dart';
import 'package:xml/xml.dart';

import '../parsing/animation.dart';
import '../parsing/interpolator.dart';
import '../serializing/animation.dart';
import '../serializing/interpolator.dart';

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

  static XmlDocument serializeDocument(AnimationResource animation) {
    final builder = XmlBuilder();
    serializeElement(builder, animation);
    return builder.buildDocument();
  }

  static void serializeElement(XmlBuilder b, AnimationResource animation) =>
      serializeAnimationResource(b, animation);

  @override
  AnimationResource clone() =>
      AnimationResource(AnimationNode.cloneNode(body), source);
}

abstract class AnimationNode implements VectorDiagnosticable {
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
    with VectorDiagnosticableTreeMixin
    implements Clonable<AnimationSet> {
  final AnimationOrdering ordering;
  final List<AnimationNode> children;

  AnimationSet(this.ordering, this.children);

  // @override
  // void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  //   super.debugFillProperties(properties);
  //   properties.add(EnumProperty('ordering', ordering,
  //       defaultValue: AnimationOrdering.together));
  // }

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
    with VectorDiagnosticableMixin
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

  // @override
  // void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  //   super.debugFillProperties(properties);
  //   properties.add(EnumProperty('valueType', valueType,
  //       defaultValue: ValueType.floatType));
  //   properties.add(DiagnosticsProperty('propertyName', propertyName));
  //   properties.add(DiagnosticsProperty('valueFrom', valueFrom,
  //       ifNull: 'interpolated from drawable'));
  //   properties.add(DiagnosticsProperty('valueTo', valueTo,
  //       ifNull: 'interpolated from drawable'));
  //   properties.add(DiagnosticsProperty('interpolator', interpolator));
  // }

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

class Keyframe with VectorDiagnosticableMixin implements Clonable<Keyframe> {
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

  // @override
  // void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  //   super.debugFillProperties(properties);
  //   properties.add(EnumProperty('valueType', valueType,
  //       defaultValue: ValueType.floatType));
  //   properties.add(DiagnosticsProperty('value', value));
  //   properties.add(DoubleProperty('fraction', fraction, ifNull: 'uniform'));
  //   properties.add(
  //       DiagnosticsProperty('interpolator', interpolator, missingIfNull: true));
  // }

  @override
  Keyframe clone() => Keyframe(
        valueType: valueType,
        value: value,
        fraction: fraction,
        interpolator: interpolator?.clone(),
      );
}

class LinearInterpolator extends Interpolator {
  LinearInterpolator({
    ResourceReference? source,
  }) : super(source);

  @override
  double transform(double t) => t;
}

final _unitXPathOffset = () {
  final SvgPathStringSource parser = SvgPathStringSource('M 1 0');
  return parser.parseSegment().targetPoint;
}();
final _unitPathOffset = () {
  final SvgPathStringSource parser = SvgPathStringSource('M 1 1');
  return parser.parseSegment().targetPoint;
}();
final _unitYPathOffset = () {
  final SvgPathStringSource parser = SvgPathStringSource('M 0 1');
  return parser.parseSegment().targetPoint;
}();
final _pathOffset =
    (double dx, double dy) => (_unitXPathOffset * dx) + (_unitYPathOffset * dy);
PathData _pathDataFromCubicSegment(
  double controlX1,
  double controlY1,
  double controlX2,
  double controlY2,
) =>
    PathData.fromSegments([
      // TODO: needed?
      PathSegmentData()..command = SvgPathSegType.moveToAbs,
      PathSegmentData()
        ..command = SvgPathSegType.cubicToAbs
        ..point1 = _pathOffset(controlX1, controlY1)
        ..point2 = _pathOffset(controlX2, controlY2)
        ..targetPoint = _unitPathOffset
    ]);

class PathInterpolator extends Interpolator {
  final PathData pathData;
  PathInterpolator({
    required this.pathData,
    ResourceReference? source,
  }) : super(source);

  PathInterpolator.cubic({
    required double controlX1,
    required double controlY1,
    required double controlX2,
    required double controlY2,
    ResourceReference? source,
  })  : pathData = _pathDataFromCubicSegment(
            controlX1, controlY1, controlX2, controlY2),
        super(source);

  PathInterpolator.quadratic({
    required double controlX,
    required double controlY,
    ResourceReference? source,
  })  : pathData = _pathDataFromCubicSegment(controlX * 1 / 3, controlY * 1 / 3,
            controlX * 2 / 3, controlY * 2 / 3),
        super(source);

  static const int _kPrecisionSteps = 30;
  late final List<Vector2> _vals = List.generate(
      _kPrecisionSteps,
      (i) => PathEvaluator.instance
          .evaluatePathAt(pathData, i / _kPrecisionSteps));
  @override
  double transform(double x) {
    double lastX = 0;
    double lastY = 0;
    // TODO: bisect
    final it = _vals.iterator;
    while (it.moveNext() && lastX < x) {
      final v = it.current;
      if (v.x >= x) {
        final dtX = (x - lastX) / (v.x - lastX);
        final e = _lerpDouble(lastY, v.y, dtX);
        return e;
      }
      lastX = v.x;
      lastY = v.y;
    }
    return 1;
  }
}

double _lerpDouble(double a, double b, double t) => a + (b - a) * t;

abstract class Interpolator extends Resource {
  Interpolator(ResourceReference? source) : super(source);
  factory Interpolator.parseDocument(
          XmlDocument element, ResourceReference source) =>
      parseInterpolatorElement(element.rootElement, source);
  factory Interpolator.parseElement(XmlElement element) =>
      parseInterpolatorElement(element, null);

  static XmlDocument serializeDocument(Interpolator interpolator) {
    final builder = XmlBuilder();
    serializeElement(builder, interpolator);
    return builder.buildDocument();
  }

  static void serializeElement(XmlBuilder b, Interpolator interpolator) =>
      serializeInterpolator(b, interpolator);

  double transform(double t);
}

/// ObjectAnimator class attributes
class ObjectAnimation extends AnimationNode
    with VectorDiagnosticableTreeMixin
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
  List<VectorDiagnosticsNode> diagnosticsChildren() => valueHolders == null
      ? []
      : valueHolders!.map((e) => e.toDiagnosticsNode()).toList();

  @override
  List<VectorProperty> properties() => [
        VectorNullableProperty<String>('propertyName', propertyName),
        VectorNullableProperty<String>('propertyXName', propertyXName),
        VectorNullableProperty<String>('propertyYName', propertyYName),
        VectorNullableProperty<StyleOr<PathData>>('pathData', pathData),
        VectorNullableProperty<int>('duration', duration),
        VectorNullableProperty<StyleOr<Object>>('valueFrom', valueFrom),
        VectorNullableProperty<StyleOr<Object>>('valueTo', valueTo),
        VectorNullableProperty<ResourceOrReference<Interpolator>>(
            'interpolator', interpolator),
        VectorNullableProperty<int>.withDefault('startOffset', startOffset,
            defaultValue: 0),
        VectorNullableProperty<int>.withDefault('repeatCount', repeatCount,
            defaultValue: 0),
        VectorEnumProperty<RepeatMode>('repeatMode', repeatMode,
            defaultValue: RepeatMode.repeat),
        VectorEnumProperty<ValueType>('valueType', valueType,
            defaultValue: ValueType.floatType),
      ];

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
