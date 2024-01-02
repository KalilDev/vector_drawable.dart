import 'package:xml/xml.dart';

import '../parsing/animated_vector_drawable.dart';
import '../serializing/animated_vector_drawable.dart';
import 'animation.dart';
import 'resource.dart';
import 'vector_drawable.dart';

//https://developer.android.com/reference/android/graphics/drawable/AnimatedVectorDrawable
class AnimatedVectorDrawable extends Resource
    implements Clonable<AnimatedVectorDrawable> {
  final AnimatedVector body;

  AnimatedVectorDrawable(this.body, ResourceReference? source) : super(source);
  static AnimatedVectorDrawable parseDocument(
          XmlDocument document, ResourceReference source) =>
      parseAnimatedVectorDrawable(document.rootElement, source);
  static AnimatedVectorDrawable parseElement(XmlElement document) =>
      parseAnimatedVectorDrawable(document, null);

  static XmlDocument serializeDocument(AnimatedVectorDrawable animation) {
    final builder = XmlBuilder();
    serializeElement(builder, animation);
    return builder.buildDocument();
  }

  static void serializeElement(
          XmlBuilder b, AnimatedVectorDrawable animation) =>
      serializeAnimatedVectorDrawable(b, animation);

  @override
  AnimatedVectorDrawable clone() =>
      AnimatedVectorDrawable(body.clone(), source);
}

abstract class AnimatedVectorDrawableNode {}

class Target extends AnimatedVectorDrawableNode implements Clonable<Target> {
  final String name;
  final ResourceOrReference<AnimationResource> animation;

  Target(this.name, this.animation);

  @override
  Target clone() => Target(name, animation.clone());
}

class AnimatedVector extends AnimatedVectorDrawableNode
    implements Clonable<AnimatedVector> {
  final ResourceOrReference<VectorDrawable> drawable;
  final List<Target> children;

  AnimatedVector(this.drawable, this.children);

  @override
  AnimatedVector clone() => AnimatedVector(
        drawable.clone(),
        children.map(cloneAn).toList(),
      );
}
