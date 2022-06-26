import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:path_parsing/path_parsing.dart';
import 'package:path_parsing/src/path_segment_type.dart';

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

PathSegmentData lerpPathSegment(
  PathSegmentData a,
  PathSegmentData b,
  double t,
) {
  return PathSegmentData()
    ..command = t < 0.5 ? a.command : b.command
    ..targetPoint = a.targetPoint + (b.targetPoint - a.targetPoint) * t
    ..point1 = a.point1 + (b.point1 - a.point1) * t
    ..point2 = a.point2 + (b.point2 - a.point2) * t
    ..arcSweep = t < 0.5 ? a.arcSweep : b.arcSweep
    ..arcLarge = t < 0.5 ? a.arcLarge : b.arcLarge;
}

String _commandToString(SvgPathSegType command) {
  switch (command) {
    case SvgPathSegType.unknown:
      return 'UNKNOWN';
    case SvgPathSegType.close:
      return 'Z';
    case SvgPathSegType.moveToAbs:
      return 'M';
    case SvgPathSegType.moveToRel:
      return 'm';
    case SvgPathSegType.lineToAbs:
      return 'L';
    case SvgPathSegType.lineToRel:
      return 'l';
    case SvgPathSegType.cubicToAbs:
      return 'C';
    case SvgPathSegType.cubicToRel:
      return 'c';
    case SvgPathSegType.quadToAbs:
      return 'Q';
    case SvgPathSegType.quadToRel:
      return 'q';
    case SvgPathSegType.arcToAbs:
      return 'A';
    case SvgPathSegType.arcToRel:
      return 'a';
    case SvgPathSegType.lineToHorizontalAbs:
      return 'H';
    case SvgPathSegType.lineToHorizontalRel:
      return 'h';
    case SvgPathSegType.lineToVerticalAbs:
      return 'V';
    case SvgPathSegType.lineToVerticalRel:
      return 'v';
    case SvgPathSegType.smoothCubicToAbs:
      return 'S';
    case SvgPathSegType.smoothCubicToRel:
      return 's';
    case SvgPathSegType.smoothQuadToAbs:
      return 'T';
    case SvgPathSegType.smoothQuadToRel:
      return 't';
  }
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
    while (parser.hasMoreData) {
      try {
        result.add(parser.parseSegment());
      } catch (e) {
        print(e);
      }
    }
    return result;
  }

  static lerp(PathData a, PathData b, double t) {
    final aSegments = a.segments;
    final bSegments = b.segments;
    return PathData.fromSegments([
      for (var i = 0; i < aSegments.length; i++)
        lerpPathSegment(aSegments[i], bSegments[i], t)
    ]);
  }

  static String _toString(List<PathSegmentData> segments) {
    final result = StringBuffer();
    void writeCommand(PathSegmentData data) {
      result.write(_commandToString(data.command));
    }

    void writeP1(PathSegmentData data) {
      result.write(data.point1.dx);
      result.write(' ');
      result.write(data.point1.dy);
      result.write(' ');
    }

    void writeP2(PathSegmentData data) {
      result.write(data.point2.dx);
      result.write(' ');
      result.write(data.point2.dy);
      result.write(' ');
    }

    void writeTarget(PathSegmentData data) {
      result.write(data.targetPoint.dx);
      result.write(' ');
      result.write(data.targetPoint.dy);
      result.write(' ');
    }

    void writeFlag(bool data) {
      result.write(data ? 1 : 0);
      result.write(' ');
    }

    void writeSegment(PathSegmentData data) {
      writeCommand(data);
      switch (data.command) {
        default:
      }
      switch (data.command) {
        case SvgPathSegType.unknown:
        case SvgPathSegType.close:
          result.write(' ');
          return;
        case SvgPathSegType.lineToHorizontalAbs:
        case SvgPathSegType.lineToHorizontalRel:
          result.write(data.targetPoint.dx);
          return;
        case SvgPathSegType.lineToVerticalAbs:
        case SvgPathSegType.lineToVerticalRel:
          result.write(data.targetPoint.dy);
          return;
        case SvgPathSegType.moveToAbs:
        case SvgPathSegType.moveToRel:
        case SvgPathSegType.lineToAbs:
        case SvgPathSegType.lineToRel:
        case SvgPathSegType.smoothQuadToAbs:
        case SvgPathSegType.smoothQuadToRel:
          writeTarget(data);
          return;
        case SvgPathSegType.cubicToAbs:
        case SvgPathSegType.cubicToRel:
          writeP1(data);
          writeP2(data);
          writeTarget(data);
          return;
        case SvgPathSegType.quadToAbs:
        case SvgPathSegType.quadToRel:
          writeP1(data);
          writeTarget(data);
          return;
        case SvgPathSegType.smoothCubicToAbs:
        case SvgPathSegType.smoothCubicToRel:
          writeP2(data);
          writeTarget(data);
          return;
        case SvgPathSegType.arcToAbs:
        case SvgPathSegType.arcToRel:
          writeP1(data);
          result.write(data.arcAngle);
          result.write(' ');
          writeFlag(data.arcLarge);
          writeFlag(data.arcSweep);
          writeTarget(data);
          return;
      }
    }

    segments.forEach(writeSegment);
    return result.toString();
  }

  UnmodifiableListView<PathSegmentData> get segments =>
      UnmodifiableListView(_segments ??=
          _asString == null ? _finishedComputer!.segments : _parse(_asString!));

  String get asString => _asString ??= _toString(segments);

  String toString() => 'PathData{$asString}';

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

final unitXPathOffset = () {
  final SvgPathStringSource parser = SvgPathStringSource('M 1 0');
  return parser.parseSegment().targetPoint;
}();
final unitPathOffset = () {
  final SvgPathStringSource parser = SvgPathStringSource('M 1 1');
  return parser.parseSegment().targetPoint;
}();
final unitYPathOffset = () {
  final SvgPathStringSource parser = SvgPathStringSource('M 0 1');
  return parser.parseSegment().targetPoint;
}();

class _PathCubicWriter extends PathProxy {
  final List<StandaloneCubic> _cubics;
  Offset _current = Offset.zero;
  Offset _start = Offset.zero;

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
      final evaluated = cubic.eval(t);
      return evaluated;
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
