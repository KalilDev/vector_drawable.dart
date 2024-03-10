import 'dart:developer';
import 'dart:math';

import 'package:vector_drawable_core/model.dart';
import 'package:vector_drawable_core/parsing.dart';
import 'package:vector_drawable_from_svg/src/model/svg_vector_drawable.dart';
import 'package:vector_drawable_from_svg/src/parsing/utils.dart';
import 'package:vector_math/vector_math_64.dart';
import 'package:xml/xml.dart';

import 'parent_data.dart';

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

SvgChildOutlet _parseSvgRect(
  XmlElement element,
  ParentData parentData, {
  bool isRoot = false,
}) {
  final idAndLabel = idAndLabelForElement(element, generatedPrefix: 'Rect');
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
  final BasicTransformContext transformContext;
  if (isRoot) {
    // the parent data is an identity matrix and there is no group on top to save us, transform using the root transform.
    transformContext = parentData.rootTransformContext;
  } else {
    transformContext = BasicTransformContext.identity();
  }
  transformContext.save();
  const kTransform = 'transform';
  final transform = element
          .getAttribute(kTransform)
          ?.mapSelfTo(TransformOrTransformList.parse) ??
      Transform.none;
  transform.applyToProxy(transformContext);

  transformContext.transformPoint(tl);
  final width = element.getAttribute(kWidth)!.mapSelfTo(double.parse);
  final height = element.getAttribute(kHeight)!.mapSelfTo(double.parse);
  final br = Vector2(x + width, y + height);
  transformContext.transformPoint(br);
  transformContext.restore();

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

SvgGroup _parseSvgGroup(
  XmlElement element,
  ParentData parentData, {
  bool isRoot = false,
}) {
  const kTransform = 'transform';
  final idAndLabel = idAndLabelForElement(element, generatedPrefix: 'Group');
  final localParentData = parentDataForGroupFromTransformString(
      element.getAttribute(kTransform), parentData, idAndLabel);
  final BasicTransformContext transformContextEncodedInTheElement;
  {
    final localTransformContext = localParentData.getTransformContextLocal();
    if (isRoot) {
      final localTransformContextWithRootApplied =
          parentData.rootTransformContext.clone();
      localTransformContext.transformList
          .applyToProxy(localTransformContextWithRootApplied);
      // we are gonna save the root transform multiplied by the root to the group values
      transformContextEncodedInTheElement =
          localTransformContextWithRootApplied;
    } else {
      // we are gonna save the local transform
      transformContextEncodedInTheElement = localTransformContext;
    }
  }
  return svgGroupFromTransformAndChildren(
    transformContextEncodedInTheElement.transformList,
    idAndLabel: idAndLabel,
    children: element.childElements
        .whereIsSupportedSvgElement()
        .map((el) => _parseSvgPathOrGroupOrRect(el, localParentData))
        .toList(),
  );
}

SvgPath _parseSvgPath(
  XmlElement element,
  ParentData parentData, {
  bool isRoot = false,
}) {
  const kStyle = 'style';
  const kData = 'd';
  const kTransform = 'transform';
  final style = element.getAttribute(kStyle)!;
  final data = element.getAttribute(kData)!;
  final transform = element.getAttribute(kTransform);
  final BasicTransformContext transformContext;
  final double Function(double) scaleStrokeWidth;
  if (isRoot) {
    transformContext = parentData.rootTransformContext.clone();
    scaleStrokeWidth = (stroke) => stroke / transformContext.getScalarScale();
  } else {
    transformContext = BasicTransformContext.identity();
    scaleStrokeWidth = (stroke) => stroke;
  }
  final idAndLabel = idAndLabelForElement(element, generatedPrefix: 'Path');
  var pathData = PathData.fromString(data);

  final pathTransforms = TransformOrTransformList.parse(transform);
  transformContext.save();
  pathTransforms.applyToProxy(transformContext);
  pathData = transformContext.transformPath(pathData);
  transformContext.restore();
  final pathStyle = parsePathStyle(
    style,
    parentStyles: parentData.styles,
    scaleStrokeWidth: scaleStrokeWidth,
  );
  final svgPath = svgPathFromStyleAndData(
    pathStyle,
    idAndLabel: idAndLabel,
    pathData: pathData,
  );
  return svgPath;
}

SvgPart _parseSvgPathOrGroupOrRect(
  XmlElement element,
  ParentData parentData, {
  bool isRoot = false,
}) {
  switch (element.name.qualified) {
    case 'g':
      return _parseSvgGroup(
        element,
        parentData,
        isRoot: isRoot,
      );
    case 'path':
      return _parseSvgPath(
        element,
        parentData,
        isRoot: isRoot,
      );
    case 'rect':
      return _parseSvgRect(
        element,
        parentData,
        isRoot: isRoot,
      );
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

  final rootParentData = ParentData.root(IdAndLabel(id, "SVG-ROOT"));

  final viewBox = doc.getAttribute(kViewBox)!;
  final width = doc.getAttribute(kWidth)!.mapSelfTo(double.parse);
  final height = doc.getAttribute(kHeight)!.mapSelfTo(double.parse);
  final vectorDimensionsAndStyle =
      vectorDimensionsAndStyleFrom(viewBox, width, height, dimensionKind);
  if (makeViewportVectorSized) {
    vectorDimensionsAndStyle.applyViewportTransformTo(rootParentData);
  }
  rootParentData.setRootTransform();
  final children = doc.childElements
      .whereIsSupportedSvgElement()
      .map((el) => _parseSvgPathOrGroupOrRect(
            el,
            rootParentData,
            isRoot: true,
          ))
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
