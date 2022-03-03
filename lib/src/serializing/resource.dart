import 'package:flutter/material.dart';
import 'package:vector_drawable/vector_drawable.dart';
import 'package:xml/xml.dart';
import 'package:path_parsing/path_parsing.dart';
import 'package:xml/src/xml/utils/namespace.dart';

import '../model/animation.dart';
import '../model/resource.dart';
import 'animated_vector_drawable.dart';
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
      ?.map((e) => parse(e.childElements.single))
      .map(ResourceOrReference.resource);
}

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

bool _isAaptAttr(XmlName name) =>
    name.namespaceUri == kAaptXmlNamespace && name.local == 'attr';

Iterable<XmlElement> _whereIsNotInlineResource(Iterable<XmlElement> elements) =>
    elements.where((e) => !_isAaptAttr(e.name));

extension IterableXmlElementE on Iterable<XmlElement> {
  Iterable<XmlElement> whereIsNotInlineResource() =>
      _whereIsNotInlineResource(this);
}
