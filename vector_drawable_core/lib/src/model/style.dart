import 'diagnostics.dart';

const _iAmExtendingYou = Object();

abstract class StyleResolver {
  final Object _dontImplementMe;
  const StyleResolver() : _dontImplementMe = _iAmExtendingYou;
  const factory StyleResolver.empty() = _EmptyStyleResolver;
  const factory StyleResolver.merged(
    StyleResolver first,
    StyleResolver second,
  ) = _MergedStyleResolver;
  const factory StyleResolver.bound(
    StyleResolver first,
    StyleResolver second,
  ) = _BoundStyleResolver;

  const factory StyleResolver.fromMap(Map<String, Object> values,
      {String namespace}) = StyleResolverWithEfficientContains.fromMap;
  bool contains(StyleProperty prop) => containsAny([prop]);
  bool containsAny(covariant Iterable<StyleProperty> props);
  Object? resolveUntyped(StyleProperty property);
  T? resolve<T>(StyleProperty property) => resolveUntyped(property) as T?;
  StyleResolver mergeWith(StyleResolver other) =>
      StyleResolver.merged(this, other);
}

abstract class _EfficientContains {}

abstract class StyleResolverWithEfficientContains extends StyleResolver
    implements _EfficientContains {
  const StyleResolverWithEfficientContains();
  const factory StyleResolverWithEfficientContains.merged(
    StyleResolverWithEfficientContains first,
    StyleResolverWithEfficientContains second,
  ) = _MergedStyleResolverWithEfficientContains;
  const factory StyleResolverWithEfficientContains.fromMap(
      Map<String, Object> values,
      {String namespace}) = _StyleResolverFromMap;
  @override
  StyleResolver mergeWith(StyleResolver other) =>
      other is StyleResolverWithEfficientContains
          ? StyleResolverWithEfficientContains.merged(this, other)
          : StyleResolver.merged(this, other);
}

class _StyleResolverFromMap extends StyleResolverWithEfficientContains {
  final Map<String, Object> map;
  final String namespace;

  const _StyleResolverFromMap(
    this.map, {
    this.namespace = '',
  });

  @override
  bool contains(StyleProperty color) =>
      color.namespace == namespace && map.containsKey(color.name);

  @override
  bool containsAny(Set<StyleProperty> colors) => colors.any(contains);

  @override
  Object? resolveUntyped(StyleProperty prop) {
    if (!contains(prop)) {
      return null;
    }
    return map[prop.name];
  }
}

class _EmptyStyleResolver extends StyleResolver {
  const _EmptyStyleResolver() : super();

  @override
  bool containsAny(Iterable<StyleProperty> props) => false;

  @override
  Object? resolveUntyped(StyleProperty property) => null;
}

class _MergedStyleResolver extends StyleResolver {
  final StyleResolver first;
  final StyleResolver second;

  const _MergedStyleResolver(this.first, this.second) : super();

  @override
  bool containsAny(covariant Iterable<StyleProperty> props) =>
      first.containsAny(props) || second.containsAny(props);

  @override
  Object? resolveUntyped(StyleProperty property) =>
      first.resolveUntyped(property) ?? second.resolveUntyped(property);
}

class _MergedStyleResolverWithEfficientContains extends StyleResolver
    implements StyleResolverWithEfficientContains {
  final StyleResolver first;
  final StyleResolver second;

  const _MergedStyleResolverWithEfficientContains(this.first, this.second)
      : super();

  @override
  bool contains(StyleProperty prop) =>
      first.contains(prop) || second.contains(prop);

  @override
  bool containsAny(covariant Iterable<StyleProperty> props) =>
      first.containsAny(props) || second.containsAny(props);

  @override
  Object? resolveUntyped(StyleProperty property) =>
      first.resolveUntyped(property) ?? second.resolveUntyped(property);
}

class _BoundStyleResolver extends StyleResolver {
  final StyleResolver first;
  final StyleResolver second;

  const _BoundStyleResolver(this.first, this.second) : super();

  @override
  bool containsAny(covariant Iterable<StyleProperty> props) =>
      first.containsAny(props) || second.containsAny(props);

  @override
  Object? resolveUntyped(StyleProperty property) {
    final resolvedFirst = first.resolveUntyped(property);
    if (resolvedFirst == null) {
      return second.resolveUntyped(property);
    }
    if (resolvedFirst is Property) {
      return second.resolveUntyped(resolvedFirst.property);
    }
    if (resolvedFirst is Value) {
      return resolvedFirst.value;
    }
    return resolvedFirst;
  }
}

abstract class StyleResolvable<T> implements VectorDiagnosticable {
  T? resolve(StyleResolver resolver);
}

enum StyleOrKind { property, value }

typedef StyleOr<T extends Object> = ValueOrProperty<T>;

class Value<T extends Object> extends ValueOrProperty<T> {
  const Value(T value) : super._(StyleOrKind.property, value: value);
  @override
  T get value => _value!;

  @override
  @Deprecated('you already know this is a value, dont try to access this.')
  StyleProperty? get property => null;

  @override
  @Deprecated(
      'use property, also you already know this is a value, dont try to access this.')
  StyleProperty? get styled => null;

  @override
  T? resolve(StyleResolver resolver) => value;

  @override
  String stringify([
    String Function(T) stringifyValue = ValueOrProperty.defaultStringifyValue,
  ]) =>
      stringifyValue(value);

  @override
  String toString([
    String Function(T) stringifyValue = ValueOrProperty.defaultStringifyValue,
  ]) =>
      'Value<$T>(${stringifyValue(value)})';
}

class Property<T extends Object> extends ValueOrProperty<T> {
  const Property(StyleProperty property)
      : super._(StyleOrKind.property, property: property);
  @override
  @Deprecated('you already know this is a property, dont try to access this.')
  T? get value => null;
  @override
  StyleProperty get property => _property!;
  @override
  T? resolve(StyleResolver resolver) => resolver.resolve(property);
  @override
  String stringify([
    String Function(T) stringifyValue = ValueOrProperty.defaultStringifyValue,
  ]) =>
      property.toString();
  @override
  String toString() => 'Property<$T>($property)';
}

abstract class ValueOrProperty<T extends Object>
    with VectorDiagnosticableMixin
    implements StyleResolvable<T> {
  const ValueOrProperty._(
    this.kind, {
    T? value,
    StyleProperty? property,
  })  : _value = value,
        _property = property;
  final T? _value;
  final StyleProperty? _property;
  final StyleOrKind kind;

  @Deprecated('use property')
  StyleProperty? get styled => _property;

  T? get value => _value;
  StyleProperty? get property => _property;

  @Deprecated('use isProperty')
  bool get isStyle => kind == StyleOrKind.property;

  @Deprecated('prefer is Property')
  bool get isProperty => kind == StyleOrKind.property;
  @Deprecated('prefer is Value')
  bool get isValue => kind == StyleOrKind.value;

  const factory ValueOrProperty.value(T value) = Value;
  @Deprecated('use StyleOr.property')
  const factory ValueOrProperty.style(StyleProperty property) = Property;
  const factory ValueOrProperty.property(StyleProperty property) = Property;

  factory ValueOrProperty.parse(
    String styleOrValueString,
    T Function(String) parse,
  ) {
    if (styleOrValueString.startsWith('?')) {
      return Property(
        StyleProperty.fromString(styleOrValueString),
      );
    }
    return Value(
      parse(styleOrValueString),
    );
  }
  static String defaultStringifyValue(Object? o) => o.toString();

  String stringify([
    String Function(T) stringifyValue = defaultStringifyValue,
  ]);

  @override
  String toString() => throw UnimplementedError();

  @override
  int get hashCode => Object.hash(_property, _value, kind);

  @override
  bool operator ==(Object other) =>
      identical(other, this) &&
      other is ValueOrProperty &&
      _property == other._property &&
      _value == other._value &&
      kind == other.kind;

  @Deprecated('you probably dont know how to use this')
  R extractTypeArgument<R>(R Function<T extends Object>() user) => user<T>();
}

extension StyleOrFromTE<T extends Object> on T {
  StyleOr<T> get asStyle => StyleOr.value(this);
}

class StyleProperty extends VectorDiagnosticable {
  final String namespace;
  final String name;
  static const String noNamespace = '';
  const StyleProperty(String nameOrNamespace, [String? name])
      : namespace = name == null ? noNamespace : nameOrNamespace,
        name = name ?? nameOrNamespace;

  factory StyleProperty.fromString(String themeColor) {
    if (!themeColor.startsWith('?')) {
      throw StateError('');
    }
    final split = themeColor.split(':');
    if (split.length != 2 && split.length != 1) {
      throw StateError('');
    }
    return StyleProperty(split.length == 1 ? '' : split[0].substring(1),
        split.length == 1 ? split[0].substring(1) : split[1]);
  }
  @override
  int get hashCode => Object.hashAll([namespace, name]);
  @override
  bool operator ==(other) =>
      other is StyleProperty &&
      other.namespace == namespace &&
      other.name == name;
  @override
  String toString() => '?${namespace.isEmpty ? '' : '$namespace:'}$name';
}

class StylePropertyNamespace {
  final String namespace;
  const StylePropertyNamespace(this.namespace);
  StyleProperty operator [](String name) => StyleProperty(namespace, name);
}

class StylePropertySymbolizedNamespace {
  final Symbol namespace;
  const StylePropertySymbolizedNamespace(this.namespace);
  StyleProperty operator [](Symbol name) => StyleProperty(
        StylePropertyFromSymbol._unqualifiedStringFromSymbol(namespace),
        StylePropertyFromSymbol._unqualifiedStringFromSymbol(name),
      );
}

extension StylePropertyFromString on String {
  StyleProperty get prop => StyleProperty('', this);

  StylePropertyNamespace get namespace => StylePropertyNamespace(this);
}

extension StylePropertyFromSymbol on Symbol {
  static String _unqualifiedStringFromSymbol(Symbol s) {
    final asString = s.toString();
    return asString.split('"')[1];
  }

  StyleProperty get prop =>
      StyleProperty('', _unqualifiedStringFromSymbol(this));

  StylePropertySymbolizedNamespace get namespace =>
      StylePropertySymbolizedNamespace(this);
}
