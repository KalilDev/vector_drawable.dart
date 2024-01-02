import 'util.dart';

import '../model/animation.dart';
import 'package:xml/xml.dart';

void _serializeLinearInterpolator(XmlBuilder b, LinearInterpolator node) {
  b.element('linearInterpolator');
}

void _serializePathInterpolator(XmlBuilder b, PathInterpolator node) {
  b.element('pathInterpolator', nest: () {
    b.androidAttribute('pathData', node.pathData);
  });
}

void serializeInterpolator(XmlBuilder b, Interpolator node) {
  b.namespace(kAndroidXmlNamespace, 'android');
  b.namespace(kAaptXmlNamespace, 'aapt');
  if (node is PathInterpolator) {
    _serializePathInterpolator(b, node);
  } else if (node is LinearInterpolator) {
    _serializeLinearInterpolator(b, node);
  } else {
    throw UnimplementedError();
  }
}
