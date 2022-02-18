import 'dart:ui';

import '../model/animated_vector_drawable.dart';
import '../model/animation.dart';
import '../model/resource.dart';
import '../model/vector_drawable.dart';
import '../parsing/vector_drawable.dart';
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

  StringBuffer _visitValue(Object node, StringBuffer context) {
    if (node is PathData) {
      _visitPathData(node, context);
    } else if (node is ColorOrStyleColor) {
      _visitColorOrStyleColor(node, context);
    } else {
      _visitStringify(node, context);
    }
    return context;
  }

  @override
  StringBuffer visitAnimation(Animation node, [StringBuffer? context]) {
    context ??= StringBuffer();
    context.write('Animation(');
    _maybeWriteNamed('duration', context, node.duration, 300, _visitStringify);
    _writeNamed('valueFrom', context, node.valueFrom, _visitValue);
    _writeNamed('valueTo', context, node.valueTo, _visitValue);
    _maybeWriteNamed('startOffset', context, node.duration, 0, _visitStringify);
    _maybeWriteNamed('repeatCount', context, node.duration, 0, _visitStringify);
    _maybeWriteNamed('repeatMode', context, node.repeatMode, RepeatMode.repeat,
        _visitStringify);
    _maybeWriteNamed('valueType', context, node.valueType, ValueType.floatType,
        _visitStringify);
    context.write(')');
    return context;
  }

  @override
  StringBuffer visitAnimationNode(AnimationNode node, [StringBuffer? context]) {
    context ??= StringBuffer();
    if (node is AnimationSet) {
      visitAnimationSet(node, context);
    } else if (node is Animation) {
      visitAnimation(node, context);
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
  StringBuffer visitResource<R extends Resource>(R node,
      [StringBuffer? context]) {
    context ??= StringBuffer();
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
    _maybeWriteNamedNN(
        'propertyName', context, node.propertyName, _visitString);
    _maybeWriteNamed('duration', context, node.duration, 300, _visitStringify);
    if (node.valueHolders == null) {
      _maybeWriteNamedNN('valueFrom', context, node.valueFrom, _visitValue);
      _writeNamed('valueTo', context, node.valueTo!, _visitValue);
    }
    _maybeWriteNamed('startOffset', context, node.duration, 0, _visitStringify);
    _maybeWriteNamed('repeatCount', context, node.duration, 0, _visitStringify);
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

StringBuffer _visitDimension(Dimension v, StringBuffer context) {
  context.write('Dimension(');
  context.write(v.value);
  context.write(',');
  context.write(v.kind);
  context.write(')');
  return context;
}

StringBuffer _visitString(String v, StringBuffer context) {
  context.write("'");
  context.write(v);
  context.write("'");
  return context;
}

StringBuffer _visitStringify(Object v, StringBuffer context) {
  context.write(v);
  return context;
}

StringBuffer _visitColorOrStyleColor(
    ColorOrStyleColor node, StringBuffer context) {
  context.write('ColorOrStyleColor');
  if (node.styleColor == null) {
    context.write('.color(');
    context.write(node.color);
  } else {
    context.write('.styleColor(');
    context.write('StyleColor(');
    _visitString(node.styleColor!.namespace, context);
    context.write(', ');
    _visitString(node.styleColor!.name, context);
    context.write(')');
  }
  context.write(')');
  return context;
}

StringBuffer _visitPathData(PathData v, StringBuffer context) {
  context.write('PathData.fromString(');
  _visitString(v.asString, context);
  context.write(')');
  return context;
}

class CodegenVectorDrawableVisitor extends VectorDrawableVisitor<StringBuffer>
    with CodegenResourceOrReferenceVisitorMixin {
  @override
  StringBuffer visitVectorDrawable(VectorDrawable node,
      [StringBuffer? context]) {
    context ??= StringBuffer();
    context.write('VectorDrawable(');
    visitVector(node.body, context);
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
  StringBuffer visitVector(Vector node, [StringBuffer? context]) {
    context ??= StringBuffer();
    context.write('Vector(');
    _writeNamedOrNull('name', context, node.name, _visitString);
    _writeNamed('width', context, node.width, _visitDimension);
    _writeNamed('height', context, node.height, _visitDimension);
    _writeNamed('viewportWidth', context, node.viewportWidth, _visitStringify);
    _writeNamed(
        'viewportHeight', context, node.viewportHeight, _visitStringify);
    _writeNamedOrNull('tint', context, node.tint, _visitStringify);
    _maybeWriteNamed(
        'tintMode', context, node.tintMode, BlendMode.srcIn, _visitStringify);
    _maybeWriteNamed(
        'autoMirrored', context, node.autoMirrored, false, _visitStringify);
    _maybeWriteNamed('opacity', context, node.opacity, 1.0, _visitStringify);
    context.write('children: [');
    for (final child in node.children) {
      visitVectorPart(child, context);
      context.write(', ');
    }
    context.write('],');
    context.write(')');
    return context;
  }

  @override
  StringBuffer visitGroup(Group node, [StringBuffer? context]) {
    context ??= StringBuffer();
    context.write('Group(');
    _writeNamedOrNull('name', context, node.name, _visitString);
    _writeNamedOrNull('rotation', context, node.rotation, _visitStringify);
    _writeNamedOrNull('pivotX', context, node.pivotX, _visitStringify);
    _writeNamedOrNull('pivotY', context, node.pivotY, _visitStringify);
    _writeNamedOrNull('scaleX', context, node.scaleX, _visitStringify);
    _writeNamedOrNull('scaleY', context, node.scaleY, _visitStringify);
    _writeNamedOrNull('translateX', context, node.translateX, _visitStringify);
    _writeNamedOrNull('translateY', context, node.translateX, _visitStringify);
    context.write('children: [');
    for (final child in node.children) {
      visitVectorPart(child, context);
      context.write(', ');
    }
    context.write('],');
    context.write(')');
    return context;
  }

  @override
  StringBuffer visitPath(Path node, [StringBuffer? context]) {
    context ??= StringBuffer();
    context.write('Path(');
    _writeNamedOrNull('name', context, node.name, _visitString);
    _writeNamed('pathData', context, node.pathData, _visitPathData);
    _writeNamedOrNull(
        'fillColor', context, node.fillColor, _visitColorOrStyleColor);
    _writeNamedOrNull(
        'strokeColor', context, node.strokeColor, _visitColorOrStyleColor);
    _maybeWriteNamed(
        'strokeWidth', context, node.strokeWidth, 0, _visitStringify);
    _maybeWriteNamed(
        'strokeAlpha', context, node.strokeAlpha, 1, _visitStringify);
    _maybeWriteNamed('fillAlpha', context, node.fillAlpha, 1, _visitStringify);
    _maybeWriteNamed(
        'trimPathStart', context, node.trimPathStart, 0, _visitStringify);
    _maybeWriteNamed(
        'trimPathEnd', context, node.trimPathEnd, 1, _visitStringify);
    _maybeWriteNamed(
        'trimPathOffset', context, node.trimPathOffset, 0, _visitStringify);
    _maybeWriteNamed('strokeLineCap', context, node.strokeLineCap,
        StrokeLineCap.butt, _visitStringify);
    _maybeWriteNamed('strokeLineJoin', context, node.strokeLineJoin,
        StrokeLineJoin.miter, _visitStringify);
    _maybeWriteNamed(
        'strokeMiterLimit', context, node.strokeMiterLimit, 4, _visitStringify);
    _maybeWriteNamed(
        'fillType', context, node.fillType, FillType.nonZero, _visitStringify);
    context.write(')');

    return context;
  }

  @override
  StringBuffer visitResource<R extends Resource>(R node,
      [StringBuffer? context]) {
    throw UnimplementedError();
  }

  @override
  StringBuffer visitVectorPart(VectorPart node, [StringBuffer? context]) {
    context ??= StringBuffer();
    if (node is Group) {
      visitGroup(node, context);
    } else if (node is Path) {
      visitPath(node, context);
    } else {
      throw UnimplementedError();
    }
    return context;
  }
}

mixin CodegenResourceOrReferenceVisitorMixin
    implements ResourceOrReferenceVisitor<StringBuffer> {
  @override
  StringBuffer visitReference(ResourceReference node, [StringBuffer? context]) {
    context ??= StringBuffer();
    context.write('ResourceReference(');
    _visitString(node.folder, context);
    context.write(', ');
    _visitString(node.name, context);
    context.write(')');
    return context;
  }

  @override
  StringBuffer visitResourceOrReference<R extends Resource>(
      ResourceOrReference<R> node,
      [StringBuffer? context]) {
    context ??= StringBuffer();
    context.write('ResourceOrReference');
    if (node.reference == null && node.resource == null) {
      context.write('.empty()');
    } else if (node.reference == null) {
      context.write('.resource(');
      visitResource<R>(node.resource!, context);
      context.write(')');
    } else if (node.resource == null) {
      context.write('.reference(');
      visitReference(node.reference!, context);
      context.write(')');
    } else {
      context.write('(');
      visitResource<R>(node.resource!, context);
      context.write(', ');
      visitReference(node.reference!, context);
      context.write(')');
    }
    return context;
  }
}

class CodegenAnimatedVectorDrawableVisitor
    extends AnimatedVectorDrawableVisitor<StringBuffer>
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
        throw UnimplementedError();
    }
    return context;
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
