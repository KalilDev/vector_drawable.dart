import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide ClipPath;
import 'package:vector_drawable_core/vector_drawable_core.dart';

@Deprecated("Use ColorSchemeStyleResolver")
typedef ColorSchemeStyleMapping = ColorSchemeStyleResolver;

class ColorSchemeStyleResolver extends StyleResolverWithEfficientContains
    with Diagnosticable {
  final ColorScheme scheme;
  ColorSchemeStyleResolver(this.scheme);

  static final _kColorSchemeColors = {
    const StyleProperty('android', 'colorBackground'),
    const StyleProperty('', 'colorSurface'),
    const StyleProperty('', 'colorOnSurface'),
    const StyleProperty('', 'colorInverseSurface'),
    const StyleProperty('', 'colorOnInverseSurface'),
    const StyleProperty('', 'colorInversePrimary'),
    const StyleProperty('', 'colorSurfaceVariant'),
    const StyleProperty('', 'colorOnSurfaceVariant'),
    const StyleProperty('', 'colorOutline'),
    const StyleProperty('', 'colorBackground'),
    const StyleProperty('', 'colorOnBackground'),
    const StyleProperty('', 'colorPrimary'),
    const StyleProperty('', 'colorOnPrimary'),
    const StyleProperty('', 'colorSecondary'),
    const StyleProperty('', 'colorOnSecondary'),
    const StyleProperty('', 'colorTertiary'),
    const StyleProperty('', 'colorOnTertiary'),
    const StyleProperty('', 'colorError'),
    const StyleProperty('', 'colorOnError'),
  };

  @override
  bool contains(StyleProperty color) => _kColorSchemeColors.contains(color);

  @override
  bool containsAny(Iterable<StyleProperty> colors) =>
      colors.any(_kColorSchemeColors.contains);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty('scheme', scheme));
  }

  @override
  Object? resolveUntyped(StyleProperty color) {
    if (color == const StyleProperty('android', 'colorBackground')) {
      return scheme.background;
    }
    if (color.namespace != '') {
      return null;
    }
    switch (color.name) {
      case 'colorSurface':
        return scheme.surface;
      case 'colorOnSurface':
        return scheme.onSurface;
      case 'colorInverseSurface':
        return scheme.inverseSurface;
      case 'colorOnInverseSurface':
        return scheme.onInverseSurface;
      case 'colorInversePrimary':
        return scheme.inversePrimary;
      case 'colorSurfaceVariant':
        return scheme.surfaceVariant;
      case 'colorOnSurfaceVariant':
        return scheme.onSurfaceVariant;
      case 'colorOutline':
        return scheme.outline;
      case 'colorBackground':
        return scheme.background;
      case 'colorOnBackground':
        return scheme.onBackground;
      case 'colorPrimary':
        return scheme.primary;
      case 'colorOnPrimary':
        return scheme.onPrimary;
      case 'colorPrimaryContainer':
        return scheme.primaryContainer;
      case 'colorOnPrimaryContainer':
        return scheme.onPrimaryContainer;
      case 'colorSecondary':
        return scheme.secondary;
      case 'colorOnSecondary':
        return scheme.onSecondary;
      case 'colorSecondaryContainer':
        return scheme.secondaryContainer;
      case 'colorOnSecondaryContainer':
        return scheme.onSecondaryContainer;
      case 'colorTertiary':
        return scheme.tertiary;
      case 'colorOnTertiary':
        return scheme.onTertiary;
      case 'colorTertiaryContainer':
        return scheme.tertiaryContainer;
      case 'colorOnTertiaryContainer':
        return scheme.onTertiaryContainer;
      case 'colorError':
        return scheme.error;
      case 'colorOnError':
        return scheme.onError;
      default:
        return null;
    }
  }
}
