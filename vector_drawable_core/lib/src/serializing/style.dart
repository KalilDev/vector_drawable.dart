import 'package:vector_drawable_core/src/model/style.dart';
import 'package:xml/xml.dart';

import 'util.dart';

extension XmlStyleBuilderE on XmlBuilder {
  void styleOrAttribute<T extends Object>(
    String name,
    StyleOr<T>? value, {
    String Function(T) stringify = StyleOr.defaultStringifyValue,
    String? namespace,
  }) {
    if (value == null) {
      return;
    }
    attribute(
      name,
      value.stringify(stringify),
      namespace: namespace,
      attributeType: XmlAttributeType.DOUBLE_QUOTE,
    );
  }

  void styleOrAndroidAttribute<T extends Object>(
    String name,
    StyleOr<T>? value, {
    String Function(T) stringify = StyleOr.defaultStringifyValue,
  }) {
    if (value == null) {
      return;
    }
    attribute(
      name,
      value.stringify(stringify),
      namespace: kAndroidXmlNamespace,
      attributeType: XmlAttributeType.DOUBLE_QUOTE,
    );
  }
}
