import 'dart:collection';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:vector_drawable/src/model/style.dart';
import 'package:xml/xml.dart';
import 'package:path_parsing/path_parsing.dart';
import 'package:path_parsing/src/path_segment_type.dart';

import '../parsing/util.dart';
import '../parsing/vector_drawable.dart';
import 'resource.dart';

// TODO: pt, mm, in
enum DimensionKind { dip, dp, px, sp }

class Dimension {
  final double value;
  final DimensionKind kind;

  Dimension(this.value, this.kind);
}

class VectorDrawable extends Resource {
  final Vector body;

  VectorDrawable(this.body, ResourceReference? source) : super(source);
  static VectorDrawable parseDocument(
          XmlDocument document, ResourceReference source) =>
      parseVectorDrawable(document.rootElement, source);
  static VectorDrawable parseElement(XmlElement element) =>
      parseVectorDrawable(element, null);
}

// https://developer.android.com/reference/android/graphics/drawable/VectorDrawable
abstract class VectorDrawableNode implements Diagnosticable {
  final String? name;
  VectorDrawableNode({
    this.name,
  });
  Iterable<StyleProperty> get _usedStyles;
  Iterable<StyleProperty> get _localUsedStyles;
  late final Set<StyleProperty> localUsedStyles = _localUsedStyles.toSet();
  late final Set<StyleProperty> usedStyles = _usedStyles.toSet();
}

abstract class VectorPart extends VectorDrawableNode {
  VectorPart({required String? name}) : super(name: name);
}

class Vector extends VectorDrawableNode with DiagnosticableTreeMixin {
  final Dimension width;
  final Dimension height;
  final double viewportWidth;
  final double viewportHeight;
  final StyleOr<Color>? tint;
  final BlendMode tintMode;
  final bool autoMirrored;
  final StyleOr<double> opacity;
  final List<VectorPart> children;

  Vector({
    required String? name,
    required this.width,
    required this.height,
    required this.viewportWidth,
    required this.viewportHeight,
    required this.tint,
    this.tintMode = BlendMode.srcIn,
    this.autoMirrored = false,
    this.opacity = const StyleOr.value(1.0),
    required this.children,
  }) : super(name: name);

  @override
  List<DiagnosticsNode> debugDescribeChildren() =>
      children.map((e) => e.toDiagnosticsNode()).toList();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty('width', width));
    properties.add(DiagnosticsProperty('height', height));
    properties.add(DoubleProperty('viewportWidth', viewportWidth));
    properties.add(DoubleProperty('viewportHeight', viewportHeight));
    properties.add(DiagnosticsProperty('tint', tint));
    properties
        .add(EnumProperty('tintMode', tintMode, defaultValue: BlendMode.srcIn));
    properties.add(FlagProperty(
      'autoMirrored',
      value: autoMirrored,
      defaultValue: false,
      ifTrue: 'mirrored on rtl',
    ));
    properties.add(DiagnosticsProperty('opacity', opacity, defaultValue: 1.0));
  }

  @override
  Iterable<StyleProperty> get _usedStyles =>
      children.expand((e) => e._usedStyles).followedBy(_localUsedStyles);

  @override
  Iterable<StyleProperty> get _localUsedStyles => [
        if (tint?.styled != null) tint!.styled!,
        if (opacity.styled != null) opacity.styled!,
      ];
}

void _copySegmentInto(PathSegmentData source, PathSegmentData target) => target
  ..command = source.command
  ..targetPoint = source.targetPoint
  ..point1 = source.point1
  ..point2 = source.point2
  ..arcSweep = source.arcSweep
  ..arcLarge = source.arcLarge;

final mutableSegment = PathSegmentData();
void emitSegmentWithoutMutation(
  PathSegmentData segment,
  PathProxy path,
  SvgPathNormalizer normalizer,
) {
  _copySegmentInto(segment, mutableSegment);
  normalizer.emitSegment(mutableSegment, path);
}

class PathData {
  PathData.fromString(String asString) : _asString = asString;
  PathData.fromSegments(Iterable<PathSegmentData> segments)
      : _segments = segments.toList();
  PathData.fromCubicSegments(List<StandaloneCubic> segments)
      : _finishedComputer = _PathCubicWriter.from(segments);
  String? _asString;
  List<PathSegmentData>? _segments;
  static List<PathSegmentData> _parse(String asString) {
    final SvgPathStringSource parser = SvgPathStringSource(asString);
    // Parse each segment individually, appending an close segment in case an
    // error occurs.
    final result = <PathSegmentData>[];
    try {
      while (parser.hasMoreData) {
        result.add(parser.parseSegment());
      }
    } catch (e) {
      print(e);
      result.add(PathSegmentData()..command = SvgPathSegType.close);
    }
    return result;
  }

  static String _toString(List<PathSegmentData> segments) {
    final result = StringBuffer();
    throw UnimplementedError('TODO');
    return result.toString();
  }

  UnmodifiableListView<PathSegmentData> get segments =>
      UnmodifiableListView(_segments ??=
          _asString == null ? _finishedComputer!.segments : _parse(_asString!));

  String get asString => _asString ??= _toString(segments);

  _PathCubicWriter? _finishedComputer;
  late final _PathCubicWriter _computer = _finishedComputer ??= () {
    final computer = _PathCubicWriter.empty();
    final normalizer = SvgPathNormalizer();
    for (final seg in segments) {
      emitSegmentWithoutMutation(seg, computer, normalizer);
    }
    return computer;
  }();

  Offset evaluateAt(double t) {
    return _computer.eval(t);
  }

  void emitTo(PathProxy proxy) {
    _computer.emitTo(proxy);
  }

  PathData segmentsFrom(double t0, double t1) {
    if (t0 == 0 && t1 == 1) {
      return this;
    }
    if (t0 == t1) {
      return PathData.fromSegments([]);
    }
    return PathData.fromCubicSegments(_computer.segmentsFrom(t0, t1));
  }
}

class StandaloneCubic {
  final Offset p0;
  final Offset p1;
  final Offset p2;
  final Offset p3;

  StandaloneCubic(
    this.p0,
    this.p1,
    this.p2,
    this.p3,
  );
  Offset eval(double t) {
    final p0ToP1 = p1 - p0;
    final p1ToP2 = p2 - p1;
    final p2ToP3 = p3 - p2;

    final p01 = p0 + (p0ToP1 * t);
    final p12 = p1 + (p1ToP2 * t);
    final p23 = p2 + (p2ToP3 * t);

    final p01toP12 = p12 - p01;
    final p12toP23 = p23 - p12;
    final p012 = p01 + (p01toP12 * t);
    final p123 = p12 + (p12toP23 * t);

    final p012toP123 = p123 - p012;
    final target = p012 + (p012toP123 * t);
    return target;
  }

  /// Algorithm from https://stackoverflow.com/questions/878862/drawing-part-of-a-b%c3%a9zier-curve-by-reusing-a-basic-b%c3%a9zier-curve-function/879213#879213
  StandaloneCubic segmentFrom(double t0, double t1) {
    final x1 = p0.dx, y1 = p0.dy;
    final bx1 = p1.dx, by1 = p1.dy;
    final bx2 = p2.dx, by2 = p2.dy;
    final x2 = p3.dx, y2 = p3.dy;

    final u0 = 1.0 - t0;
    final u1 = 1.0 - t1;

    final qxa = x1 * u0 * u0 + bx1 * 2 * t0 * u0 + bx2 * t0 * t0;
    final qxb = x1 * u1 * u1 + bx1 * 2 * t1 * u1 + bx2 * t1 * t1;
    final qxc = bx1 * u0 * u0 + bx2 * 2 * t0 * u0 + x2 * t0 * t0;
    final qxd = bx1 * u1 * u1 + bx2 * 2 * t1 * u1 + x2 * t1 * t1;

    final qya = y1 * u0 * u0 + by1 * 2 * t0 * u0 + by2 * t0 * t0;
    final qyb = y1 * u1 * u1 + by1 * 2 * t1 * u1 + by2 * t1 * t1;
    final qyc = by1 * u0 * u0 + by2 * 2 * t0 * u0 + y2 * t0 * t0;
    final qyd = by1 * u1 * u1 + by2 * 2 * t1 * u1 + y2 * t1 * t1;

    final xa = qxa * u0 + qxc * t0;
    final xb = qxa * u1 + qxc * t1;
    final xc = qxb * u0 + qxd * t0;
    final xd = qxb * u1 + qxd * t1;

    final ya = qya * u0 + qyc * t0;
    final yb = qya * u1 + qyc * t1;
    final yc = qyb * u0 + qyd * t0;
    final yd = qyb * u1 + qyd * t1;

    return StandaloneCubic(
      Offset(xa, ya),
      Offset(xb, yb),
      Offset(xc, yc),
      Offset(xd, yd),
    );
  }

  double computeWeigth(int steps) {
    double weigth = 0.0;
    Offset lastPoint = p0;
    for (var i = 1; i <= steps; i++) {
      final t = i / steps;
      final point = eval(t);
      final dt = point - lastPoint;
      weigth += dt.distanceSquared;
      lastPoint = point;
    }
    return weigth;
  }

  double computeLength(int steps) {
    double length = 0.0;
    Offset lastPoint = p0;
    for (var i = 1; i <= steps; i++) {
      final t = i / steps;
      final point = eval(t);
      final dt = point - lastPoint;
      length += dt.distance;
      lastPoint = point;
    }
    return length;
  }

  double _approximateWeigth() {
    final p0ToP1 = p1 - p0;
    final p1ToP2 = p2 - p1;
    final p2ToP3 = p3 - p2;
    return p0ToP1.distanceSquared +
        p1ToP2.distanceSquared +
        p2ToP3.distanceSquared;
  }

  late final double approximateWeigth = _approximateWeigth();
}

class _PathCubicWriter extends PathProxy {
  final List<StandaloneCubic> _cubics;
  Offset _current = Offset.zero;
  Offset _start = Offset.zero;

  static final unitXPathOffset = () {
    final SvgPathStringSource parser = SvgPathStringSource('M 1 0');
    return parser.parseSegment().targetPoint;
  }();
  static final unitYPathOffset = () {
    final SvgPathStringSource parser = SvgPathStringSource('M 0 1');
    return parser.parseSegment().targetPoint;
  }();

  _PathCubicWriter.empty() : _cubics = [];
  _PathCubicWriter.from(this._cubics);
  late final UnmodifiableListView<PathSegmentData> segments =
      UnmodifiableListView<PathSegmentData>(_toSegments());

  void emitTo(PathProxy path) {
    Offset current = Offset.zero;
    for (final cubic in _cubics) {
      if (cubic.p0 != current) {
        path.moveTo(cubic.p0.dx, cubic.p0.dy);
      }
      path.cubicTo(
        cubic.p1.dx,
        cubic.p1.dy,
        cubic.p2.dx,
        cubic.p2.dy,
        cubic.p3.dx,
        cubic.p3.dy,
      );
      current = cubic.p3;
    }
  }

  List<PathSegmentData> _toSegments() {
    Offset current = Offset.zero;
    return _cubics.expand((e) {
      final cubic = PathSegmentData()
        ..command = SvgPathSegType.cubicToAbs
        ..point1 = (unitXPathOffset * e.p1.dx + unitYPathOffset * e.p1.dy)
        ..point2 = (unitXPathOffset * e.p2.dx + unitYPathOffset * e.p2.dy)
        ..targetPoint = (unitXPathOffset * e.p3.dx + unitYPathOffset * e.p3.dy);
      if (e.p0 == current) {
        current = e.p3;
        return [cubic];
      }
      current = e.p3;
      return [
        PathSegmentData()
          ..command = SvgPathSegType.moveToAbs
          ..targetPoint =
              (unitXPathOffset * e.p0.dx + unitYPathOffset * e.p0.dy),
        cubic,
      ];
    }).toList();
  }

  @override
  void close() {
    if (_current == _start) {
      return;
    }
    lineTo(_start.dx, _start.dy);
  }

  @override
  void cubicTo(
    double x1,
    double y1,
    double x2,
    double y2,
    double x3,
    double y3,
  ) {
    final p0 = _current;
    final p1 = Offset(x1, y1);
    final p2 = Offset(x2, y2);
    final p3 = Offset(x3, y3);
    _cubics.add(StandaloneCubic(p0, p1, p2, p3));
    _current = p3;
  }

  @override
  void lineTo(double x, double y) {
    final p0 = _current;
    final p3 = Offset(x, y);
    final p0ToP3 = p3 - p0;
    final p1 = p0 + (p0ToP3 * (1 / 3));
    final p2 = p0 + (p0ToP3 * (2 / 3));
    _cubics.add(StandaloneCubic(p0, p1, p2, p3));
    _current = p3;
  }

  @override
  void moveTo(double x, double y) => _start = _current = Offset(x, y);

  late final totalWeigth = _cubics.fold<double>(
    0.0,
    (acc, e) => acc + e.approximateWeigth,
  );

  Offset eval(double t) {
    if (_cubics.isEmpty) {
      return Offset.zero;
    }
    final targetWeigthPoint = t * totalWeigth;
    var currentAccumullatedWeigth = 0.0;
    for (final cubic in _cubics) {
      if (currentAccumullatedWeigth + cubic.approximateWeigth <
          targetWeigthPoint) {
        currentAccumullatedWeigth += cubic.approximateWeigth;
        continue;
      }
      final t = (targetWeigthPoint - currentAccumullatedWeigth) /
          cubic.approximateWeigth;
      return cubic.eval(t);
    }
    return _cubics.last.p3;
  }

  List<StandaloneCubic> segmentsFrom(double t0, double t1) {
    if (t0 == 0 && t1 == 1) {
      return _cubics;
    }
    if (t0 < 0 || t0 > t1 || t1 > 1) {
      throw RangeError('t0 and t1 do not follow that 0 <= $t0 <= $t1 <= 1');
    }
    final targetWeigthPoint0 = t0 * totalWeigth;
    final targetWeigthPoint1 = t1 * totalWeigth;
    var currentAccumullatedWeigth = 0.0;
    final result = <StandaloneCubic>[];
    final it = _cubics.iterator;
    while (it.moveNext() && currentAccumullatedWeigth < targetWeigthPoint1) {
      final point = it.current;
      final pointWeigth = point.approximateWeigth;
      final t0 =
          ((targetWeigthPoint0 - currentAccumullatedWeigth) / pointWeigth)
              .clamp(0.0, 1.0);
      final t1 =
          ((targetWeigthPoint1 - currentAccumullatedWeigth) / pointWeigth)
              .clamp(0.0, 1.0);
      currentAccumullatedWeigth += pointWeigth;
      // This cubic would be empty
      if (t0 == t1) {
        continue;
      }
      final cutSegment = point.segmentFrom(t0, t1);
      result.add(cutSegment);
    }
    return result;
  }
}

class ClipPath extends VectorPart with DiagnosticableTreeMixin {
  final StyleOr<PathData> pathData;
  final List<VectorPart> children;

  ClipPath({
    String? name,
    required this.pathData,
    required this.children,
  }) : super(name: name);

  @override
  Iterable<StyleProperty> get _usedStyles =>
      _localUsedStyles.followedBy(children.expand((e) => e._usedStyles));
  @override
  Iterable<StyleProperty> get _localUsedStyles => [
        if (pathData.styled != null) pathData.styled!,
      ];

  @override
  List<DiagnosticsNode> debugDescribeChildren() =>
      children.map((e) => e.toDiagnosticsNode()).toList();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty('pathData', pathData));
  }
}

class Group extends VectorPart with DiagnosticableTreeMixin {
  final StyleOr<double>? rotation;
  final StyleOr<double>? pivotX;
  final StyleOr<double>? pivotY;
  final StyleOr<double>? scaleX;
  final StyleOr<double>? scaleY;
  final StyleOr<double>? translateX;
  final StyleOr<double>? translateY;
  final List<VectorPart> children;

  Group({
    required String? name,
    required this.rotation,
    required this.pivotX,
    required this.pivotY,
    required this.scaleX,
    required this.scaleY,
    required this.translateX,
    required this.translateY,
    required this.children,
  }) : super(name: name);

  @override
  List<DiagnosticsNode> debugDescribeChildren() =>
      children.map((e) => e.toDiagnosticsNode()).toList();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty('rotation', rotation));
    properties.add(DiagnosticsProperty('pivotX', pivotX));
    properties.add(DiagnosticsProperty('pivotY', pivotY));
    properties.add(DiagnosticsProperty('scaleX', scaleX));
    properties.add(DiagnosticsProperty('scaleY', scaleY));
    properties.add(DiagnosticsProperty('translateX', translateX));
    properties.add(DiagnosticsProperty('translateY', translateY));
  }

  @override
  Iterable<StyleProperty> get _usedStyles =>
      _localUsedStyles.followedBy(children.expand((e) => e._usedStyles));
  @override
  Iterable<StyleProperty> get _localUsedStyles => [
        if (rotation?.styled != null) rotation!.styled!,
        if (pivotX?.styled != null) pivotX!.styled!,
        if (pivotY?.styled != null) pivotY!.styled!,
        if (scaleX?.styled != null) scaleX!.styled!,
        if (scaleY?.styled != null) scaleY!.styled!,
        if (translateX?.styled != null) translateX!.styled!,
        if (translateY?.styled != null) translateY!.styled!,
      ];
}

enum FillType { nonZero, evenOdd }
enum StrokeLineCap {
  butt,
  round,
  square,
}
enum StrokeLineJoin {
  miter,
  round,
  bevel,
}

class Path extends VectorPart with Diagnosticable {
  final StyleOr<PathData> pathData;
  final StyleOr<Color>? fillColor;
  final StyleOr<Color>? strokeColor;
  final StyleOr<double> strokeWidth;
  final StyleOr<double> strokeAlpha;
  final StyleOr<double> fillAlpha;
  final StyleOr<double> trimPathStart;
  final StyleOr<double> trimPathEnd;
  final StyleOr<double> trimPathOffset;
  final StrokeLineCap strokeLineCap;
  final StrokeLineJoin strokeLineJoin;
  final double strokeMiterLimit;
  final FillType fillType;

  Path({
    required String? name,
    required this.pathData,
    required this.fillColor,
    required this.strokeColor,
    this.strokeWidth = const StyleOr.value(0),
    this.strokeAlpha = const StyleOr.value(1),
    this.fillAlpha = const StyleOr.value(1),
    this.trimPathStart = const StyleOr.value(0),
    this.trimPathEnd = const StyleOr.value(1),
    this.trimPathOffset = const StyleOr.value(0),
    this.strokeLineCap = StrokeLineCap.butt,
    this.strokeLineJoin = StrokeLineJoin.miter,
    this.strokeMiterLimit = 4,
    this.fillType = FillType.nonZero,
  }) : super(name: name);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('name', name));
    properties.add(DiagnosticsProperty('pathData', pathData));
    properties.add(DiagnosticsProperty('fillColor', fillColor));
    properties.add(DiagnosticsProperty('strokeColor', strokeColor));
    properties
        .add(DiagnosticsProperty('strokeWidth', strokeWidth, defaultValue: 0));
    properties
        .add(DiagnosticsProperty('strokeAlpha', strokeAlpha, defaultValue: 1));
    properties
        .add(DiagnosticsProperty('fillAlpha', fillAlpha, defaultValue: 1));
    properties.add(
        DiagnosticsProperty('trimPathStart', trimPathStart, defaultValue: 0));
    properties
        .add(DiagnosticsProperty('trimPathEnd', trimPathEnd, defaultValue: 1));
    properties.add(
        DiagnosticsProperty('trimPathOffset', trimPathOffset, defaultValue: 0));
    properties.add(EnumProperty('strokeLineCap', strokeLineCap,
        defaultValue: StrokeLineCap.butt));
    properties.add(EnumProperty('strokeLineJoin', strokeLineJoin,
        defaultValue: StrokeLineJoin.miter));
    properties.add(
        DoubleProperty('strokeMiterLimit', strokeMiterLimit, defaultValue: 4));
    properties.add(
        EnumProperty('fillType', fillType, defaultValue: FillType.nonZero));
  }

  @override
  Iterable<StyleProperty> get _localUsedStyles => _usedStyles;
  @override
  Iterable<StyleProperty> get _usedStyles => [
        if (pathData.styled != null) pathData.styled!,
        if (fillColor?.styled != null) fillColor!.styled!,
        if (strokeColor?.styled != null) strokeColor!.styled!,
        if (strokeWidth.styled != null) strokeWidth.styled!,
        if (strokeAlpha.styled != null) strokeAlpha.styled!,
        if (fillAlpha.styled != null) fillAlpha.styled!,
        if (trimPathStart.styled != null) trimPathStart.styled!,
        if (trimPathEnd.styled != null) trimPathEnd.styled!,
        if (trimPathOffset.styled != null) trimPathOffset.styled!,
      ];
}
