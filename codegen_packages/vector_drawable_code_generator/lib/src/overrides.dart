import 'package:vector_drawable_annotation/vector_drawable_annotation.dart';
import 'package:vector_drawable_core/model.dart';
import 'package:vector_drawable_style_extractor/model.dart';

String unqualifiedStringFromSymbol(Symbol s) {
  final asString = s.toString();
  return asString.split('"')[1];
}

typedef ElementOverrides = Map<String, ValueOrProperty>;
Map<OverrideTarget, ElementOverrides> overridesFromWantedStyles(
  WantedStyles wantedStyles,
) {
  final acc = <OverrideTarget, ElementOverrides>{};
  for (final kv in wantedStyles.entries) {
    final type = kv.key;
    for (final kv in kv.value.entries) {
      final elementId = unqualifiedStringFromSymbol(kv.key);

      final props = <String, ValueOrProperty>{};
      for (final kv in kv.value.entries) {
        final propertyId = unqualifiedStringFromSymbol(kv.key);
        final propertyValue = kv.value;
        props[propertyId] = Property(propertyValue);
      }
      acc[OverrideTarget(type, elementId)] = props;
    }
  }
  return acc;
}
