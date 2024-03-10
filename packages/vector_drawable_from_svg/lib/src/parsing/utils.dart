import 'package:vector_drawable_core/model.dart';
import 'package:vector_drawable_core/parsing.dart';
import 'package:vector_drawable_from_svg/src/model/svg_vector_drawable.dart';
import 'package:vector_math/vector_math_64.dart'
    show
        Vector3,
        Matrix3,
        Matrix4,
        Vector4,
        Vector2,
        degrees2Radians,
        radians2Degrees;
import 'package:xml/xml.dart';

import 'parent_data.dart';

const kInkscapeXmlNamespace = 'http://www.inkscape.org/namespaces/inkscape';
const kSodipodiXmlNamespace =
    'http://sodipodi.sourceforge.net/DTD/sodipodi-0.dtd';
const kSvgXmlNamespace = 'http://www.w3.org/2000/svg';
const kGlobalNamespace = kSvgXmlNamespace;
const kRdfXmlNamespace = 'http://www.w3.org/1999/02/22-rdf-syntax-ns#';
const kCcXmlNamespace = 'http://creativecommons.org/ns#';
const kDcXmlNamespace = 'http://purl.org/dc/elements/1.1/';

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
PathStyle parsePathStyle(
  String pathStyle, {
  required double Function(double) scaleStrokeWidth,
  required StyleMap parentStyles,
}) {
  var styles = stylesFromStyleString(pathStyle);
  styles = mergeStylesWithParent(styles, parentStyles);
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
    defaultValue: VectorColor.components(0, 0, 0, 255),
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

  strokeWidth = scaleStrokeWidth(strokeWidth);
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

AffineGroup groupFromTransformAndChildren(
  TransformList transformList, {
  String? name,
  required List<VectorPart> children,
}) {
  return AffineGroup(
    name: name,
    children: children,
    tempTransformList: Value(transformList.transforms.isEmpty
        ? Transform.none
        : transformList.transforms.length == 1
            ? transformList.transforms.single
            : transformList),
  );
}

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

SvgGroup svgGroupFromTransformAndChildren(
  TransformList transformList, {
  required IdAndLabel idAndLabel,
  required List<SvgPart> children,
}) {
  final group = groupFromTransformAndChildren(
    transformList,
    name: idAndLabel.id,
    children: children.map((e) => e.part).toList(),
  );
  final labels = SvgNameMapping.empty();
  labels.addChildren(children.whereType());
  return SvgGroup(idAndLabel, labels, group);
}

ParentData parentDataForGroupFromTransformString(
  String? transformString,
  ParentData parentData,
  IdAndLabel idAndLabel,
) {
  final localParentData = parentData.cloneForChild(idAndLabel);
  if (transformString != null) {
    localParentData.applyTransformString(transformString);
  }
  return localParentData;
}

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
  void applyViewportTransformTo(LegacyTransformProxy transformContext) {
    const EPSILON = 0.0001;
    if ((viewportX.abs() > EPSILON) || (viewportY.abs() > EPSILON)) {
      transformContext.translateBy(Vector2(viewportX, viewportY));
    }
    final widthScale = width.value / viewportWidth;
    final heightScale = height.value / viewportHeight;
    if (((widthScale - 1.0).abs() > EPSILON) ||
        ((heightScale - 1.0).abs() > EPSILON)) {
      transformContext.scaleBy(Vector2(widthScale, heightScale));
    }
  }
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
    required List<SvgPart> children,
    required bool makeViewportVectorSized}) {
  final vector = vectorFromVectorDimensionsAndStyleAndChildren(
    dimensionsAndStyle,
    name: id,
    children: children.map((e) => e.part).toList(),
    makeViewportVectorSized: makeViewportVectorSized,
  );
  print(vector.children);
  final labels = SvgNameMapping.empty();
  labels.addChildren(children.whereType<SvgPathOrGroup>());
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
      var supported = _isSupportedSvgElement(e.name);
      supported |=
          (e.name.namespaceUri == kSvgXmlNamespace && e.name.local == 'rect') &&
              e.getAttribute('id') == 'ChildOutlet';
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
