import 'package:vector_drawable_core/vector_drawable_core.dart';
import 'package:vector_drawable_core/vector_drawable_core.dart';

enum ElementType { Vector, Group, ClipPath, Path, ChildOutlet }

class ElementNameTypeAndPropertyName {
  final String name;
  final ElementType type;
  final String propetyName;

  const ElementNameTypeAndPropertyName(this.name, this.type, this.propetyName);

  factory ElementNameTypeAndPropertyName.parse(String str) {
    var cs = str.split('-');
    final a = cs[0];
    final ElementType type;
    switch (a) {
      case 'Vector':
        type = ElementType.Vector;
        break;
      case 'Group':
        type = ElementType.Group;
        break;
      case 'ClipPath':
        type = ElementType.ClipPath;
        break;
      case 'Path':
        type = ElementType.Path;
        break;
      case 'ChildOutlet':
        type = ElementType.ChildOutlet;
        break;
      default:
        throw ArgumentError();
    }
    str = cs.skip(1).join('-');
    cs = str.split(':');
    final b = cs.take(cs.length - 1).join(':');
    final c = cs.last;
    return ElementNameTypeAndPropertyName(b, type, c);
  }

  bool operator ==(Object other) {
    if (other is! ElementNameTypeAndPropertyName) {
      return false;
    }
    return name == other.name &&
        type == other.type &&
        propetyName == other.propetyName;
  }

  int get hashCode => Object.hash(name, type, propetyName);

  String get generatedPropertyName => '${type.name}-$name:$propetyName';
  ValueOrProperty<T> toProperty<T extends Object>() => Property(
        StyleProperty(
          'extractedFromElement',
          generatedPropertyName,
        ),
      );
}

class VectorDrawableAndUsedStyles {
  final VectorDrawable vectorDrawable;
  final Map<ElementNameTypeAndPropertyName, StyleOr<Object>> usedStyles;

  VectorDrawableAndUsedStyles(this.vectorDrawable, this.usedStyles);
}

VectorDrawable visitAndExtractUsedStyles(VectorDrawable vectorDrawable) =>
    VectorDrawable(
      vectorDrawable.body.accept<VectorDrawableNode, _VisitorContext>(
          ExtractUsedStylesVisitor()) as Vector,
      vectorDrawable.source,
    );

typedef _VisitorContext
    = Map<ElementNameTypeAndPropertyName, ValueOrProperty<Object>>;

class ExtractUsedStylesVisitor
    extends VectorDrawableNodeFullVisitor<VectorDrawableNode, _VisitorContext> {
  _VisitorContext _makeContext() => _VisitorContext();
  @override
  VectorDrawableNode visitClipPath(ClipPath node, [_VisitorContext? context]) {
    context ??= _makeContext();
    final namedArguments = _addToContextAndExtractParams(
      node.name,
      node.localValuesOrProperties,
      ElementType.ClipPath,
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
      ElementType.Group,
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
  VectorDrawableNode visitPath(Path node, [_VisitorContext? context]) {
    context ??= _makeContext();
    final namedArguments = _addToContextAndExtractParams(
      node.name,
      node.localValuesOrProperties,
      ElementType.Path,
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
    ElementType nodeType,
    List<String> stylablePropertyNames,
    _VisitorContext context,
  ) {
    final name = nodeName;
    final elementType = nodeType;
    final thisElementValueOrProperties =
        <ElementNameTypeAndPropertyName, ValueOrProperty<Object>>{};
    for (var i = 0; i < stylablePropertyNames.length; i++) {
      final propertyName = stylablePropertyNames[i];
      final id =
          ElementNameTypeAndPropertyName(name!, elementType, propertyName);

      final valueOrProperty = nodeLocalValuesOrProperties[i];
      thisElementValueOrProperties[id] = valueOrProperty;
    }
    final es = thisElementValueOrProperties.entries;
    final extractedProperties = es.map((e) {
      final id = e.key;
      final nameSym = Symbol(id.propetyName);
      if (e.value is Property) {
        return MapEntry(
          Symbol(id.propetyName),
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
      ElementType.Vector,
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
      [Map<ElementNameTypeAndPropertyName, ValueOrProperty<Object>>? context]) {
    context ??= _makeContext();
    final namedArguments = _addToContextAndExtractParams(
      node.name ?? 'ROOT',
      node.localValuesOrProperties,
      ElementType.ChildOutlet,
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
