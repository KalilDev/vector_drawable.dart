import '../model/style.dart';
import 'util.dart';
import 'package:xml/xml.dart';

extension XmlStyleElementE on XmlElement {
  StyleOr<T>? getStyleOrAttribute<T extends Object>(
    String name, {
    String? namespace,
    required T Function(String) parse,
  }) =>
      getAttribute(
        name,
        namespace: namespace,
      )?.mapSelfTo(
        (attr) => StyleOr.parse(attr, parse),
      );
  StyleOr<T>? getStyleOrAndroidAttribute<T extends Object>(
    String name, {
    required T Function(String) parse,
    T? defaultValue,
  }) =>
      getAttribute(
        name,
        namespace: kAndroidXmlNamespace,
      )?.mapSelfTo(
        (attr) => StyleOr.parse(attr, parse),
      ) ??
      defaultValue?.mapSelfTo(StyleOr.value);
}
