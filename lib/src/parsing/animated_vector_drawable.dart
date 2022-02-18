import 'package:flutter/material.dart' hide Animation;
import 'package:md3_clock/widgets/animated_vector/parsing/resource.dart';
import 'package:xml/xml.dart';
import 'package:path_parsing/path_parsing.dart';

import '../model/animated_vector_drawable.dart';
import '../model/animation.dart';
import '../model/resource.dart';
import '../model/vector_drawable.dart';
import 'animation.dart';
import 'exception.dart';
import 'util.dart';

AnimatedVector _parseAnimatedVector(XmlElement node) {
  if (node.name.qualified != 'animated-vector') {
    throw ParseException(node, 'is not animated-vector');
  }

  return AnimatedVector(
    node.inlineResourceOrAttribute(
      'drawable',
      namespace: kAndroidXmlNamespace,
      parse: VectorDrawable.parseElement,
    )!,
    node.realChildElements.map(_parseTarget).toList(),
  );
}

Target _parseTarget(XmlElement node) {
  if (node.name.qualified != 'target') {
    throw ParseException(node, 'is not animated-vector');
  }
  return Target(
    node.getAndroidAttribute('name')!,
    node.inlineResourceOrAttribute(
      'animation',
      namespace: kAndroidXmlNamespace,
      parse: AnimationResource.parseElement,
    )!,
  );
}

AnimatedVectorDrawable parseAnimatedVectorDrawable(
        XmlHasChildren doc, ResourceReference? source) =>
    AnimatedVectorDrawable(
      _parseAnimatedVector(doc.childElements.single),
      source,
    );
