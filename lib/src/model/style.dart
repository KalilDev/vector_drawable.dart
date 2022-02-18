abstract class StyleResolver {
  bool containsAny(covariant Iterable<StyleProperty> props);
  T? resolve<T>(StyleProperty property);
}

abstract class StyleResolvable<T> {
  T? resolve(StyleResolver resolver);
}

class StyleOr<T> implements StyleResolvable<T> {
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
}

class StyleProperty {
  final String namespace;
  final String name;

  const StyleProperty(this.namespace, this.name);
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
  int get hashCode => Object.hashAll([namespace, name]);
  bool operator ==(other) =>
      other is StyleProperty &&
      other.namespace == namespace &&
      other.name == name;
}
