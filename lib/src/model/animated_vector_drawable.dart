import 'package:flutter/material.dart' hide Animation;
import 'package:xml/xml.dart';
import 'package:path_parsing/path_parsing.dart';

import '../parsing/animated_vector_drawable.dart';
import 'animation.dart';
import 'resource.dart';
import 'vector_drawable.dart';

//https://developer.android.com/reference/android/graphics/drawable/AnimatedVectorDrawable
class AnimatedVectorDrawable extends Resource {
  final AnimatedVector body;

  AnimatedVectorDrawable(this.body, ResourceReference? source) : super(source);
  static AnimatedVectorDrawable parseDocument(
          XmlDocument document, ResourceReference source) =>
      parseAnimatedVectorDrawable(document, source);
  static AnimatedVectorDrawable parseElement(XmlElement document) =>
      parseAnimatedVectorDrawable(document, null);
}

abstract class AnimatedVectorDrawableNode {}

class Target extends AnimatedVectorDrawableNode {
  final String name;
  final ResourceOrReference<AnimationResource> animation;

  Target(this.name, this.animation);
}

class AnimatedVector extends AnimatedVectorDrawableNode {
  final ResourceOrReference<VectorDrawable> drawable;
  final List<Target> children;

  AnimatedVector(this.drawable, this.children);
}
