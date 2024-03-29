import 'package:vector_drawable_core/model.dart';
import 'package:vector_drawable_core/parsing.dart';
import 'package:xml/xml.dart';

import '../model/animated_vector_drawable.dart';
import '../model/animation.dart';

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
        XmlElement doc, ResourceReference? source) =>
    AnimatedVectorDrawable(
      _parseAnimatedVector(doc),
      source,
    );
