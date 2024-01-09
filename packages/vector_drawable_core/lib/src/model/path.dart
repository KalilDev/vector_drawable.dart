import 'dart:collection';
import 'package:path_parsing/path_parsing.dart';

import '../serializing/segments.dart';

void _copySegmentInto(PathSegmentData source, PathSegmentData target) => target
  ..command = source.command
  ..targetPoint = source.targetPoint
  ..point1 = source.point1
  ..point2 = source.point2
  ..arcSweep = source.arcSweep
  ..arcLarge = source.arcLarge;
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

final __mutableSegment = PathSegmentData();
void _emitSegmentWithoutMutation(
  PathSegmentData segment,
  PathProxy path,
  SvgPathNormalizer normalizer,
) {
  _copySegmentInto(segment, __mutableSegment);
  normalizer.emitSegment(__mutableSegment, path);
}

enum PathDataInputType { string, segments, emitter }

abstract class PathEmitter {
  void emitTo(PathProxy proxy);
}

final Expando<UnmodifiableListView<PathSegmentData>> _pathDataSegmentsExpando =
    Expando('PathData.segments');

extension ExpandoPutIfAbsent<T extends Object> on Expando<T> {
  T putIfAbsent(Object obj, T Function() ifAbsent) {
    final res = this[obj];
    if (res != null) {
      return res;
    }
    return this[obj] = ifAbsent();
  }
}

class PathData {
  const PathData.fromStringRaw(String asString)
      : _stringInput = asString,
        _segmentsInput = null,
        _emitterInput = null,
        _inputType = PathDataInputType.string;
  factory PathData.fromString(String asString) =>
      PathData.fromStringRaw(removeTrailingCubic(asString));
  // In Android VectorDrawables, it is common for vectors to end with an c instead
// of an z, and in the android impl the path gets closed with an error, but with
// the current path package the path is not parsed and an error is thrown. To
// mitigate this, we must remove the trailing c
  static String removeTrailingCubic(String s) {
    if (s.isEmpty) {
      return s;
    }
    for (var i = s.length - 1; i >= 0; i--) {
      if (s[i] == ' ') continue;
      if (s[i] == 'c' || s[i] == 'C') {
        return String.fromCharCodes(s.codeUnits.take(i));
      }
      return s;
    }
    // the string is just spaces
    return s;
  }

  const PathData.fromSegmentsRaw(UnmodifiableListView<PathSegmentData> segments)
      : _stringInput = null,
        _segmentsInput = segments,
        _emitterInput = null,
        _inputType = PathDataInputType.segments;
  factory PathData.fromSegments(Iterable<PathSegmentData> segments) =>
      PathData.fromSegmentsRaw(UnmodifiableListView(segments.toList()));
  const PathData.fromEmitter(PathEmitter emitter,
      {bool iKnowThatIWillGenerateBogusResultsIfITryToLerpThisPathDataWithAnyOtherPathDataOrReadItsSegments =
          false})
      : _stringInput = null,
        _segmentsInput = null,
        _emitterInput = emitter,
        _inputType = PathDataInputType.emitter,
        assert(
            iKnowThatIWillGenerateBogusResultsIfITryToLerpThisPathDataWithAnyOtherPathDataOrReadItsSegments);
  final String? _stringInput;
  final UnmodifiableListView<PathSegmentData>? _segmentsInput;
  final PathEmitter? _emitterInput;
  final PathDataInputType _inputType;

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

  UnmodifiableListView<PathSegmentData> _buildSegments() {
    switch (_inputType) {
      case PathDataInputType.string:
        return UnmodifiableListView(_parse(_stringInput!));
      case PathDataInputType.segments:
        return _segmentsInput!;
      case PathDataInputType.emitter:
        return UnmodifiableListView(const <PathSegmentData>[]);
    }
  }

  UnmodifiableListView<PathSegmentData> get segments =>
      _pathDataSegmentsExpando.putIfAbsent(this, _buildSegments);

  void emitTo(PathProxy proxy) {
    if (_inputType == PathDataInputType.emitter) {
      _emitterInput!.emitTo(proxy);
      return;
    }
    final normalizer = SvgPathNormalizer();
    for (final seg in segments) {
      _emitSegmentWithoutMutation(seg, proxy, normalizer);
    }
  }

  String toSimplifiedPathDataString() {
    final stringProxy = _StringProxy();
    emitTo(stringProxy);
    final outBuffer = stringProxy.buffer;
    return outBuffer.toString();
  }

  String toPathDataString({bool needsSameInput = false}) {
    switch (_inputType) {
      case PathDataInputType.string:
        return _stringInput!;
      case PathDataInputType.segments:
        if (!needsSameInput) {
          return toSimplifiedPathDataString();
        } else {
          return segmentsToPathString(segments);
        }
      case PathDataInputType.emitter:
        assert(!needsSameInput);
        return toSimplifiedPathDataString();
    }
  }

  PathDataInputType get inputType => _inputType;

  static lerp(PathData a, PathData b, double t) {
    if (a._inputType == PathDataInputType.emitter ||
        b._inputType == PathDataInputType.emitter) {
      assert(false, "i told you not to use the emitter");
      print(
          "oh well, you are running an production build with broken paths. The offending paths are $a and $b");
    }
    final aSegments = a.segments;
    final bSegments = b.segments;
    return PathData.fromSegments([
      for (var i = 0; i < aSegments.length; i++)
        lerpPathSegment(aSegments[i], bSegments[i], t)
    ]);
  }
}

class _StringProxy implements PathProxy {
  final StringBuffer buffer = StringBuffer();
  @override
  void close() {
    buffer.write('z');
  }

  @override
  void cubicTo(
      double x1, double y1, double x2, double y2, double x3, double y3) {
    buffer.write('C$x1 $y1 $x2 $y2 $x3 $y3');
  }

  @override
  void lineTo(double x, double y) {
    buffer.write('L$x $y');
  }

  @override
  void moveTo(double x, double y) {
    buffer.write('M$x $y');
  }
}
