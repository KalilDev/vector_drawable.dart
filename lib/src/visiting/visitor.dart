import '../model/animated_vector_drawable.dart';
import '../model/animation.dart';
import '../model/resource.dart';
import '../model/vector_drawable.dart';

abstract class ResourceOrReferenceVisitor<T> {
  T visitResourceOrReference<R extends Resource>(ResourceOrReference<R> node,
      [T? context]);
  T visitResource<R extends Resource>(R node, [T? context]);
  T visitReference(ResourceReference node, [T? context]);
}

abstract class VectorDrawableVisitor<T>
    implements ResourceOrReferenceVisitor<T> {
  T visitVectorDrawable(VectorDrawable node, [T? context]);
  T visitVector(Vector node, [T? context]);
  T visitVectorPart(VectorPart node, [T? context]);
  T visitGroup(Group node, [T? context]);
  T visitPath(Path node, [T? context]);
}

abstract class AnimationResourceVisitor<T>
    implements ResourceOrReferenceVisitor<T> {
  T visitAnimationResource(AnimationResource node, [T? context]);
  T visitAnimationNode(AnimationNode node, [T? context]);
  T visitAnimationSet(AnimationSet node, [T? context]);
  T visitAnimation(Animation node, [T? context]);
  T visitObjectAnimation(ObjectAnimation node, [T? context]);
  T visitPropertyValuesHolder(PropertyValuesHolder node, [T? context]);
}

abstract class AnimatedVectorDrawableVisitor<T>
    implements ResourceOrReferenceVisitor<T> {
  T visitAnimatedVectorDrawable(AnimatedVectorDrawable node, [T? context]);
  T visitAnimationResource(AnimationResource node, [T? context]);
  T visitVectorDrawable(VectorDrawable node, [T? context]);

  T visitTarget(Target node, [T? context]);
  T visitAnimatedVector(AnimatedVector node, [T? context]);
}
