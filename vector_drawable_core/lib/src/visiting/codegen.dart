import '../serializing/util.dart';

import '../model/color.dart';
import '../model/path.dart';
import '../model/resource.dart';
import '../model/style.dart';
import '../model/vector_drawable.dart';
import 'visitor.dart';

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

class CodegenVectorDrawableVisitor
    extends VectorDrawableIsoVisitor<StringBuffer>
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
    _maybeWriteStyleNamed(
        'tint', context, node.tint, VectorColor.transparent, _visitStringify);
    _maybeWriteNamed(
        'tintMode', context, node.tintMode, TintMode.srcIn, _visitStringify);
    _maybeWriteNamed(
        'autoMirrored', context, node.autoMirrored, false, _visitStringify);
    _maybeWriteStyleNamed(
        'opacity', context, node.opacity, 1.0, _visitStringify);
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
  StringBuffer visitClipPath(ClipPath node, [StringBuffer? context]) {
    context ??= StringBuffer();
    context.write('ClipPath(');
    _writeNamedOrNull('name', context, node.name, _visitString);
    _writeStyleNamed('pathData', context, node.pathData, _visitPathData);
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
    _maybeWriteStyleNamed(
        'rotation', context, node.rotation, 0.0, _visitStringify);
    _maybeWriteStyleNamed('pivotX', context, node.pivotX, 0.0, _visitStringify);
    _maybeWriteStyleNamed('pivotY', context, node.pivotY, 0.0, _visitStringify);
    _maybeWriteStyleNamed('scaleX', context, node.scaleX, 1.0, _visitStringify);
    _maybeWriteStyleNamed('scaleY', context, node.scaleY, 1.0, _visitStringify);
    _maybeWriteStyleNamed(
        'translateX', context, node.translateX, 0.0, _visitStringify);
    _maybeWriteStyleNamed(
        'translateY', context, node.translateY, 0.0, _visitStringify);
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
    _writeStyleNamed('pathData', context, node.pathData, _visitPathData);
    _maybeWriteStyleNamed('fillColor', context, node.fillColor,
        VectorColor.transparent, _visitStringify);
    _maybeWriteStyleNamed('strokeColor', context, node.strokeColor,
        VectorColor.transparent, _visitStringify);
    _maybeWriteStyleNamed(
        'strokeWidth', context, node.strokeWidth, 0.0, _visitStringify);
    _maybeWriteStyleNamed(
        'strokeAlpha', context, node.strokeAlpha, 1.0, _visitStringify);
    _maybeWriteStyleNamed(
        'fillAlpha', context, node.fillAlpha, 1.0, _visitStringify);
    _maybeWriteStyleNamed(
        'trimPathStart', context, node.trimPathStart, 0.0, _visitStringify);
    _maybeWriteStyleNamed(
        'trimPathEnd', context, node.trimPathEnd, 1.0, _visitStringify);
    _maybeWriteStyleNamed(
        'trimPathOffset', context, node.trimPathOffset, 0.0, _visitStringify);
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
    } else if (node is ClipPath) {
      visitClipPath(node, context);
    } else {
      throwUnimplemented();
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
