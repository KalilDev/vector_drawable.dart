import 'package:vector_drawable_core/model.dart';
import 'package:vector_drawable_core/vector_drawable_core.dart';
import 'package:vector_drawable_style_extractor/model.dart';

void serializeConstExtractedResolver(ExtractedResolver resolver,
    [StringBuffer? out]) {
  out ??= StringBuffer();
  final rawValues = resolver.rawValues();
  final styles = <NodeTypeNameAndProperty, ValueOrProperty>{};
  for (final kv in rawValues.entries) {
    final type = kv.key;
    for (final kv in kv.value.entries) {
      final nodeName = kv.key;
      for (final kv in kv.value.entries) {
        final propertyName = kv.key;
        final propertyOrValue = kv.value;

        final id = NodeTypeNameAndProperty(nodeName, type, propertyName);
        styles[id] = propertyOrValue;
      }
    }
  }
  out.write(
      'ExtractedResolver.raw(StyleResolverWithEfficientContains.fromMap(');
  out.write(
    styles.map(
      (key, value) => MapEntry(
        "'${key.generatedPropertyName}'",
        _serializeValue(value),
      ),
    ),
  );
  out.write(", namespace: 'extractedFromNode'");
  out.write('),');
  out.write(
    styles.map(
      (key, value) => MapEntry(
        "'${key.generatedPropertyName}'",
        _serializeValue(value),
      ),
    ),
  );
  out.write(')');
}

String _serializeValue(ValueOrProperty value) {
  if (value is Value<PathData>) {
    return value.toString((pd) {
      final pathString = "'${pd.toPathDataString(
        needsSameInput: true,
      )}'";
      return 'PathData.fromStringRaw($pathString)';
    });
  }
  if (value is Value<TransformOrTransformList>) {
    return value.toString(
      (totl) => visitTransformOrTransformList(totl, StringBuffer()).toString(),
    );
  }
  return value.toString();
}

void serializeExtractedResolver(ExtractedResolver resolver,
    [StringBuffer? out]) {
  out ??= StringBuffer();
  final rawValues = resolver.rawValues();
  final styles = <NodeTypeNameAndProperty, ValueOrProperty>{};
  for (final kv in rawValues.entries) {
    final type = kv.key;
    for (final kv in kv.value.entries) {
      final nodeName = kv.key;
      for (final kv in kv.value.entries) {
        final propertyName = kv.key;
        final propertyOrValue = kv.value;

        final id = NodeTypeNameAndProperty(nodeName, type, propertyName);
        styles[id] = propertyOrValue;
      }
    }
  }
  out.write('ExtractedResolver(');
  out.write(
    styles.map(
      (key, value) => MapEntry(
        "'${key.generatedPropertyName}'",
        _serializeValue(value),
      ),
    ),
  );
  out.write(')');
}
