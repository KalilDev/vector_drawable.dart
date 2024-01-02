import 'package:xml/xml.dart';
// ignore: implementation_imports
import 'package:xml/src/xml/utils/namespace.dart';

import '../model/resource.dart';
import 'util.dart';

ResourceOrReference<T>? _parseInlineResource<T extends Resource>(
  String name, {
  String? namespace,
  required XmlElement element,
  required T Function(XmlElement) parse,
}) {
  // TODO: improve this
  final namespacePrefix =
      namespace == null ? '' : '${lookupNamespacePrefix(element, namespace)}:';
  final qualifiedName = '$namespacePrefix$name';
  return element.childElements
      .cast<XmlElement?>()
      .singleWhere(
          (e) =>
              _isAaptAttr(e!.name) && e.getAttribute('name') == qualifiedName,
          orElse: () => null)
      ?.mapSelfTo((e) => parse(e.childElements.single))
      .mapSelfTo(ResourceOrReference.resource);
}

extension XmlElementE on XmlElement {
  ResourceOrReference<T>? inlineResourceOrAttribute<T extends Resource>(
    String name, {
    String? namespace,
    required T Function(XmlElement) parse,
  }) =>
      getAttribute(
        name,
        namespace: namespace,
      )?.mapSelfTo(
        ResourceOrReference.parseReference<T>,
      ) ??
      _parseInlineResource(
        name,
        namespace: namespace,
        element: this,
        parse: parse,
      );

  Iterable<XmlElement> get realChildElements =>
      childElements.whereIsNotInlineResource();
}

bool _isAaptAttr(XmlName name) =>
    name.namespaceUri == kAaptXmlNamespace && name.local == 'attr';
