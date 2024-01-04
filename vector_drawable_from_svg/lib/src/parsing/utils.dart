import 'dart:io';
import 'dart:math';

import 'package:vector_drawable_core/model.dart';
import 'package:vector_drawable_core/parsing.dart';
import 'package:vector_drawable_core/serializing.dart';
import 'package:vector_drawable_from_svg/src/model/svg_vector_drawable.dart';
import 'package:vector_math/vector_math.dart'
    show
        Vector3,
        Matrix,
        Matrix4,
        Vector4,
        Vector2,
        degrees2Radians,
        radians2Degrees;
import 'package:xml/xml.dart';
import 'package:path_parsing/src/path_parsing.dart';
import 'package:path_parsing/src/path_segment_type.dart';

const kInkscapeXmlNamespace = 'http://www.inkscape.org/namespaces/inkscape';
const kSodipodiXmlNamespace =
    'http://sodipodi.sourceforge.net/DTD/sodipodi-0.dtd';
const kSvgXmlNamespace = 'http://www.w3.org/2000/svg';
const kGlobalNamespace = kSvgXmlNamespace;
const kRdfXmlNamespace = 'http://www.w3.org/1999/02/22-rdf-syntax-ns#';
const kCcXmlNamespace = 'http://creativecommons.org/ns#';
const kDcXmlNamespace = 'http://purl.org/dc/elements/1.1/';

class AffineMatrix {
  final Matrix4 _matrix;
  AffineMatrix(
    double a,
    double b,
    double c,
    double d,
    double e,
    double f, [
    double? m4_10,
  ]) : _matrix = Matrix4.fromList([
          a, b, 0, 0, //
          c, d, 0, 0, //
          0, 0, m4_10 ?? (1.0 * a), 0, //
          e, f, 0, 1.0, //
        ]);
  factory AffineMatrix.identity() => AffineMatrix(1, 0, 0, 1, 0, 0);
  double get a => _matrix.row0[0];
  double get b => _matrix.row1[0];
  double get c => _matrix.row0[1];
  double get d => _matrix.row1[1];
  double get e => _matrix.row0[3];
  double get f => _matrix.row1[3];

  AffineMatrix clone() => AffineMatrix.identity()..setFromOther(this);

  /// Calculates the scale for a stroke width based on the average of the x- and
  /// y-axis scales of this matrix.
  double scaleStrokeWidth(double width) {
    if (a == 1 && d == 1) {
      return width;
    }

    final double xScale = sqrt(a * a + c * c);
    final double yScale = sqrt(b * b + d * d);

    return (xScale + yScale) / 2 * width;
  }

  void _rotateRadians(double radians) {
    _matrix.rotateZ(radians);
  }

  void _setFromOther(AffineMatrix other) {
    _matrix.setFrom(other._matrix);
  }

  void setFromOther(AffineMatrix other) {
    _setFromOther(other);
  }

  void translate(Vector2 offset) {
    // final translated = offset.clone();
    // scalePoint(translated);
    // print(translated);
    // final col = _matrix.getColumn(3);
    // col.x = translated.x;
    // col.y = translated.y;
    // _matrix.setColumn(3, col);

    final lastCol = Vector4(offset.x, offset.y, 0, 1);
    final translationMatrix = Matrix4.identity()..setColumn(3, lastCol);
    translationMatrix.multiply(_matrix);
    _matrix.setFrom(translationMatrix);
  }

  double get _m4_10 => _matrix.row2[2];

  void multiply(AffineMatrix other) {
    _matrix.multiply(other._matrix);
  }

  void rotate(double radians, [Vector2? center]) {
    if (center == null) {
      _rotateRadians(radians);
      return;
    }
    _matrix.multiply(Matrix4_rotation(radians, center));
  }

  String toCssString() {
    String n(double d) => d.toStringAsFixed(4);
    return 'matrix(${n(a)}, ${n(b)}, ${n(c)}, ${n(d)}, ${n(e)}, ${n(f)}) // _m4_10 = ${n(_m4_10)}';
  }

  void transformPoint(Vector2 point) {
    final temp = Vector4(point.x, point.y, 1, 1);
    _matrix.transform(temp);
    point.x = temp.x;
    point.y = temp.y;
  }

  void scalePoint(Vector2 point) {
    final temp = Vector4(point.x, point.y, 0, 0);
    _matrix.transform(temp);
    point.x = temp.x;
    point.y = temp.y;
  }

  @override
  String toString() => '''
[ $a, $c, $e ]
[ $b, $d, $f ]
[ 0.0, 0.0, ${_matrix.row3[3]} ] // _m4_10 = $_m4_10
''';

  /// Creates a new affine matrix rotated by `x` and `y`.
  ///
  /// If `y` is not specified, it is defaulted to the same value as `x`.
  void scale(double x, [double? y]) {
    y ??= x;
    if (x == 1 && y == 1) {
      return;
    }
    final scaleVec = Vector4(x, y, x, x);
    final scaled = Matrix4.identity()..setDiagonal(scaleVec);
    _matrix.multiply(scaled);
  }
}

typedef StyleMap = Map<String, String>;

extension ObjectMapE<T extends Object> on T {
  R mapSelfTo<R>(R Function(T) fn) => fn(this);
}

extension InkscapeXmlElementE on XmlElement {
  String? getInkscapeAttribute(String name) =>
      getAttribute(name, namespace: kInkscapeXmlNamespace);
}

extension SvgXmlElementE on XmlElement {
  String? getSvgAttribute(String name) =>
      getAttribute(name, namespace: kSvgXmlNamespace);
}

class PathStyle {
  final VectorColor fillColor;
  final VectorColor strokeColor;
  final double strokeWidth;
  final double strokeAlpha;
  final double fillAlpha;
  final double trimPathStart;
  final double trimPathEnd;
  final double trimPathOffset;
  final StrokeLineCap strokeLineCap; // default: StrokeLineCap.butt
  final StrokeLineJoin strokeLineJoin; // default: StrokeLineJoin.miter
  final double strokeMiterLimit; // default: 4.0
  final FillType fillType; // default: FillType.nonZero

  PathStyle(
    this.fillColor,
    this.strokeColor,
    this.strokeWidth,
    this.strokeAlpha,
    this.fillAlpha,
    this.trimPathStart,
    this.trimPathEnd,
    this.trimPathOffset,
    this.strokeLineCap,
    this.strokeLineJoin,
    this.strokeMiterLimit,
    this.fillType,
  );
}

void _parseTransformMatrix(String transform, ParentData localParentData) {
  assert(transform.startsWith('matrix('));
  assert(transform.endsWith(')'));
  // Assuming the matrix string is in the form "matrix(a, b, c, d, e, f)"
  final matrixString = transform.substring(7, transform.length - 1);
  List<double> values = matrixString
      .split(",")
      .map((str) => str.trim())
      .map(double.parse)
      .toList();

  final a = values[0];
  final b = values[1];
  final c = values[2];
  final d = values[3];
  final tx = values[4];
  final ty = values[5];
  assert(values.length == 6);
  localParentData.multiplyBy(
    AffineMatrix(a, b, c, d, tx, ty),
  );
}

void _parseTransformRotate(String transform, ParentData localParentData) {
  assert(transform.startsWith('rotate('));
  assert(transform.endsWith(')'));
  // Assuming the matrix string is in the form "(a, b, c)"
  final matrixString = transform.substring(7, transform.length - 1);
  List<double> values = matrixString
      .split(",")
      .map((str) => str.trim())
      .map(double.parse)
      .toList();

  if (values.length == 3) {
    final a = values[0];
    final b = values[1];
    final c = values[2];
    localParentData.rotate(a * degrees2Radians, Vector2(b, c));
  } else {
    assert(values.length == 1);
    final a = values[0];
    localParentData.rotate(a * degrees2Radians);
  }
}

void _parseTransformTranslate(String transform, ParentData localParentData) {
  assert(transform.startsWith('translate('));
  assert(transform.endsWith(')'));
  // Assuming the matrix string is in the form "(a, b)"
  final matrixString = transform.substring(10, transform.length - 1);
  List<double> values = matrixString
      .split(",")
      .map((str) => str.trim())
      .map(double.parse)
      .toList();

  final a = values[0];
  final b = values[1];
  assert(values.length == 2);

  double translateX = a;
  double translateY = b;

  localParentData.translateBy(Vector2(translateX, translateY));
}

void parseTransform(String transform, ParentData localParentData) {
  if (transform.startsWith('matrix(')) {
    _parseTransformMatrix(transform, localParentData);
    return;
  }
  if (transform.startsWith('rotate(')) {
    _parseTransformRotate(transform, localParentData);
    return;
  }
  if (transform.startsWith('translate(')) {
    _parseTransformTranslate(transform, localParentData);
    return;
  }
  throwUnimplemented('unsuported transform "$transform"');
}

extension on StyleMap {
  T? parseValue<T extends Object>(
    String name, {
    required T? Function(String) parse,
    T Function()? ifAbsent,
  }) =>
      containsKey(name) ? parse(remove(name)!) : ifAbsent?.call();
  T parseValueDefault<T extends Object>(
    String name, {
    required T? Function(String) parse,
    required T defaultValue,
  }) =>
      containsKey(name) ? parse(remove(name)!) ?? defaultValue : defaultValue;
}

T? Function(String) returnNullOnNone<T extends Object>(
        T? Function(String) parse) =>
    (input) => input == 'none' ? null : parse(input);

T? Function(String) returnNullWhenOtherThingIsNone<T extends Object>(
        String? otherThing, T? Function(String) parse) =>
    returnValueWhenOtherThingIsNone(otherThing, parse, value: null);
T? Function(String) returnValueWhenOtherThingIsNone<T extends Object>(
        String? otherThing, T? Function(String) parse,
        {required T? value}) =>
    (input) => otherThing == 'none' ? value : parse(input);

// Copy and pasted
StrokeLineCap? _parseStrokeLineCap(String text) =>
    parseEnum(text, StrokeLineCap.values);
StrokeLineJoin? _parseStrokeLineJoin(String text) =>
    parseEnum(text, StrokeLineJoin.values);
FillType? _parseFillType(String text) => parseEnum(text, FillType.values);

double parseDoubleIgnoreMeasure(String dbl) {
  const parse = double.parse;
  const measures = ['px'];
  for (final measure in measures) {
    if (dbl.endsWith(measure)) {
      dbl = dbl.substring(0, dbl.length - measure.length);
      return parse(dbl);
    }
  }
  return parse(dbl);
}

T whenNone<T extends Object>(String? otherString,
        {required T none, required T notNone}) =>
    otherString == 'none' ? none : notNone;
PathStyle parsePathStyle(String pathStyle, ParentData parentData) {
  var styles = stylesFromStyleString(pathStyle);
  styles = mergeStylesWithParent(styles, parentData.styles);
  const kFillColor = 'fill';
  const kFillOpacity = 'fill-opacity';
  const kFillType = 'fill-type';

  const kStrokeColor = 'stroke';
  const kStrokeWidth = 'stroke-width';
  const kStrokeOpacity = 'stroke-opacity';
  const kStrokeLineCap = 'stroke-linecap';
  const kStrokeLineJoin = 'stroke-linejoin';
  const kStrokeMiterLimit = 'stroke-miterlimit';
  //const kOpacity = 'opacity';

  const kTrimPathStart = 'trim-path-start';
  const kTrimPathEnd = 'trim-path-end';
  const kTrimPathOffset = 'trim-path-offset';

  final fillColorString = styles[kFillColor];
  final fillColor = styles.parseValueDefault(
    kFillColor,
    parse: returnNullOnNone(parseHexColor),
    defaultValue: VectorColor.transparent,
  );
  final fillOpacity = styles.parseValueDefault(
    kFillOpacity,
    parse: returnValueWhenOtherThingIsNone(fillColorString, double.parse,
        value: 0.0),
    defaultValue: whenNone(fillColorString, none: 0.0, notNone: 1.0),
  );
  final fillType = styles.parseValueDefault(
    kFillType,
    parse: _parseFillType,
    defaultValue: FillType.nonZero,
  );

  final strokeColorString = styles[kStrokeColor];
  final strokeColor = styles.parseValueDefault(
    kStrokeColor,
    parse: returnNullOnNone(parseHexColor),
    defaultValue: VectorColor.transparent,
  );
  final strokeOpacity = styles.parseValueDefault(
    kStrokeOpacity,
    parse: returnNullWhenOtherThingIsNone(strokeColorString, double.parse),
    defaultValue: whenNone(strokeColorString, none: 0.0, notNone: 0.0),
  );
  var strokeWidth = styles.parseValueDefault(
    kStrokeWidth,
    parse: parseDoubleIgnoreMeasure,
    defaultValue: 0.0,
  );
  final strokeLineCap = styles.parseValueDefault(
    kStrokeLineCap,
    parse: _parseStrokeLineCap,
    defaultValue: StrokeLineCap.butt,
  );
  final strokeLineJoin = styles.parseValueDefault(
    kStrokeLineJoin,
    parse: _parseStrokeLineJoin,
    defaultValue: StrokeLineJoin.miter,
  );
  final strokeMiterLimit = styles.parseValueDefault(
    kStrokeMiterLimit,
    parse: parseDoubleIgnoreMeasure,
    defaultValue: 4.0,
  );
  final trimPathStart = styles.parseValueDefault(
    kTrimPathStart,
    parse: double.parse,
    defaultValue: 0.0,
  );
  final trimPathEnd = styles.parseValueDefault(
    kTrimPathEnd,
    parse: double.parse,
    defaultValue: 1.0,
  );
  final trimPathOffset = styles.parseValueDefault(
    kTrimPathOffset,
    parse: double.parse,
    defaultValue: 0.0,
  );

  strokeWidth = parentData.scaleStrokeWidth(strokeWidth);
  return PathStyle(
    fillColor,
    strokeColor,
    strokeWidth,
    strokeOpacity,
    fillOpacity,
    trimPathStart,
    trimPathEnd,
    trimPathOffset,
    strokeLineCap,
    strokeLineJoin,
    strokeMiterLimit,
    fillType,
  );
}

Path pathFromStyleAndData(
  PathStyle style, {
  String? name,
  required PathData pathData,
}) =>
    Path(
      name: name,
      pathData: pathData.asStyle,
      fillColor: style.fillColor.asStyle,
      strokeColor: style.strokeColor.asStyle,
      strokeWidth: style.strokeWidth.asStyle,
      strokeAlpha: style.strokeAlpha.asStyle,
      fillAlpha: style.fillAlpha.asStyle,
      trimPathStart: style.trimPathStart.asStyle,
      trimPathEnd: style.trimPathEnd.asStyle,
      trimPathOffset: style.trimPathOffset.asStyle,
      strokeLineCap: style.strokeLineCap,
      strokeLineJoin: style.strokeLineJoin,
      strokeMiterLimit: style.strokeMiterLimit,
      fillType: style.fillType,
    );

Group groupFromTransformAndChildren(
  ParentData parentData, {
  String? name,
  required List<VectorPart> children,
}) =>
    Group(
      name: name,
      children: children,
    );

SvgPath svgPathFromStyleAndData(
  PathStyle style, {
  required IdAndLabel idAndLabel,
  required PathData pathData,
}) {
  final path = pathFromStyleAndData(
    style,
    name: idAndLabel.id,
    pathData: pathData,
  );
  return SvgPath(idAndLabel, path);
}

SvgPath svgPathFromStyleStringAndData(
  String styleString, {
  required IdAndLabel idAndLabel,
  required PathData pathData,
  required ParentData parentData,
  required String? pathTransformString,
}) {
  parentData.pushPathTransform(pathTransformString);
  final res = svgPathFromStyleAndData(
    parsePathStyle(styleString, parentData),
    idAndLabel: idAndLabel,
    pathData: parentData.multiplyPath(pathData),
  );
  parentData.popPathTransform(pathTransformString);
  return res;
}

SvgGroup svgGroupFromTransformAndChildren(
  ParentData localParentData, {
  required IdAndLabel idAndLabel,
  required List<SvgPathOrGroup> children,
}) {
  final group = groupFromTransformAndChildren(
    localParentData,
    name: idAndLabel.id,
    children: children.map((e) => e.part).toList(),
  );
  final labels = SvgNameMapping.empty();
  labels.addChildren(children);
  return SvgGroup(idAndLabel, labels, group);
}

ParentData parentDataForGroupFromTransformString(
    String? transformString, ParentData parentData, IdAndLabel idAndLabel) {
  final localParentData = parentData.cloneForChild(idAndLabel);
  if (transformString != null) {
    parseTransform(transformString, localParentData);
    localParentData.lockTransform();
  }
  return localParentData;
}

SvgGroup svgGroupFromTransformStringAndChildren(
  ParentData localParentData, {
  required IdAndLabel idAndLabel,
  required List<SvgPathOrGroup> children,
}) =>
    svgGroupFromTransformAndChildren(
      localParentData,
      idAndLabel: idAndLabel,
      children: children,
    );

class VectorDimensionsAndStyle {
  final Dimension width;
  final Dimension height;
  final double viewportX;
  final double viewportY;
  final double viewportWidth;
  final double viewportHeight;
  final VectorColor tint;
  final TintMode tintMode;
  final bool autoMirrored;
  final double opacity;

  VectorDimensionsAndStyle(
    this.width,
    this.height,
    this.viewportX,
    this.viewportY,
    this.viewportWidth,
    this.viewportHeight,
    this.tint,
    this.tintMode,
    this.autoMirrored,
    this.opacity,
  );
  void applyViewportTransformTo(ParentData parentData) {
    const EPSILON = 0.0001;
    if ((viewportX.abs() > EPSILON) || (viewportY.abs() > EPSILON)) {
      parentData.translateBy(Vector2(viewportX, viewportY));
    }
    final widthScale = width.value / viewportWidth;
    final heightScale = height.value / viewportHeight;
    if (((widthScale - 1.0).abs() > EPSILON) ||
        ((heightScale - 1.0).abs() > EPSILON)) {
      parentData.scaleBy(Vector2(widthScale, heightScale));
    }
  }
}

Matrix4 Matrix4_rotation(double radians, Vector2 pivot) {
  final cosTheta = cos(radians);
  final sinTheta = sin(radians);
  final pivotX = pivot.x;
  final pivotY = pivot.y;

  return Matrix4.columns(
    Vector4(
      cosTheta,
      sinTheta,
      0,
      0,
    ),
    Vector4(
      -sinTheta,
      cosTheta,
      0,
      0,
    ),
    Vector4(
      0,
      0,
      (1.0 * cosTheta), // a
      0,
    ),
    Vector4(
      pivotX * (1 - cosTheta) + pivotY * sinTheta,
      pivotY * (1 - cosTheta) - pivotX * sinTheta,
      0,
      1,
    ),
  );
}

Vector vectorFromVectorDimensionsAndStyleAndChildren(
        VectorDimensionsAndStyle dimensionsAndStyle,
        {required String name,
        required List<VectorPart> children,
        required bool makeViewportVectorSized}) =>
    Vector(
      width: dimensionsAndStyle.width,
      height: dimensionsAndStyle.height,
      viewportWidth: makeViewportVectorSized
          ? dimensionsAndStyle.width.value
          : dimensionsAndStyle.viewportWidth,
      viewportHeight: makeViewportVectorSized
          ? dimensionsAndStyle.height.value
          : dimensionsAndStyle.viewportHeight,
      tint: dimensionsAndStyle.tint.asStyle,
      tintMode: dimensionsAndStyle.tintMode,
      autoMirrored: dimensionsAndStyle.autoMirrored,
      opacity: dimensionsAndStyle.opacity.asStyle,
      children: children,
    );
VectorDimensionsAndStyle vectorDimensionsAndStyleFrom(
  String viewBox,
  double width,
  double height,
  DimensionKind dimensionKind,
) {
  final vb = viewBox.split(' ').map((e) => e.trim()).map(double.parse).toList();
  assert(vb[0] == 0.0);
  assert(vb[1] == 0.0);
  final viewportWidth = vb[2];
  final viewportHeight = vb[3];

  final widthDim = Dimension(width, dimensionKind);
  final heightDim = Dimension(height, dimensionKind);
  return VectorDimensionsAndStyle(
    widthDim,
    heightDim,
    vb[0],
    vb[1],
    viewportWidth,
    viewportHeight,
    VectorColor.transparent, // tint
    TintMode.srcIn, // tintMode
    false, // autoMirrored
    1.0, // opacity
  );
}

SvgVector svgVectorFromVectorDimensionsAndStyleAndChildren(
    VectorDimensionsAndStyle dimensionsAndStyle,
    {required String id,
    required List<SvgPathOrGroup> children,
    required bool makeViewportVectorSized}) {
  final vector = vectorFromVectorDimensionsAndStyleAndChildren(
    dimensionsAndStyle,
    name: id,
    children: children.map((e) => e.part).toList(),
    makeViewportVectorSized: makeViewportVectorSized,
  );
  final labels = SvgNameMapping.empty();
  labels.addChildren(children);
  return SvgVector(vector, labels);
}

@Deprecated("TODO")
Never throwUnimplemented([String? message]) =>
    throw UnimplementedError(message);

bool _isSvgElement(XmlName name) => name.namespaceUri == kSvgXmlNamespace;
bool _isSupportedSvgTag(String tag) {
  const supportedTags = {'g', 'path'};
  return supportedTags.contains(tag);
}

bool _isSupportedSvgElement(XmlName name) =>
    name.namespaceUri == kSvgXmlNamespace && _isSupportedSvgTag(name.local);

Iterable<XmlElement> _whereIsSvgElement(Iterable<XmlElement> elements) =>
    elements.where((e) => _isSvgElement(e.name));
Iterable<XmlElement> _whereIsSupportedSvgElement(
        Iterable<XmlElement> elements) =>
    elements.where((e) {
      final supported = _isSupportedSvgElement(e.name);
      if (!supported) {
        print("unsupported ${e.name}");
        print(e.namespaceUri);
        print(e.name.local);
      }
      return supported;
    });

extension WhereIsSvgXmlElementE on Iterable<XmlElement> {
  Iterable<XmlElement> whereIsSvgElement() => _whereIsSvgElement(this);
  Iterable<XmlElement> whereIsSupportedSvgElement() =>
      _whereIsSupportedSvgElement(this);
}

StyleMap stylesFromStyleString(String styleString) {
  if (styleString.isEmpty) {
    return {};
  }
  final list = styleString.split(';').map((e) => e.trim());
  final tuples = list.map((e) => e.split(':'));
  final mapEntries = tuples.map((tpl) => MapEntry(tpl[0], tpl[1]));
  return Map.fromEntries(mapEntries);
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

void _copySegmentInto(PathSegmentData source, PathSegmentData target) => target
  ..command = source.command
  ..targetPoint = source.targetPoint
  ..point1 = source.point1
  ..point2 = source.point2
  ..arcSweep = source.arcSweep
  ..arcLarge = source.arcLarge;

class ParentData {
  final IdAndLabel current;
  final ParentData? previous;
  final StyleMap styles;
  final AffineMatrix _transform;

  ParentData(this.current, this.previous, this.styles,
      [AffineMatrix? transform])
      : _transform = transform?.clone() ?? AffineMatrix.identity();
  bool _isTransformLocked = false;
  void lockTransform() => _isTransformLocked = true;

  Iterable<ParentData> get previousParentDatasReversed sync* {
    var it = previous;
    while (it != null) {
      yield it;
      it = it.previous;
    }
  }

  Iterable<ParentData> get previousParentDatas =>
      previousParentDatasReversed.toList().reversed;

  Iterable<ParentData> get parentDatas =>
      previousParentDatas.followedBy([this]);

  Iterable<IdAndLabel> get groups => parentDatas.map((e) => e.current);

  ParentData cloneForChild(IdAndLabel newCurrent) =>
      ParentData(newCurrent, this, {...styles}, _transform);
  PathSegmentData _multiplySegment(PathSegmentData segment) {
    final newSegment = PathSegmentData();
    _copySegmentInto(segment, newSegment);
    void mulP1() {
      final point = Vector2(segment.point1.dx, segment.point1.dy);
      _transform.transformPoint(point);
      newSegment.point1 = _pathOffset(point.x, point.y);
    }

    void mulP2() {
      final point = Vector2(segment.point2.dx, segment.point2.dy);
      _transform.transformPoint(point);
      newSegment.point2 = _pathOffset(point.x, point.y);
    }

    void mulTarget() {
      final point = Vector2(segment.targetPoint.dx, segment.targetPoint.dy);
      _transform.transformPoint(point);
      newSegment.targetPoint = _pathOffset(point.x, point.y);
    }

    switch (segment.command) {
      case SvgPathSegType.unknown:
      case SvgPathSegType.close:
        return segment;
      case SvgPathSegType.lineToHorizontalAbs:
        mulTarget();
        return newSegment;
      case SvgPathSegType.lineToVerticalAbs:
        mulTarget();
        return newSegment;
      case SvgPathSegType.moveToAbs:
      case SvgPathSegType.moveToRel:
      case SvgPathSegType.lineToAbs:
      case SvgPathSegType.smoothQuadToAbs:
        mulTarget();
        return newSegment;
      case SvgPathSegType.cubicToAbs:
        mulP1();
        mulP2();
        mulTarget();
        return newSegment;
      case SvgPathSegType.quadToAbs:
        mulP1();
        mulTarget();
        return newSegment;
      case SvgPathSegType.smoothCubicToAbs:
        mulP2();
        mulTarget();
        return newSegment;
      case SvgPathSegType.arcToAbs:
        mulP1();
        mulTarget();
        return newSegment;
      case SvgPathSegType.smoothCubicToRel:
      case SvgPathSegType.arcToRel:
      case SvgPathSegType.quadToRel:
      case SvgPathSegType.cubicToRel:
      case SvgPathSegType.smoothQuadToRel:
      case SvgPathSegType.lineToRel:
      case SvgPathSegType.lineToVerticalRel:
      case SvgPathSegType.lineToHorizontalRel:
        return segment;
    }
  }

  static Never _throwLocked() => throw StateError("Fuck youuuu");
  void multiplyBy(AffineMatrix mat) {
    _multiplyBy(mat);
    _appendTransformString(
        'matrix(${mat.a} ${mat.b} ${mat.c} ${mat.d} ${mat.e} ${mat.f})');
  }

  void _multiplyBy(AffineMatrix matrix) {
    if (_isTransformLocked) {
      _throwLocked();
    }
    _transform.multiply(matrix);
  }

  void _scaleBy(Vector2 scale) {
    if (_isTransformLocked) {
      _throwLocked();
    }
    _transform.scale(scale.x, scale.y);
  }

  void scaleBy(Vector2 scale) {
    _scaleBy(scale);
    _appendTransformString('scale(${scale.x} ${scale.y})');
  }

  void translateBy(Vector2 vector2) {
    _translateBy(vector2);
    _appendTransformString('translate(${vector2.x} ${vector2.y})');
  }

  void _translateBy(Vector2 vector2) {
    if (_isTransformLocked) {
      _throwLocked();
    }
    _transform.translate(vector2);
  }

  void rotate(double radians, [Vector2? center]) {
    _rotate(radians, center);
    _appendTransformString(
        'rotate(${radians * radians2Degrees}${center?.x.mapSelfTo((x) => ' $x') ?? ''}${center?.x.mapSelfTo((y) => ' $y') ?? ''})');
  }

  void _appendTransformString(String s) => _currTransformString.isEmpty
      ? _currTransformString = s
      : _currTransformString += ' $s';

  void _rotate(double radians, [Vector2? center]) {
    if (_isTransformLocked) {
      _throwLocked();
    }
    _transform.rotate(radians, center);
  }

  String get pathString =>
      groups.map((e) => '${e.label ?? ''}[${e.id}]').join('>');
  String _currTransformString = '';
  String get currTransformString => _currTransformString;
  String get transformStrings =>
      parentDatas.map((e) => e.currTransformString).join('>');

  final List<AffineMatrix> _savedTransforms = [];
  void saveTransform() {
    _savedTransforms.add(_transform.clone());
  }

  void restoreTransform() {
    _transform.setFromOther(_savedTransforms.removeLast());
  }

  double scaleStrokeWidth(double width) => _transform.scaleStrokeWidth(width);

  void pushPathTransform(String? pathTransformString) {
    if (pathTransformString != null) {
      saveTransform();
      parseTransform(pathTransformString, this);
    }
  }

  void popPathTransform(String? pathTransformString) {
    if (pathTransformString != null) {
      restoreTransform();
    }
  }

  static bool printMatrix = true;
  PathData multiplyPath(PathData path) {
    final simplifiedPath =
        PathData.fromString(path.toSimplifiedPathDataString());
    final transformedPath = PathData.fromString(
        segmentsToPathString(simplifiedPath.segments.map(_multiplySegment)));
    return transformedPath;
  }

  void extractStylesFromElement(XmlElement element) {
    const kStyle = 'style';
    final newStyles =
        element.getAttribute(kStyle)?.mapSelfTo(stylesFromStyleString);
    styles.addAll(newStyles ?? const {});
  }
}

StyleMap mergeStylesWithParent(StyleMap styles, StyleMap parentStyles) => {
      ...parentStyles,
      ...styles,
    };
