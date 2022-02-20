import 'package:flutter/material.dart';
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

extension XmlElementE on XmlElement {
  ResourceOrReference<T>? inlineResourceOrAttribute<T extends Resource>(
    String name, {
    String? namespace,
    required T Function(XmlElement) parse,
  }) =>
      getAttribute(
        name,
        namespace: namespace,
      )?.map(
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

Iterable<XmlElement> _whereIsNotInlineResource(Iterable<XmlElement> elements) =>
    elements.where((e) => !_isAaptAttr(e.name));

extension IterableXmlElementE on Iterable<XmlElement> {
  Iterable<XmlElement> whereIsNotInlineResource() =>
      _whereIsNotInlineResource(this);
}
