import 'package:vector_drawable_core/vector_drawable_core.dart';
import 'package:vector_drawable_style_extractor/vector_drawable_style_extractor.dart';

typedef PropertyName = String;

class StyleInlinerVisitor
    extends VectorDrawableNodeFullVisitor<VectorDrawableNode, StyleResolver> {
  @override
  VectorDrawableNode visitClipPath(ClipPath node, [StyleResolver? context]) {
    context!;
    final namedArguments = _inlineProperties(
      node.localValuesOrProperties,
      ClipPath.stylablePropertyNames,
      context,
    );
    final children = node.children
        .map((e) => e.accept(this, context) as VectorPart)
        .toList();
    namedArguments.addAll({
      #name: node.name,
      #children: children,
    });
    return Function.apply(ClipPath.new, const [], namedArguments) as ClipPath;
  }

  @override
  VectorDrawableNode visitGroup(Group node, [StyleResolver? context]) {
    context!;
    final namedArguments = _inlineProperties(
      node.localValuesOrProperties,
      Group.stylablePropertyNames,
      context,
    );
    final children = node.children
        .map((e) => e.accept(this, context) as VectorPart)
        .toList();
    namedArguments.addAll({
      #name: node.name,
      #children: children,
    });
    return Function.apply(Group.new, const [], namedArguments) as Group;
  }

  @override
  VectorDrawableNode visitAffineGroup(AffineGroup node, [StyleResolver? context]) {
    context!;
    final namedArguments = _inlineProperties(
      node.localValuesOrProperties,
      AffineGroup.stylablePropertyNames,
      context,
    );
    final children = node.children
        .map((e) => e.accept(this, context) as VectorPart)
        .toList();
    namedArguments.addAll({
      #name: node.name,
      #children: children,
    });
    return Function.apply(AffineGroup.new, const [], namedArguments) as AffineGroup;
  }

  @override
  VectorDrawableNode visitPath(Path node, [StyleResolver? context]) {
    context!;
    final namedArguments = _inlineProperties(
      node.localValuesOrProperties,
      Path.stylablePropertyNames,
      context,
    );
    namedArguments.addAll({
      #name: node.name,
      #strokeLineCap: node.strokeLineCap,
      #strokeLineJoin: node.strokeLineJoin,
      #strokeMiterLimit: node.strokeMiterLimit,
      #fillType: node.fillType
    });
    return Function.apply(Path.new, const [], namedArguments) as Path;
  }

  @override
  Map<Symbol, dynamic?> _inlineProperties(
    List<ValueOrProperty<Object>> nodeLocalValuesOrProperties,
    List<String> stylablePropertyNames,
    StyleResolver styleResolver,
  ) {
    final thisElementValueOrProperties =
        <PropertyName, ValueOrProperty<Object>>{};
    for (var i = 0; i < stylablePropertyNames.length; i++) {
      final propertyName = stylablePropertyNames[i];
      final valueOrProperty = nodeLocalValuesOrProperties[i];
      thisElementValueOrProperties[propertyName] = valueOrProperty;
    }
    final es = thisElementValueOrProperties.entries;
    final inlinedProperties = es.map((e) {
      final propertyName = e.key;
      final propertySym = Symbol(propertyName);
      final ValueOrProperty<Object> inlined;
      if (e.value is Property) {
        final resolved = styleResolver.resolveUntyped(e.value.property!);
        if (resolved is Property) {
          inlined = e.value.extractTypeArgument<Property>(
              <T extends Object>() => Property<T>(resolved.property));
        } else if (resolved is Value) {
          inlined = e.value.extractTypeArgument<Value>(
              <T extends Object>() => Value<T>(resolved.value as T));
        } else {
          inlined = e.value.extractTypeArgument<Value>(
              <T extends Object>() => Value<T>(resolved as T));
        }
      } else {
        final v = e.value as Value;
        inlined = v;
      }
      return MapEntry(propertySym, inlined);
    });
    return Map.fromEntries(inlinedProperties);
  }

  @override
  VectorDrawableNode visitVector(Vector node, [StyleResolver? context]) {
    context!;
    final namedArguments = _inlineProperties(
      node.localValuesOrProperties,
      Vector.stylablePropertyNames,
      context,
    );
    final children = node.children
        .map((e) => e.accept(this, context) as VectorPart)
        .toList();
    namedArguments.addAll({
      #name: node.name ?? 'ROOT',
      #width: node.width,
      #height: node.height,
      #viewportWidth: node.viewportWidth,
      #viewportHeight: node.viewportHeight,
      #tintMode: node.tintMode,
      #autoMirrored: node.autoMirrored,
      #children: children,
    });
    return Function.apply(Vector.new, const [], namedArguments) as Vector;
  }

  @override
  VectorDrawableNode visitChildOutlet(ChildOutlet node,
      [StyleResolver? context]) {
    context!;
    final namedArguments = _inlineProperties(
      node.localValuesOrProperties,
      ChildOutlet.stylablePropertyNames,
      context,
    );
    namedArguments.addAll({
      #name: node.name ?? 'ChildOutlet',
    });
    return Function.apply(ChildOutlet.new, const [], namedArguments)
        as ChildOutlet;
  }

  @override
  VectorDrawableNode visitVectorPart(VectorPart node,
          [StyleResolver? context]) =>
      node.accept(this, context);
}
