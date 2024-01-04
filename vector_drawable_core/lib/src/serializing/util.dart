import 'package:xml/xml.dart';

import '../model/color.dart';
import '../parsing_and_serializing_commons.dart';
export '../parsing_and_serializing_commons.dart';

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

String serializeHexColor(VectorColor color) => '#'
    //'${color.alpha.toRadixString(16).padLeft(2, '0')}'
    '${color.red.toRadixString(16).padLeft(2, '0')}'
    '${color.green.toRadixString(16).padLeft(2, '0')}'
    '${color.blue.toRadixString(16).padLeft(2, '0')}';
