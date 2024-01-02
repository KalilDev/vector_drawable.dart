import 'dart:collection';
import 'package:path_parsing/path_parsing.dart';

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

// In Android VectorDrawables, it is common for vectors to end with an c instead
// of an z, and in the android impl the path gets closed with an error, but with
// the current path package the path is not parsed and an error is thrown. To
// mitigate this, we must remove the trailing c
String _removeTrailingCubic(String s) {
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

enum _PathDataInputType { string, segments, emitter }

abstract class PathEmitter {
  void emitTo(PathProxy proxy);
}

class PathData {
  PathData.fromString(String asString)
      : _stringInput = _removeTrailingCubic(asString),
        _segmentsInput = null,
        _emitterInput = null,
        _inputType = _PathDataInputType.string;
  PathData.fromSegments(Iterable<PathSegmentData> segments)
      : _stringInput = null,
        _segmentsInput = UnmodifiableListView(segments.toList()),
        _emitterInput = null,
        _inputType = _PathDataInputType.segments;
  PathData.fromEmitter(PathEmitter emitter,
      {bool iKnowThatIWillGenerateBogusResultsIfITryToLerpThisPathDataWithAnyOtherPathDataOrReadItsSegments =
          false})
      : _stringInput = null,
        _segmentsInput = null,
        _emitterInput = emitter,
        _inputType = _PathDataInputType.emitter,
        assert(
            iKnowThatIWillGenerateBogusResultsIfITryToLerpThisPathDataWithAnyOtherPathDataOrReadItsSegments);
  final String? _stringInput;
  final UnmodifiableListView<PathSegmentData>? _segmentsInput;
  final PathEmitter? _emitterInput;
  final _PathDataInputType _inputType;

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

  late final UnmodifiableListView<PathSegmentData> segments = () {
    switch (_inputType) {
      case _PathDataInputType.string:
        return UnmodifiableListView(_parse(_stringInput!));
      case _PathDataInputType.segments:
        return _segmentsInput!;
      case _PathDataInputType.emitter:
        return UnmodifiableListView(const <PathSegmentData>[]);
    }
  }();

  void emitTo(PathProxy proxy) {
    if (_inputType == _PathDataInputType.emitter) {
      _emitterInput!.emitTo(proxy);
      return;
    }
    final normalizer = SvgPathNormalizer();
    for (final seg in segments) {
      _emitSegmentWithoutMutation(seg, proxy, normalizer);
    }
  }

  static lerp(PathData a, PathData b, double t) {
    if (a._inputType == _PathDataInputType.emitter ||
        b._inputType == _PathDataInputType.emitter) {
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
