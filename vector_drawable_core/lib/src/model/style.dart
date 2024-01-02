import 'diagnostics.dart';

abstract class StyleResolver {
  bool containsAny(covariant Iterable<StyleProperty> props);
  T? resolve<T>(StyleProperty property);
}

abstract class StyleResolvable<T> implements VectorDiagnosticable {
  T? resolve(StyleResolver resolver);
}

class StyleOr<T> with VectorDiagnosticableMixin implements StyleResolvable<T> {
  final T? value;
  final StyleProperty? styled;

  const StyleOr.value(this.value) : styled = null;
  const StyleOr.style(this.styled) : value = null;
  factory StyleOr.parse(String styleOrValueString, T Function(String) parse) {
    if (styleOrValueString.startsWith('?')) {
      return StyleOr.style(
        StyleProperty.fromString(styleOrValueString),
      );
    }
    return StyleOr.value(
      parse(styleOrValueString),
    );
  }

  @override
  T? resolve(StyleResolver resolver) => value ?? resolver.resolve(styled!);

  static String defaultStringifyValue(Object? o) => o.toString();
  String stringify([
    String Function(T) stringifyValue = defaultStringifyValue,
  ]) =>
      styled != null ? styled.toString() : stringifyValue(value!);
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
