import 'package:vector_drawable_core/vector_drawable_core.dart';

import '../visitors/extract_used_styles_visitor.dart';
import 'node_type_name_and_property.dart';

class ExtractedResolver extends StyleResolverWithEfficientContains {
  final StyleResolverWithEfficientContains _values;
  final Map<String, ValueOrProperty<Object>> _rawValues;
  const ExtractedResolver.raw(StyleResolverWithEfficientContains values,
      Map<String, ValueOrProperty<Object>> rawValues)
      : _values = values,
        _rawValues = rawValues;
  const factory ExtractedResolver.overriden(
    ExtractedResolver base,
    VectorDrawableNodeType elementType,
    String elementName, {
    required Map<String, ValueOrProperty> overrides,
  }) = _ResolverOverride;
  // todo: Optimize
  factory ExtractedResolver.manyOverriden(
    ExtractedResolver base, {
    required Map<OverrideTarget, ElementOverrides> overrides,
  }) {
    for (final to in overrides.entries) {
      final t = to.key;
      final o = to.value;
      base = base.overrideNode(t.type, t.name, overrides: o);
    }
    return base;
  }
  ExtractedResolver(Map<String, ValueOrProperty<Object>> values)
      : _values = StyleResolverWithEfficientContains.fromMap(
          values,
          namespace: 'extractedFromNode',
        ),
        _rawValues = values;

  bool contains(StyleProperty prop) => _values.contains(prop);
  @override
  bool containsAny(covariant Iterable<StyleProperty> props) =>
      _values.containsAny(props);

  @override
  Object? resolveUntyped(StyleProperty property) {
    final resolved = _values.resolveUntyped(property);
    if (resolved is Value) {
      return resolved.value;
    }
    return resolved;
  }

  ExtractedResolver overrideNode(
          VectorDrawableNodeType elementType, String elementName,
          {required Map<String, ValueOrProperty> overrides}) =>
      ExtractedResolver.overriden(this, elementType, elementName,
          overrides: overrides);
  @override
  Map<VectorDrawableNodeType, Map<String, Map<String, ValueOrProperty<Object>>>>
      rawValues() {
    final out = <VectorDrawableNodeType,
        Map<String, Map<String, ValueOrProperty<Object>>>>{};
    for (final e in _rawValues.entries) {
      final id = NodeTypeNameAndProperty.parse(e.key);
      final val = e.value;
      final t = out.putIfAbsent(id.type, () => {});
      final n = t.putIfAbsent(id.name, () => {});
      n[id.propertyName] = val;
    }
    return out;
  }
}

class OverrideTarget {
  final VectorDrawableNodeType type;
  final String name;

  const OverrideTarget(this.type, this.name);
}

typedef ElementOverrides = Map<String, ValueOrProperty>;

class _ResolverOverride extends StyleResolverWithEfficientContains
    implements ExtractedResolver {
  final ExtractedResolver base;
  final VectorDrawableNodeType element;
  final String elementName;
  final ElementOverrides overrides;
  Map<String, ValueOrProperty> get _rawValues => base._rawValues;

  const _ResolverOverride(this.base, this.element, this.elementName,
      {required this.overrides});

  @override
  bool contains(StyleProperty prop) {
    if (_values.contains(prop)) {
      return true;
    }
    if (prop.namespace != 'extractedFromNode') {
      return false;
    }
    final parsed = NodeTypeNameAndProperty.parse(prop.name);
    if (parsed.type != element || parsed.name != elementName) {
      return false;
    }
    return overrides.containsKey(parsed.propertyName);
  }

  @override
  StyleResolverWithEfficientContains get _values => base;

  @override
  bool containsAny(covariant Iterable<StyleProperty> props) {
    if (_values.containsAny(props)) {
      return true;
    }
    // TODO: optimize this
    for (final contains in props.map(contains)) {
      if (contains) {
        return true;
      }
    }
    return false;
  }

  @override
  Object? resolveUntyped(StyleProperty prop) {
    if (prop.namespace != 'extractedFromNode') {
      return _values.resolveUntyped(prop);
    }
    final parsed = NodeTypeNameAndProperty.parse(prop.name);
    if (parsed.type != element || parsed.name != elementName) {
      return _values.resolveUntyped(prop);
    }
    if (overrides.containsKey(parsed.propertyName)) {
      final p = overrides[parsed.propertyName];
      return p is Value ? p.value : p;
    }
    return _values.resolveUntyped(prop);
  }

  @override
  ExtractedResolver overrideNode(
      VectorDrawableNodeType elementType, String elementName,
      {required ElementOverrides overrides}) {
    final isSameTargetAsThis =
        elementType == element && elementName == this.elementName;
    if (!isSameTargetAsThis) {
      return ExtractedResolver.overriden(this, elementType, elementName,
          overrides: overrides);
    }
    return _ResolverOverride(base, element, elementName, overrides: {
      ...this.overrides,
      ...overrides,
    });
  }

  @override
  Map<VectorDrawableNodeType, Map<String, Map<String, ValueOrProperty<Object>>>>
      rawValues() {
    final out = <VectorDrawableNodeType,
        Map<String, Map<String, ValueOrProperty<Object>>>>{};
    for (final e in _rawValues.entries) {
      final id = NodeTypeNameAndProperty.parse(e.key);
      final val = e.value;
      final t = out.putIfAbsent(id.type, () => {});
      final n = t.putIfAbsent(id.name, () => {});
      n[id.propertyName] = val;
    }
    return out;
  }
}
