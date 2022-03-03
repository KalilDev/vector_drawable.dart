import 'package:vector_drawable/src/model/style.dart';
import 'package:vector_drawable/src/parsing/util.dart';
import 'package:xml/xml.dart';

extension XmlStyleBuilderE on XmlBuilder {
  void styleOrAttribute<T>(
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

  void styleOrAndroidAttribute<T>(
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
