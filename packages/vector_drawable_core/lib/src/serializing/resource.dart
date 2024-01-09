import 'package:xml/xml.dart';

import '../model/resource.dart';
import 'util.dart';

extension XmlBuilderE on XmlBuilder {
  void inlineResourceOrAttribute<T extends Resource>(
    String name,
    ResourceOrReference<T>? value, {
    String? namespace,
    String? namespacePrefix,
    required void Function(T) serialize,
  }) {
    if ((namespace == null) != (namespacePrefix == null)) {
      throw ArgumentError(
          'When defining an namespace, you MUST define an namespace prefix');
    }
    if (value == null) {
      return;
    }

    if (value.isResolved) {
      element('attr', namespace: kAaptXmlNamespace, nest: () {
        final namespacedName =
            '${namespacePrefix == null ? '' : '$namespacePrefix:'}$name';
        attribute('name', namespacedName);
        serialize(value.resource!);
      });
    } else if (value.isResolvable) {
      attribute(
        name,
        value.reference!,
        namespace: namespace,
        attributeType: XmlAttributeType.DOUBLE_QUOTE,
      );
    }
  }
}
