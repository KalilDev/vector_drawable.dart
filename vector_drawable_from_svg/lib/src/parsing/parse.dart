import 'dart:math';

import 'package:vector_drawable_core/model.dart';
import 'package:vector_drawable_core/parsing.dart';
import 'package:vector_drawable_from_svg/src/model/svg_vector_drawable.dart';
import 'package:vector_drawable_from_svg/src/parsing/utils.dart';
import 'package:vector_math/vector_math.dart';
import 'package:xml/xml.dart';

int _generationIndex = 0;
String _generateName(String prefix) => "$prefix-${++_generationIndex}";
IdAndLabel idAndLabelForElement(XmlElement element,
    {required String generatedPrefix}) {
  const kId = 'id';
  const kLabel = 'label';
  const kLabelNs = kInkscapeXmlNamespace;
  return IdAndLabel(
    element.getAttribute(kId) ?? _generateName(generatedPrefix),
    element.getAttribute(kLabel, namespace: kLabelNs),
  );
}

Map<String, String> extractStylesAndMergeWithParent(
    XmlElement element, Map<String, String> parentStyles) {
  const kStyle = 'style';
  final style = element.getAttribute(kStyle);
  if (style == null) {
    return {};
  }
  return mergeStylesWithParent(stylesFromStyleString(style), parentStyles);
}

SvgChildOutlet _parseSvgRect(XmlElement element, ParentData parentData) {
  final idAndLabel = idAndLabelForElement(element, generatedPrefix: 'Group');
  if (idAndLabel.id != 'ChildOutlet') {
    throw UnimplementedError('Only rect outlets are supported');
  }

  const kX = 'x';
  const kY = 'y';
  const kWidth = 'width';
  const kHeight = 'height';
  final x = element.getAttribute(kX)?.mapSelfTo(double.parse) ?? 0.0;
  final y = element.getAttribute(kY)?.mapSelfTo(double.parse) ?? 0.0;
  final tl = Vector2(x, y);
  parentData.transformPoint(tl);
  final width = element.getAttribute(kWidth)!.mapSelfTo(double.parse);
  final height = element.getAttribute(kHeight)!.mapSelfTo(double.parse);
  final br = Vector2(x + width, y + height);
  parentData.transformPoint(br);

  final l = min(tl.x, br.x);
  final t = min(tl.y, br.y);
  final r = max(tl.x, br.x);
  final b = max(tl.y, br.y);
  return SvgChildOutlet(
    idAndLabel,
    ChildOutlet(
      name: idAndLabel.id,
      x: Value(l),
      y: Value(t),
      width: Value(r - l),
      height: Value(b - t),
    ),
  );
}

SvgGroup _parseSvgGroup(XmlElement element, ParentData parentData) {
  const kTransform = 'transform';
  final idAndLabel = idAndLabelForElement(element, generatedPrefix: 'Group');
  final localParentData = parentDataForGroupFromTransformString(
      element.getAttribute(kTransform), parentData, idAndLabel);
  localParentData.extractStylesFromElement(element);
  return svgGroupFromTransformStringAndChildren(
    localParentData,
    idAndLabel: idAndLabel,
    children: element.childElements
        .whereIsSupportedSvgElement()
        .map((el) => _parseSvgPathOrGroupOrRect(el, localParentData))
        .toList(),
  );
}

SvgPath _parseSvgPath(XmlElement element, ParentData parentData) {
  const kStyle = 'style';
  const kData = 'd';
  const kTransform = 'transform';
  final style = element.getAttribute(kStyle)!;
  final data = element.getAttribute(kData)!;
  final transform = element.getAttribute(kTransform);
  return svgPathFromStyleStringAndData(
    style,
    idAndLabel: idAndLabelForElement(element, generatedPrefix: 'Group'),
    pathData: PathData.fromString(data),
    parentData: parentData,
    pathTransformString: transform,
  );
}

SvgPart _parseSvgPathOrGroupOrRect(XmlElement element, ParentData parentData) {
  switch (element.name.qualified) {
    case 'g':
      return _parseSvgGroup(element, parentData);
    case 'path':
      return _parseSvgPath(element, parentData);
    case 'rect':
      return _parseSvgRect(element, parentData);
    default:
      print(element.name.qualified);
      throw UnimplementedError();
  }
}

SvgVectorDrawable parseSvgIntoVectorDrawable(
  XmlElement doc,
  ResourceReference? source, {
  required DimensionKind dimensionKind,
  bool makeViewportVectorSized = true,
}) {
  if (doc.name.qualified != 'svg') {
    throw ParseException(doc, 'is not svg');
  }

  const kViewBox = 'viewBox';
  const kWidth = 'width';
  const kHeight = 'height';
  const kId = 'id';
  final id = doc.getAttribute(kId)!;

  final rootParentData = ParentData(IdAndLabel(id, "SVG-ROOT"), null, {});

  final viewBox = doc.getAttribute(kViewBox)!;
  final width = doc.getAttribute(kWidth)!.mapSelfTo(double.parse);
  final height = doc.getAttribute(kHeight)!.mapSelfTo(double.parse);
  final vectorDimensionsAndStyle =
      vectorDimensionsAndStyleFrom(viewBox, width, height, dimensionKind);
  if (makeViewportVectorSized) {
    vectorDimensionsAndStyle.applyViewportTransformTo(rootParentData);
  }
  rootParentData.lockTransform();

  final children = doc.childElements
      .whereIsSupportedSvgElement()
      .map((el) => _parseSvgPathOrGroupOrRect(el, rootParentData))
      .toList();

  print(children);

  final svgVector = svgVectorFromVectorDimensionsAndStyleAndChildren(
    vectorDimensionsAndStyle,
    id: id,
    children: children,
    makeViewportVectorSized: makeViewportVectorSized,
  );
  final vectorDrawable = VectorDrawable(svgVector.vector, source);
  return SvgVectorDrawable(vectorDrawable, svgVector.labels);
}
