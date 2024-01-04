import 'package:path_parsing/path_parsing.dart';
import 'package:path_parsing/src/path_segment_type.dart';

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

void writeSegmentToPathSegmentStringBuffer(
    PathSegmentData segment, StringBuffer buffer) {
  void writeCommand(PathSegmentData data) {
    buffer.write(_commandToString(data.command));
  }

  void writeP1(PathSegmentData data) {
    buffer.write(data.point1.dx);
    buffer.write(' ');
    buffer.write(data.point1.dy);
    buffer.write(' ');
  }

  void writeP2(PathSegmentData data) {
    buffer.write(data.point2.dx);
    buffer.write(' ');
    buffer.write(data.point2.dy);
    buffer.write(' ');
  }

  void writeTarget(PathSegmentData data) {
    buffer.write(data.targetPoint.dx);
    buffer.write(' ');
    buffer.write(data.targetPoint.dy);
    buffer.write(' ');
  }

  void writeFlag(bool data) {
    buffer.write(data ? 1 : 0);
    buffer.write(' ');
  }

  writeCommand(segment);
  switch (segment.command) {
    case SvgPathSegType.unknown:
    case SvgPathSegType.close:
      buffer.write('');
      return;
    case SvgPathSegType.lineToHorizontalAbs:
    case SvgPathSegType.lineToHorizontalRel:
      buffer.write(segment.targetPoint.dx);
      return;
    case SvgPathSegType.lineToVerticalAbs:
    case SvgPathSegType.lineToVerticalRel:
      buffer.write(segment.targetPoint.dy);
      return;
    case SvgPathSegType.moveToAbs:
    case SvgPathSegType.moveToRel:
    case SvgPathSegType.lineToAbs:
    case SvgPathSegType.lineToRel:
    case SvgPathSegType.smoothQuadToAbs:
    case SvgPathSegType.smoothQuadToRel:
      writeTarget(segment);
      return;
    case SvgPathSegType.cubicToAbs:
    case SvgPathSegType.cubicToRel:
      writeP1(segment);
      writeP2(segment);
      writeTarget(segment);
      return;
    case SvgPathSegType.quadToAbs:
    case SvgPathSegType.quadToRel:
      writeP1(segment);
      writeTarget(segment);
      return;
    case SvgPathSegType.smoothCubicToAbs:
    case SvgPathSegType.smoothCubicToRel:
      writeP2(segment);
      writeTarget(segment);
      return;
    case SvgPathSegType.arcToAbs:
    case SvgPathSegType.arcToRel:
      writeP1(segment);
      buffer.write(segment.arcAngle);
      buffer.write(' ');
      writeFlag(segment.arcLarge);
      writeFlag(segment.arcSweep);
      writeTarget(segment);
      return;
  }
}

String segmentToPathSegmentString(PathSegmentData segment) {
  final buffer = StringBuffer();
  writeSegmentToPathSegmentStringBuffer(segment, buffer);
  return buffer.toString();
}

void writeSegmentsToPathStringBuffer(
    Iterable<PathSegmentData> segments, StringBuffer buffer) {
  for (final segment in segments) {
    writeSegmentToPathSegmentStringBuffer(segment, buffer);
  }
}

String segmentsToPathString(Iterable<PathSegmentData> segments) {
  final buffer = StringBuffer();
  writeSegmentsToPathStringBuffer(segments, buffer);
  return buffer.toString();
}
