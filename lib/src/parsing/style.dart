import 'package:vector_drawable/src/model/style.dart';
import 'package:vector_drawable/src/parsing/util.dart';
import 'package:xml/xml.dart';

extension XmlStyleElementE on XmlElement {
  StyleOr<T>? getStyleOrAttribute<T>(
    String name, {
    String? namespace,
    required T Function(String) parse,
  }) =>
      getAttribute(
        name,
        namespace: namespace,
      )?.map(
        (attr) => StyleOr.parse(attr, parse),
      );
  StyleOr<T>? getStyleOrAndroidAttribute<T>(
    String name, {
    required T Function(String) parse,
    T? defaultValue,
  }) =>
      getAttribute(
        name,
        namespace: kAndroidXmlNamespace,
      )?.map(
        (attr) => StyleOr.parse(attr, parse),
      ) ??
      defaultValue?.map(StyleOr.value);
}
