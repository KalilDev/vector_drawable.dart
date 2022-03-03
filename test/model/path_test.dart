import 'package:flutter_test/flutter_test.dart';
import 'package:vector_drawable/src/model/path.dart';
import 'dart:collection';

import 'package:path_parsing/path_parsing.dart';
import 'package:path_parsing/src/path_segment_type.dart';
import 'package:meta/meta.dart';

void main() {
  test('pathData from string', () {
    final p = PathData.fromString('M0 0L0 1 Z');
    final segments = p.segments;
    {
      final m = segments[0];
      expect(m.command, SvgPathSegType.moveToAbs);
      expect(m.targetPoint.dx, 0);
      expect(m.targetPoint.dy, 0);
    }
    {
      final l = segments[1];
      expect(l.command, SvgPathSegType.lineToAbs);
      expect(l.targetPoint.dx, 0);
      expect(l.targetPoint.dy, 1);
    }
    {
      final z = segments[2];
      expect(z.command, SvgPathSegType.close);
    }
  });
  test('_PathOffset unit', () {
    expect(unitPathOffset.dx, 1);
    expect(unitPathOffset.dy, 1);
    expect(unitXPathOffset.dx, 1);
    expect(unitXPathOffset.dy, 0);
    expect(unitYPathOffset.dx, 0);
    expect(unitYPathOffset.dy, 1);
  });
  test('pathData to string', () {
    final pathOffsetZero = unitPathOffset * 0;
    final p = PathData.fromSegments([
      PathSegmentData()
        ..command = SvgPathSegType.moveToAbs
        ..targetPoint = pathOffsetZero,
      PathSegmentData()
        ..command = SvgPathSegType.lineToAbs
        ..targetPoint = unitYPathOffset,
      PathSegmentData()..command = SvgPathSegType.close,
    ]);
    final string = p.asString;
    expect(string, 'M0.0 0.0 L0.0 1.0 Z ');
  });
  test('pathData eval simple line', () {
    final p = PathData.fromString('M0.0 0.0 L0.0 1.0 Z');
    final start = p.evaluateAt(0.0);
    final halfStart = p.evaluateAt(0.25);
    final cubicEnd = p.evaluateAt(0.5);
    final halfEnd = p.evaluateAt(0.75);
    final end = p.evaluateAt(1.0);
    expect(start.dx, closeTo(0.0, EPSILON));
    expect(start.dy, closeTo(0.0, EPSILON));
    expect(halfStart.dx, closeTo(0.0, EPSILON));
    expect(halfStart.dy, closeTo(0.5, EPSILON));
    expect(halfEnd.dx, closeTo(0.0, EPSILON));
    expect(halfEnd.dy, closeTo(0.5, EPSILON));
    expect(cubicEnd.dx, closeTo(0.0, EPSILON));
    expect(cubicEnd.dy, closeTo(1, EPSILON));
    expect(end.dx, closeTo(0.0, EPSILON));
    expect(end.dy, closeTo(0.0, EPSILON));
  });
  test('pathData eval simple cubic', () {
    final p = PathData.fromString('M 0 0 C 1 0 0 1 1 1');
    final start = p.evaluateAt(0.0);
    final center = p.evaluateAt(0.5);
    final end = p.evaluateAt(1.0);
    expect(start.dx, closeTo(0.0, EPSILON));
    expect(start.dy, closeTo(0.0, EPSILON));
    expect(center.dx, closeTo(0.5, EPSILON));
    expect(center.dy, closeTo(0.5, EPSILON));
    expect(end.dx, closeTo(1.0, EPSILON));
    expect(end.dy, closeTo(1.0, EPSILON));

    // https://www.desmos.com/calculator/ebdtbxgbq0?lang=pt-BR
    final p1 = p.evaluateAt(0.25);
    final p2 = p.evaluateAt(0.75);
    expect(p1.dx, closeTo(0.4375, EPSILON));
    expect(p1.dy, closeTo(0.15625, EPSILON));
    expect(p2.dx, closeTo(0.5625, EPSILON));
    expect(p2.dy, closeTo(0.8438, EPSILON));
  });
  test('pathData cubic cutting', () {
    final p =
        PathData.fromString('M 0 0 C 1 0 0 1 1 1').segmentsFrom(0.25, 0.75);
    final start = p.evaluateAt(0.0);
    final center = p.evaluateAt(0.5);
    final end = p.evaluateAt(1.0);
    expect(start.dx, closeTo(0.4375, EPSILON));
    expect(start.dy, closeTo(0.15625, EPSILON));
    expect(center.dx, closeTo(0.5, EPSILON));
    expect(center.dy, closeTo(0.5, EPSILON));
    expect(end.dx, closeTo(0.5625, EPSILON));
    expect(end.dy, closeTo(0.8438, EPSILON));

    // https://www.desmos.com/calculator/ebdtbxgbq0?lang=pt-BR
    final p1 = p.evaluateAt(0.25);
    final p2 = p.evaluateAt(0.75);
    expect(p1.dx, closeTo(0.4922, EPSILON));
    expect(p1.dy, closeTo(0.3164, EPSILON));
    expect(p2.dx, closeTo(0.5078, EPSILON));
    expect(p2.dy, closeTo(0.6836, EPSILON));
  });
  test('pathData from cubic segments without move', () {
    final p = PathData.fromCubicSegments([
      StandaloneCubic(Offset.zero, Offset(1, 0), Offset(0, 1), Offset(1, 1)),
      StandaloneCubic(Offset(1, 1), Offset(2, 0), Offset(0, 2), Offset(2, 2)),
    ]);
    expect(p.asString, 'C1.0 0.0 0.0 1.0 1.0 1.0 C2.0 0.0 0.0 2.0 2.0 2.0 ');
  });
  test('pathData from cubic segments with move', () {
    final p = PathData.fromCubicSegments([
      StandaloneCubic(Offset(1, 1), Offset(2, 0), Offset(0, 2), Offset(2, 2)),
    ]);
    expect(p.asString, 'M1.0 1.0 C2.0 0.0 0.0 2.0 2.0 2.0 ');
  });
  test('pathSegmentData lerp', () {
    // Only in local closures the return type is inferred, instead of being
    // dynamic.
    pathOffset(double x, double y) =>
        (unitXPathOffset * x) + (unitYPathOffset * y);
    final p0 = PathSegmentData()
      ..command = SvgPathSegType.unknown
      ..point1 = pathOffset(0, 0)
      ..point2 = pathOffset(1, 1)
      ..targetPoint = pathOffset(2, 2)
      ..arcSweep = false
      ..arcLarge = false;
    final p1 = PathSegmentData()
      ..command = SvgPathSegType.cubicToAbs
      ..point1 = pathOffset(1, 1)
      ..point2 = pathOffset(2, 2)
      ..targetPoint = pathOffset(3, 3)
      ..arcSweep = true
      ..arcLarge = true;

    void ensureSegsDidntMutate() {
      expect(p0.command, SvgPathSegType.unknown);
      expect(p0.point1.dx, 0.0);
      expect(p0.point1.dy, 0.0);
      expect(p0.point2.dx, 1.0);
      expect(p0.point2.dy, 1.0);
      expect(p0.targetPoint.dx, 2.0);
      expect(p0.targetPoint.dy, 2.0);
      expect(p0.arcSweep, false);
      expect(p0.arcLarge, false);

      expect(p1.command, SvgPathSegType.cubicToAbs);
      expect(p1.point1.dx, 1.0);
      expect(p1.point1.dy, 1.0);
      expect(p1.point2.dx, 2.0);
      expect(p1.point2.dy, 2.0);
      expect(p1.targetPoint.dx, 3.0);
      expect(p1.targetPoint.dy, 3.0);
      expect(p1.arcSweep, true);
      expect(p1.arcLarge, true);
    }

    // ensure they were initialized correctly
    ensureSegsDidntMutate();
    {
      final t = 0.0;
      final lp0 = lerpPathSegment(p0, p1, t);
      ensureSegVals(
        lp0,
        t < 0.5 ? SvgPathSegType.unknown : SvgPathSegType.cubicToAbs,
        Offset.lerp(Offset(0, 0), Offset(1, 1), t)!,
        Offset.lerp(Offset(1, 1), Offset(2, 2), t)!,
        Offset.lerp(Offset(2, 2), Offset(3, 3), t)!,
        t < 0.5 ? false : true,
        t < 0.5 ? false : true,
      );
      ensureSegsDidntMutate();
    }
    {
      final t = 0.25;
      final lp1_4 = lerpPathSegment(p0, p1, t);
      ensureSegVals(
        lp1_4,
        t < 0.5 ? SvgPathSegType.unknown : SvgPathSegType.cubicToAbs,
        Offset.lerp(Offset(0, 0), Offset(1, 1), t)!,
        Offset.lerp(Offset(1, 1), Offset(2, 2), t)!,
        Offset.lerp(Offset(2, 2), Offset(3, 3), t)!,
        t < 0.5 ? false : true,
        t < 0.5 ? false : true,
      );
      ensureSegsDidntMutate();
    }
    {
      final t = 0.5;
      final lp1_2 = lerpPathSegment(p0, p1, t);
      ensureSegVals(
        lp1_2,
        t > 0.5 ? SvgPathSegType.unknown : SvgPathSegType.cubicToAbs,
        Offset.lerp(Offset(0, 0), Offset(1, 1), t)!,
        Offset.lerp(Offset(1, 1), Offset(2, 2), t)!,
        Offset.lerp(Offset(2, 2), Offset(3, 3), t)!,
        t < 0.5 ? false : true,
        t < 0.5 ? false : true,
      );
      ensureSegsDidntMutate();
    }
    {
      final t = 0.75;
      final lp3_4 = lerpPathSegment(p0, p1, t);
      ensureSegVals(
        lp3_4,
        t < 0.5 ? SvgPathSegType.unknown : SvgPathSegType.cubicToAbs,
        Offset.lerp(Offset(0, 0), Offset(1, 1), t)!,
        Offset.lerp(Offset(1, 1), Offset(2, 2), t)!,
        Offset.lerp(Offset(2, 2), Offset(3, 3), t)!,
        t < 0.5 ? false : true,
        t < 0.5 ? false : true,
      );
      ensureSegsDidntMutate();
    }
    {
      final t = 1.0;
      final lp1 = lerpPathSegment(p0, p1, t);
      ensureSegVals(
        lp1,
        t < 0.5 ? SvgPathSegType.unknown : SvgPathSegType.cubicToAbs,
        Offset.lerp(Offset(0, 0), Offset(1, 1), t)!,
        Offset.lerp(Offset(1, 1), Offset(2, 2), t)!,
        Offset.lerp(Offset(2, 2), Offset(3, 3), t)!,
        t < 0.5 ? false : true,
        t < 0.5 ? false : true,
      );
      ensureSegsDidntMutate();
    }
  });
  test('pathData lerp', () {
    // This path is complex, featuring arcs, to ensure that the path data is
    // lerped with the same commands, instead of converting to an intermediary
    // cubic, because doing so could make the paths not morphed, for example,
    // in cases where an arc doesnt generate the same cubic sequence, as the
    // case here, where one arc is really a line and the other is an half
    // circle.
    final p0 = PathData.fromString('M 0 0 L 1 2 Z A 1 0 0 0 0 2 0');
    final p1 = PathData.fromString('M 0 0 L -1 -2 Z A 1 1 0 0 0 2 0');
    final p = PathData.lerp(p0, p1, 0.5);
    expect(p.asString, 'M0.0 0.0 L0.0 0.0 Z A1.0 0.5 0.0 0 0 2.0 0.0 ');
  });
}

void ensureSegVals(
  PathSegmentData seg,
  SvgPathSegType command,
  Offset p1,
  Offset p2,
  Offset target,
  bool sweep,
  bool large,
) {
  expect(seg.command, command);
  expect(seg.point1.dx, closeTo(p1.dx, EPSILON));
  expect(seg.point1.dy, closeTo(p1.dy, EPSILON));
  expect(seg.point2.dx, closeTo(p2.dx, EPSILON));
  expect(seg.point2.dy, closeTo(p2.dy, EPSILON));
  expect(seg.targetPoint.dx, closeTo(target.dx, EPSILON));
  expect(seg.targetPoint.dy, closeTo(target.dy, EPSILON));
  expect(seg.arcSweep, sweep);
  expect(seg.arcLarge, large);
}

const double EPSILON = 0.0001;
