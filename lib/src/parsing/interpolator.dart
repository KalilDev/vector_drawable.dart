import 'package:vector_drawable/src/parsing/util.dart';
import 'package:vector_drawable/vector_drawable.dart';

import '../model/animation.dart';
import 'package:xml/xml.dart';

import 'exception.dart';

LinearInterpolator _parseLinearInterpolator(
    XmlElement node, ResourceReference? source) {
  if (node.name.qualified != 'linearInterpolator') {
    throw ParseException(node, 'is not linearInterpolator');
  }
  return LinearInterpolator();
}

PathInterpolator _parsePathInterpolator(
    XmlElement node, ResourceReference? source) {
  if (node.name.qualified != 'pathInterpolator') {
    throw ParseException(node, 'is not pathInterpolator');
  }
  {
    final pathData =
        node.getAndroidAttribute('pathData')?.map(PathData.fromString);
    if (pathData != null) {
      return PathInterpolator(
        pathData: pathData,
        source: source,
      );
    }
  }
  {
    final cx1 = node.getAndroidAttribute('controlX1')?.map(double.parse),
        cx2 = node.getAndroidAttribute('controlX2')?.map(double.parse),
        cy1 = node.getAndroidAttribute('controlY1')?.map(double.parse),
        cy2 = node.getAndroidAttribute('controlY2')?.map(double.parse);
    if (cx1 != null && cy1 != null && cx2 != null && cy2 != null) {
      return PathInterpolator.cubic(
        controlX1: cx1,
        controlY1: cy1,
        controlX2: cx2,
        controlY2: cy2,
      );
    }
  }
  {
    final cx = node.getAndroidAttribute('controlX')?.map(double.parse),
        cy = node.getAndroidAttribute('controlY')?.map(double.parse);
    if (cx != null && cy != null) {
      return PathInterpolator.quadratic(
        controlX: cx,
        controlY: cy,
      );
    }
  }
  throw ParseException(node, 'is malformed');
}

Interpolator parseInterpolatorElement(
    XmlElement element, ResourceReference? source) {
  switch (element.name.local) {
    case 'pathInterpolator':
      return _parsePathInterpolator(element, source);
    case 'linearInterpolator':
      return _parseLinearInterpolator(element, source);
    default:
      throw UnimplementedError();
  }
}
