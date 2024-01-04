import 'package:vector_drawable_core/vector_drawable_core.dart';
import 'package:vector_drawable_from_svg/src/model/svg_vector_drawable.dart';
import 'package:vector_drawable_from_svg/src/visitors/extract_used_styles_visitor.dart';
import 'package:vector_drawable_from_svg/vector_drawable_from_svg.dart';
import 'dart:io';
import 'dart:convert';
import 'package:xml/xml.dart';

const filename = 'svg.svg';
const outputFilename = 'vd.xml';
const outputCodeFilename = 'code.dart';
const codeFileHeader = '''library generated;
import 'package:vector_drawable_core/vector_drawable_core.dart';


class ExtractedResolver extends StyleResolverWithEfficientContains {
  final StyleResolverWithEfficientContains _values;
  const ExtractedResolver.raw(StyleResolverWithEfficientContains values)
      : _values = values;
  const factory ExtractedResolver.overriden(
    ExtractedResolver base,
    ElementType elementType,
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
      base = base.overrideElement(t.type, t.name, overrides: o);
    }
    return base;
  }
  ExtractedResolver(Map<String, ValueOrProperty<Object>> values)
      : _values = StyleResolverWithEfficientContains.fromMap(
          values,
          namespace: 'extractedFromElement',
        );

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

  ExtractedResolver overrideElement(ElementType elementType, String elementName,
          {required Map<String, ValueOrProperty> overrides}) =>
      ExtractedResolver.overriden(this, elementType, elementName,
          overrides: overrides);
}

class OverrideTarget {
  final ElementType type;
  final String name;

  const OverrideTarget(this.type, this.name);
}

typedef ElementOverrides = Map<String, ValueOrProperty>;

class _ResolverOverride extends StyleResolverWithEfficientContains
    implements ExtractedResolver {
  final ExtractedResolver base;
  final ElementType element;
  final String elementName;
  final ElementOverrides overrides;

  const _ResolverOverride(this.base, this.element, this.elementName,
      {required this.overrides});

  @override
  bool contains(StyleProperty prop) {
    if (_values.contains(prop)) {
      return true;
    }
    if (prop.namespace != 'extractedFromElement') {
      return false;
    }
    final parsed = ElementNameTypeAndPropertyName.parse(prop.name);
    if (parsed.type != element || parsed.name != elementName) {
      return false;
    }
    return overrides.containsKey(parsed.propetyName);
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
    if (prop.namespace != 'extractedFromElement') {
      return _values.resolveUntyped(prop);
    }
    final parsed = ElementNameTypeAndPropertyName.parse(prop.name);
    if (parsed.type != element || parsed.name != elementName) {
      return _values.resolveUntyped(prop);
    }
    if (overrides.containsKey(parsed.propetyName)) {
      final p = overrides[parsed.propetyName];
      return p is Value ? p.value : p;
    }
    return _values.resolveUntyped(prop);
  }

  @override
  ExtractedResolver overrideElement(ElementType elementType, String elementName,
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
}

final drawable = ''';
Future<int> main() async {
  final file = File(filename);
  final fileString = await file.readAsString();
  final fileXml = XmlDocument.parse(fileString);
  final source = ResourceReference('pitu', 'pitusvg');
  final fileSvgVector = SvgVectorDrawable.parseDocument(fileXml, source);
  {
    final outString =
        VectorDrawable.serializeDocument(fileSvgVector.vectorDrawable)
            .toXmlString(pretty: true);
    final outFile = File(outputFilename);
    await outFile.writeAsString(outString, mode: FileMode.writeOnly);
  }
  {
    final extractStyles = true;
    final styles = <ElementNameTypeAndPropertyName, ValueOrProperty<Object>>{};
    final vector = extractStyles
        ? VectorDrawable(
            fileSvgVector.vectorDrawable.body
                .accept(ExtractUsedStylesVisitor(), styles) as Vector,
            fileSvgVector.vectorDrawable.source)
        : fileSvgVector.vectorDrawable;
    final outBuffer = StringBuffer(codeFileHeader);
    CodegenVectorDrawableVisitor().visitVectorDrawable(vector, outBuffer);
    outBuffer.writeln(';');
    String serializeValue(ValueOrProperty value) => value is! Value<PathData>
        ? value.toString()
        : value.toString((pd) {
            final pathString = "'${pd.toPathDataString(
              needsSameInput: true,
            )}'";
            return 'PathData.fromStringRaw($pathString)';
          });
    if (extractStyles) {
      outBuffer.writeln('/// Style resolver');
      outBuffer.write(
          'const styleResolver = ExtractedResolver.raw(StyleResolverWithEfficientContains.fromMap(');
      outBuffer.write(
        styles.map(
          (key, value) => MapEntry(
            "'${key.generatedPropertyName}'",
            serializeValue(value),
          ),
        ),
      );
      outBuffer.write(", namespace: 'extractedFromElement'");
      outBuffer.write('));');
    }
    final outString = outBuffer.toString();
    final outFile = File(outputCodeFilename);
    await outFile.writeAsString(outString, mode: FileMode.writeOnly);
  }
  return 0;
}
