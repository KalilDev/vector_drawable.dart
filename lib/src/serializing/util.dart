import 'dart:ui';

import 'package:xml/xml.dart';
import 'package:xml/src/xml/utils/namespace.dart';

const kAndroidXmlNamespace = 'http://schemas.android.com/apk/res/android';
const kAaptXmlNamespace = 'http://schemas.android.com/aapt';

extension ObjectE<T> on T {
  R map<R>(R Function(T) fn) => fn(this);
}

extension AndroidXmlElementE on XmlElement {
  String? getAndroidAttribute(String name) =>
      getAttribute(name, namespace: kAndroidXmlNamespace);
}

extension AndroidXmlBuilderE on XmlBuilder {
  void androidAttribute(
    String name,
    Object? value,
  ) {
    if (value == null) {
      return;
    }
    attribute(
      name,
      value,
      namespace: kAndroidXmlNamespace,
      attributeType: XmlAttributeType.DOUBLE_QUOTE,
    );
  }
}

String serializeEnum<T extends Enum>(T value) => value.name;

String serializeHexColor(Color color) => '#'
    '${color.alpha.toRadixString(16)}'
    '${color.red.toRadixString(16)}'
    '${color.green.toRadixString(16)}'
    '${color.blue.toRadixString(16)}';
