import 'package:vector_drawable/src/parsing/util.dart';
import 'package:vector_drawable/vector_drawable.dart';

import '../model/animation.dart';
import 'package:xml/xml.dart';

import 'exception.dart';

PathInterpolator _parsePathInterpolator(
    XmlElement node, ResourceReference? source) {
  if (node.name.qualified != 'pathInterpolator') {
    throw ParseException(node, 'is not pathInterpolator');
  }
  return PathInterpolator(
    pathData: node.getAndroidAttribute('pathData')!.map(PathData.fromString),
    source: source,
  );
}

Interpolator parseInterpolatorElement(
    XmlElement element, ResourceReference? source) {
  switch (element.name.local) {
    case 'pathInterpolator':
      return _parsePathInterpolator(element, source);
    default:
      throw UnimplementedError();
  }
}
