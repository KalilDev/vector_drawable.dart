import '../parsing/util.dart';

import '../model/animated_vector_drawable.dart';
import '../model/animation.dart';
import 'package:vector_drawable_core/model.dart';
import 'package:vector_drawable_core/visiting.dart';
import 'visitor.dart';

class CodegenAnimationResourceVisitor
    extends AnimationResourceVisitor<StringBuffer>
    with CodegenResourceOrReferenceVisitorMixin {
  @override
  StringBuffer visitAnimationResource(AnimationResource node,
      [StringBuffer? context]) {
    context ??= StringBuffer();
    context.write('AnimationResource(');
    visitAnimationNode(node.body, context);
    context.write(', ');
    if (node.source == null) {
      context.write('null');
    } else {
      visitReference(node.source!, context);
    }
    context.write(')');
    return context;
  }

  @override
  StringBuffer visitAnimationNode(AnimationNode node, [StringBuffer? context]) {
    context ??= StringBuffer();
    if (node is AnimationSet) {
      visitAnimationSet(node, context);
    } else if (node is ObjectAnimation) {
      visitObjectAnimation(node, context);
    }
    return context;
  }

  @override
  StringBuffer visitAnimationSet(AnimationSet node, [StringBuffer? context]) {
    context ??= StringBuffer();
    context.write('AnimationSet(');
    context.write(node.ordering);
    context.write(', ');
    context.write('[');
    for (final child in node.children) {
      visitAnimationNode(child, context);
      context.write(', ');
    }
    context.write('],');
    context.write(')');
    return context;
  }

  @override
  StringBuffer visitInterpolator(Interpolator node, [StringBuffer? context]) {
    context ??= StringBuffer();
    context.write('Interpolator(');

    context.write(')');
    return context;
  }

  @override
  StringBuffer visitResource<R extends Resource>(R node,
      [StringBuffer? context]) {
    context ??= StringBuffer();
    switch (R) {
      case Interpolator:
        return visitInterpolator(node as Interpolator, context);
    }
    throw UnimplementedError();
    return context;
  }

  StringBuffer _visitKeyframe(Keyframe node, StringBuffer context) {
    context.write('Keyframe(');
    _maybeWriteNamed('valueType', context, node.valueType, ValueType.floatType,
        _visitStringify);
    _maybeWriteNamedNN('fraction', context, node.fraction, _visitStringify);
    _maybeWriteNamedNN('value', context, node.value, _visitValue);
    _maybeWriteNamedNN(
        'interpolator', context, node.interpolator, visitResourceOrReference);
    context.write(')');
    return context;
  }

  @override
  StringBuffer visitPropertyValuesHolder(PropertyValuesHolder node,
      [StringBuffer? context]) {
    context ??= StringBuffer();
    context.write('PropertyValuesHolder(');
    _writeNamed('propertyName', context, node.propertyName, _visitString);
    if (node.keyframes == null) {
      _maybeWriteNamedNN('valueFrom', context, node.valueFrom, _visitValue);
      _writeNamed('valueTo', context, node.valueTo!, _visitValue);
    }
    _maybeWriteNamed('valueType', context, node.valueType, ValueType.floatType,
        _visitStringify);
    if (node.keyframes != null) {
      _writeNamed<List<Keyframe>>('keyframes', context, node.keyframes!,
          (keyframes, context) {
        context.write('[');
        for (final keyframe in keyframes) {
          _visitKeyframe(keyframe, context);
          context.write(', ');
        }
        context.write(']');
        return context;
      });
    }
    context.write(')');
    return context;
  }

  @override
  StringBuffer visitObjectAnimation(ObjectAnimation node,
      [StringBuffer? context]) {
    context ??= StringBuffer();
    context.write('ObjectAnimation(');
    if (node.pathData != null) {
      _maybeWriteNamedNN(
          'pathData', context, node.pathData, _visitStyleOrValue);
      _maybeWriteNamedNN(
          'propertyXName', context, node.propertyXName, _visitString);
      _maybeWriteNamedNN(
          'propertyYName', context, node.propertyYName, _visitString);
    }
    _maybeWriteNamedNN(
        'propertyName', context, node.propertyName, _visitString);
    _maybeWriteNamed('duration', context, node.duration, 300, _visitStringify);
    _maybeWriteNamedNN<ResourceOrReference<Interpolator>>(
        'interpolator', context, node.interpolator, visitResourceOrReference);
    if (node.valueHolders == null && node.pathData == null) {
      _maybeWriteNamedNN(
          'valueFrom', context, node.valueFrom, _visitStyleOrValue);
      _writeNamed('valueTo', context, node.valueTo!, _visitStyleOrValue);
    }
    _maybeWriteNamed(
        'startOffset', context, node.startOffset, 0, _visitStringify);
    _maybeWriteNamed(
        'repeatCount', context, node.repeatCount, 0, _visitStringify);
    _maybeWriteNamed('repeatMode', context, node.repeatMode, RepeatMode.repeat,
        _visitStringify);
    _maybeWriteNamed('valueType', context, node.valueType, ValueType.floatType,
        _visitStringify);
    if (node.valueHolders != null) {
      _writeNamed<List<PropertyValuesHolder>>(
          'valueHolders', context, node.valueHolders!, (holders, context) {
        context.write('[');
        for (final holder in holders) {
          visitPropertyValuesHolder(holder, context);
          context.write(', ');
        }
        context.write(']');
        return context;
      });
    }
    context.write(')');
    return context;
  }
}

void _writeNamedOrNull<T>(String name, StringBuffer context, T? arg,
    StringBuffer Function(T, StringBuffer) visit) {
  if (arg == null) {
    context.write(name);
    context.write(': null,');
  } else {
    _writeNamed(name, context, arg, visit);
  }
}

void _writeNamed<T>(String name, StringBuffer context, T arg,
    StringBuffer Function(T, StringBuffer) visit) {
  context.write(name);
  context.write(': ');
  visit(arg, context);
  context.write(',');
}

void _maybeWriteNamedNN<T>(String name, StringBuffer context, T? arg,
    StringBuffer Function(T, StringBuffer) visit) {
  if (arg == null) {
    return;
  }
  _writeNamed(name, context, arg, visit);
}

void _maybeWriteNamed<T>(String name, StringBuffer context, T arg, T whenNot,
    StringBuffer Function(T, StringBuffer) visit) {
  if (arg == whenNot) {
    return;
  }
  _writeNamed(name, context, arg, visit);
}

void _writeStyleNamed<T extends Object>(
  String name,
  StringBuffer context,
  StyleOr<T> arg,
  StringBuffer Function(T, StringBuffer) visit,
) {
  _writeNamed<StyleOr<T>>(name, context, arg,
      (node, context) => _visitStyleOr(node, context, visit));
}

void _maybeWriteStyleNamed<T extends Object>(
  String name,
  StringBuffer context,
  StyleOr<T> arg,
  T whenNot,
  StringBuffer Function(T, StringBuffer) visit,
) {
  if (arg.value == whenNot) {
    return;
  }
  _writeNamed<StyleOr<T>>(name, context, arg,
      (node, context) => _visitStyleOr(node, context, visit));
}

StringBuffer _visitDimension(Dimension v, StringBuffer context) {
  context.write('Dimension(');
  context.write(v.value);
  context.write(',');
  context.write(v.kind);
  context.write(')');
  return context;
}

StringBuffer _visitString(String v, StringBuffer context) {
  context.write("r'");
  context.write(v);
  context.write("'");
  return context;
}

StringBuffer _visitStringify(Object v, StringBuffer context) {
  context.write(v);
  return context;
}

StringBuffer _visitValue(Object node, StringBuffer context) {
  if (node is PathData) {
    _visitPathData(node, context);
  } else if (node is StyleOr<Object>) {
    _visitStyleOr<Object>(node, context, _visitValue);
  } else {
    // double, num and Color
    _visitStringify(node, context);
  }
  return context;
}

StringBuffer _visitStyleOrValue(
  StyleOr<Object> node,
  StringBuffer context,
) =>
    _visitStyleOr(
      node,
      context,
      _visitValue,
    );
StringBuffer _visitStyleOrPathData(
  StyleOr<PathData> node,
  StringBuffer context,
) =>
    _visitStyleOr(
      node,
      context,
      _visitPathData,
    );
StringBuffer _visitStyleOrStringify(
  StyleOr<Object> node,
  StringBuffer context,
) =>
    _visitStyleOr(node, context, _visitStringify);
StringBuffer _visitStyleOr<T extends Object>(
  StyleOr<T> node,
  StringBuffer context,
  StringBuffer Function(T, StringBuffer) visit,
) {
  if (node is Value<T>) {
    context.write('Value<');
    context.write(T);
    context.write('>(');
    visit(node.value, context);
    context.write(')');
    return context;
  }
  if (node is Property<T>) {
    context.write('Property<');
    context.write(T);
    context.write('>(');
    context.write('StyleProperty(');
    _visitString(node.property.namespace, context);
    context.write(', ');
    _visitString(node.property.name, context);
    context.write(')');
    context.write(')');
    return context;
  }
  throw TypeError();
}

StringBuffer _visitPathData(PathData v, StringBuffer context) {
  context.write('PathData.fromStringRaw(');
  _visitString(
      PathData.removeTrailingCubic(v.toPathDataString(needsSameInput: true)),
      context);
  context.write(')');
  return context;
}

class CodegenAnimatedVectorDrawableVisitor
    extends AnimatedVectorDrawableIsoVisitor<StringBuffer>
    with CodegenResourceOrReferenceVisitorMixin {
  final CodegenVectorDrawableVisitor _vectorDrawableVisitor =
      CodegenVectorDrawableVisitor();
  final CodegenAnimationResourceVisitor _animationResourceVisitor =
      CodegenAnimationResourceVisitor();
  @override
  StringBuffer visitAnimatedVectorDrawable(AnimatedVectorDrawable node,
      [StringBuffer? context]) {
    context ??= StringBuffer();
    context.write('AnimatedVectorDrawable(');
    visitAnimatedVector(node.body, context);
    context.write(', ');
    if (node.source == null) {
      context.write('null');
    } else {
      visitReference(node.source!, context);
    }
    context.write(')');
    return context;
  }

  @override
  StringBuffer visitAnimatedVector(AnimatedVector node,
      [StringBuffer? context]) {
    context ??= StringBuffer();
    context.write('AnimatedVector(');
    visitResourceOrReference<VectorDrawable>(node.drawable, context);
    context.write(', [');
    for (final child in node.children) {
      visitTarget(child, context);
      context.write(', ');
    }
    context.write('],');
    context.write(')');
    return context;
  }

  @override
  StringBuffer visitTarget(Target node, [StringBuffer? context]) {
    context ??= StringBuffer();
    context.write('Target(');
    _visitString(node.name, context);
    context.write(', ');
    visitResourceOrReference<AnimationResource>(node.animation, context);
    context.write(')');
    return context;
  }

  @override
  StringBuffer visitResource<R extends Resource>(R node,
      [StringBuffer? context]) {
    context ??= StringBuffer();
    switch (R) {
      case AnimationResource:
        return visitAnimationResource(node as AnimationResource, context);
      case VectorDrawable:
        return visitVectorDrawable(node as VectorDrawable, context);
      default:
        throw TypeError();
    }
  }

  @override
  StringBuffer visitVectorDrawable(VectorDrawable node,
      [StringBuffer? context]) {
    context ??= StringBuffer();
    _vectorDrawableVisitor.visitVectorDrawable(node, context);
    return context;
  }

  @override
  StringBuffer visitAnimationResource(AnimationResource node,
      [StringBuffer? context]) {
    context ??= StringBuffer();
    _animationResourceVisitor.visitAnimationResource(node, context);
    return context;
  }
}
