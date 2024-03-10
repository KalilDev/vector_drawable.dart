import 'package:vector_drawable_core/vector_drawable_core.dart';
import 'package:vector_drawable_style_extractor/vector_drawable_style_extractor.dart';

VectorWithExtractedStyles visitAndExtractUsedStyles(Vector vector) {
  final _VisitorContext foo = {};
  return VectorWithExtractedStyles(
    vector.accept<VectorDrawableNode, _VisitorContext>(
        ExtractUsedStylesVisitor(), foo) as Vector,
    ExtractedResolver(
        foo.map((key, value) => MapEntry(key.generatedPropertyName, value))),
  );
}

typedef _VisitorContext = Map<NodeTypeNameAndProperty, ValueOrProperty<Object>>;

class ExtractUsedStylesVisitor
    extends VectorDrawableNodeFullVisitor<VectorDrawableNode, _VisitorContext> {
  _VisitorContext _makeContext() => _VisitorContext();
  @override
  VectorDrawableNode visitClipPath(ClipPath node, [_VisitorContext? context]) {
    context ??= _makeContext();
    final namedArguments = _addToContextAndExtractParams(
      node.name,
      node.localValuesOrProperties,
      node.type,
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
  VectorDrawableNode visitGroup(Group node, [_VisitorContext? context]) {
    context ??= _makeContext();
    final namedArguments = _addToContextAndExtractParams(
      node.name,
      node.localValuesOrProperties,
      node.type,
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
  VectorDrawableNode visitAffineGroup(AffineGroup node, [_VisitorContext? context]) {
    context ??= _makeContext();
    final namedArguments = _addToContextAndExtractParams(
      node.name,
      node.localValuesOrProperties,
      node.type,
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
  VectorDrawableNode visitPath(Path node, [_VisitorContext? context]) {
    context ??= _makeContext();
    final namedArguments = _addToContextAndExtractParams(
      node.name,
      node.localValuesOrProperties,
      node.type,
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
  Map<Symbol, dynamic?> _addToContextAndExtractParams(
    String? nodeName,
    List<ValueOrProperty<Object>> nodeLocalValuesOrProperties,
    VectorDrawableNodeType nodeType,
    List<String> stylablePropertyNames,
    _VisitorContext context,
  ) {
    final name = nodeName;
    final elementType = nodeType;
    final thisElementValueOrProperties =
        <NodeTypeNameAndProperty, ValueOrProperty<Object>>{};
    for (var i = 0; i < stylablePropertyNames.length; i++) {
      final propertyName = stylablePropertyNames[i];
      final id = NodeTypeNameAndProperty(name!, elementType, propertyName);

      final valueOrProperty = nodeLocalValuesOrProperties[i];
      thisElementValueOrProperties[id] = valueOrProperty;
    }
    final es = thisElementValueOrProperties.entries;
    final extractedProperties = es.map((e) {
      final id = e.key;
      final nameSym = Symbol(id.propertyName);
      if (e.value is Property) {
        return MapEntry(
          Symbol(id.propertyName),
          e.value,
        );
      }
      // ignore: deprecated_member_use
      return MapEntry(
          nameSym,
          e.value.extractTypeArgument<ValueOrProperty<Object>>(
              <T extends Object>() => id.toProperty<T>() as Property<Object>));
    });
    context.addAll(thisElementValueOrProperties);
    return Map.fromEntries(extractedProperties);
  }

  @override
  VectorDrawableNode visitVector(Vector node, [_VisitorContext? context]) {
    context ??= _makeContext();
    final namedArguments = _addToContextAndExtractParams(
      node.name ?? 'ROOT',
      node.localValuesOrProperties,
      node.type,
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
      [Map<NodeTypeNameAndProperty, ValueOrProperty<Object>>? context]) {
    context ??= _makeContext();
    final namedArguments = _addToContextAndExtractParams(
      node.name ?? 'ROOT',
      node.localValuesOrProperties,
      node.type,
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
          [_VisitorContext? context]) =>
      node.accept(this, context);
}
