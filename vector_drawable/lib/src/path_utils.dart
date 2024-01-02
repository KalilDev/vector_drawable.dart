import 'dart:collection';
import 'dart:math';
import 'dart:ui';
import 'package:vector_math/vector_math_64.dart';
import 'package:path_parsing/path_parsing.dart';
// ignore: implementation_imports
import 'package:path_parsing/src/path_segment_type.dart';

import 'package:vector_drawable_core/vector_drawable_core.dart';

void _copySegmentInto(PathSegmentData source, PathSegmentData target) => target
  ..command = source.command
  ..targetPoint = source.targetPoint
  ..point1 = source.point1
  ..point2 = source.point2
  ..arcSweep = source.arcSweep
  ..arcLarge = source.arcLarge;

extension PathDataAdditionalOps on PathData {
  Offset evaluateAt(double t) =>
      PathDataAdditionalData.forPath(this).evaluateAt(t);

  PathData segmentsFrom(double t0, double t1) => t0 == 0 && t1 == 1
      ? this
      : PathDataAdditionalData.forPath(this).segmentsFrom(t0, t1);
}

class PathDataAdditionalData {
  factory PathDataAdditionalData.createFromPath(PathData path) {
    final computer = _PathCubicWriter.empty();
    path.emitTo(computer);
    return PathDataAdditionalData._(computer);
  }
  factory PathDataAdditionalData.forPath(PathData path) =>
      getOrCreateAdditionalDataFromPathData(path);
  final _PathCubicWriter _computer;

  static final _expando =
      Expando<PathDataAdditionalData>('PathDataAdditionalDataExpando');

  PathDataAdditionalData._(this._computer);

  Offset evaluateAt(double t) {
    return _computer.eval(t);
  }

  PathData segmentsFrom(double t0, double t1) {
    if (t0 == 0 && t1 == 1) {
      throw Error();
    }
    if (t0 == t1) {
      return PathData.fromSegments([]);
    }
    final selectedSegments = _computer.segmentsFrom(t0, t1);
    return PathData.fromEmitter(
      _PathCubicWriter.from(selectedSegments),
      iKnowThatIWillGenerateBogusResultsIfITryToLerpThisPathDataWithAnyOtherPathDataOrReadItsSegments:
          hellYeahBaby_ImDoingThisToReuseCodeWithoutHavingFlutterCodeOrDuplicationInMyGeneralPurposeVDLibrary,
    );
  }
}

const hellYeahBaby_ImDoingThisToReuseCodeWithoutHavingFlutterCodeOrDuplicationInMyGeneralPurposeVDLibrary =
    true;

extension ExpandoPutIfAbsent<T extends Object> on Expando<T> {
  T putIfAbsent(Object obj, T Function() ifAbsent) {
    final res = this[obj];
    if (res != null) {
      return res;
    }
    return this[obj] = ifAbsent();
  }
}

PathDataAdditionalData getOrCreateAdditionalDataFromPathData(PathData path) =>
    PathDataAdditionalData._expando
        .putIfAbsent(path, () => PathDataAdditionalData.createFromPath(path));

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

class _PathCubicWriter implements PathProxy, PathEmitter {
  final List<StandaloneCubic> _cubics;
  Offset _current = Offset.zero;
  Offset _start = Offset.zero;

  _PathCubicWriter.empty() : _cubics = [];
  _PathCubicWriter.from(this._cubics);
  late final UnmodifiableListView<PathSegmentData> segments =
      UnmodifiableListView<PathSegmentData>(_toSegments());

  @override
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
