import 'package:flutter/material.dart' hide Animation;
import 'package:vector_drawable/src/parsing/resource.dart';
import 'package:vector_drawable/src/serializing/resource.dart';
import 'package:xml/xml.dart';
import 'package:path_parsing/path_parsing.dart';

import '../model/animated_vector_drawable.dart';
import '../model/animation.dart';
import '../model/resource.dart';
import '../model/vector_drawable.dart';
import 'animation.dart';
import 'exception.dart';
import 'util.dart';

void _serializeAnimatedVector(XmlBuilder b, AnimatedVector node) {
  b.element('animated-vector', nest: () {
    b.inlineResourceOrAttribute<VectorDrawable>(
      'drawable',
      node.drawable,
      namespace: kAndroidXmlNamespace,
      namespacePrefix: 'android',
      serialize: (v) => VectorDrawable.serializeElement(b, v),
    );
    for (final child in node.children) {
      _serializeTarget(b, child);
    }
  });
}

void _serializeTarget(XmlBuilder b, Target node) {
  b.element('target', nest: () {
    b.androidAttribute('name', node.name);
    b.inlineResourceOrAttribute<AnimationResource>(
      'animation',
      node.animation,
      namespace: kAndroidXmlNamespace,
      namespacePrefix: 'android',
      serialize: (r) => AnimationResource.serializeElement(b, r),
    );
  });
}

void serializeAnimatedVectorDrawable(XmlBuilder b, AnimatedVectorDrawable doc) {
  b.namespace(kAndroidXmlNamespace, 'android');
  b.namespace(kAaptXmlNamespace, 'aapt');
  _serializeAnimatedVector(b, doc.body);
  b.namespace(kAndroidXmlNamespace, 'android');
  b.namespace(kAaptXmlNamespace, 'aapt');
}
