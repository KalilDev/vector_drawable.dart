import 'dart:async';

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:path/path.dart';
import 'package:vector_drawable_core/vector_drawable_core.dart';
import 'package:vector_drawable_from_svg/vector_drawable_from_svg.dart';
import 'package:vector_drawable_style_extractor/vector_drawable_style_extractor.dart';
import 'package:xml/xml.dart';
import 'models.dart';
import 'overrides.dart';
import 'package:source_gen/source_gen.dart';
// ignore: implementation_imports
import 'package:source_gen/src/output_helpers.dart';

import 'reviving.dart';

Builder vectorDrawablePartBuilder() => SharedPartBuilder(
      [
        VectorDrawableGenerator(),
      ],
      'vector_drawable',
    );

abstract class GeneratorForManyAnnotations extends Generator {
  const GeneratorForManyAnnotations();

  List<Type> get annotationTypes;

  TypeChecker get typeChecker =>
      TypeChecker.any(annotationTypes.map(TypeChecker.fromRuntime));

  @override
  FutureOr<String> generate(LibraryReader library, BuildStep buildStep) async {
    final values = <String>{};

    for (var annotatedElement in library.annotatedWith(typeChecker)) {
      final generatedValue = generateForAnnotatedElement(
        annotatedElement.element,
        annotatedElement.annotation,
        buildStep,
      );
      await for (var value in normalizeGeneratorOutput(generatedValue)) {
        assert(value.length == value.trim().length);
        values.add(value);
      }
    }

    return values.join('\n\n');
  }

  dynamic generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  );
}

Vector inlineStyles(Vector vector, StyleResolver resolver) =>
    vector.accept(StyleInlinerVisitor(), resolver) as Vector;

typedef VectorId = AssetId;
// ignore: deprecated_member_use
AssetId assetIdForFile(String path, BuildStep buildStep) {
  final currentCodeAssetId = buildStep.inputId;
  final filePath = join(dirname(currentCodeAssetId.path), path);
  final wantedFileAssetId = AssetId(currentCodeAssetId.package, filePath);
  return wantedFileAssetId;
}

AssetId assetIdWithExtension(AssetId assetId, String extension) {
  return AssetId(assetId.package, setExtension(assetId.path, extension));
}

// ignore: deprecated_member_use
class VectorDrawableGenerator extends GeneratorForManyAnnotations {
  @override
  List<Type> get annotationTypes =>
      const [VectorFromSvg, VectorFromVd, VectorWithSomeStyles];

  static final TypeChecker vectorWithExtractedStylesTypeChecker =
      TypeChecker.fromRuntime(VectorWithExtractedStyles);

  Future<String> readFile(
    String path,
    BuildStep buildStep,
  ) {
    final vectorAssetId = assetIdForFile(path, buildStep);
    return buildStep.readAsString(vectorAssetId);
  }

  Future<XmlDocument> readXmlDocument(
    String path,
    BuildStep buildStep,
  ) async {
    return readFile(path, buildStep).then(XmlDocument.parse);
  }

  Future<SvgVectorDrawable> readSvgVectorDrawable(
    String path,
    BuildStep buildStep, {
    ResourceReference? resourceReference,
    DimensionKind dimensionKind = DimensionKind.dp,
    bool inlineTransforms = false,
    bool makeViewportVectorSized = true,
  }) {
    final package = buildStep.inputId.package;
    final name = basenameWithoutExtension(path);
    return readXmlDocument(path, buildStep).then(
      (doc) {
        var svg = SvgVectorDrawable.parseDocument(
          doc,
          resourceReference ?? ResourceReference('drawable', name, package),
          dimensionKind: dimensionKind,
          makeViewportVectorSized: false,
        );
        if (makeViewportVectorSized) {
          final vd = VectorDrawable(
            VectorViewportTransformerVisitor()
                .visitVector(svg.vectorDrawable.body) as Vector,
            svg.vectorDrawable.source,
          );
          svg = SvgVectorDrawable(vd, svg.labels);
        }
        if (inlineTransforms) {
          print('this is broken');
          final vd = VectorDrawable(
            VectorTransformInlinerVisitor().visitVector(svg.vectorDrawable.body)
                as Vector,
            svg.vectorDrawable.source,
          );
          svg = SvgVectorDrawable(vd, svg.labels);
        }
        return svg;
      },
    );
  }

  Future<VectorDrawable> readVectorDrawable(String path, BuildStep buildStep,
      {ResourceReference? resourceReference}) {
    final package = buildStep.inputId.package;
    final name = basenameWithoutExtension(path);
    return readXmlDocument(path, buildStep).then((doc) =>
        VectorDrawable.parseDocument(doc,
            resourceReference ?? ResourceReference('drawable', name, package)));
  }

  // ignore: deprecated_member_use
  AssetId vectorIdFor(VectorSource source, BuildStep buildStep) {
    final String path;
    if (source is VectorFromSvg) {
      path = source.svgPath;
    } else if (source is VectorFromVd) {
      path = source.vdPath;
    } else {
      throw TypeError();
    }
    return assetIdForFile(path, buildStep);
  }

  Future<Vector> vectorFromSource(
    // ignore: deprecated_member_use
    VectorSource source,
    BuildStep buildStep,
  ) async {
    if (source is VectorFromSvg) {
      final svgVectorDrawable = await readSvgVectorDrawable(
        source.svgPath,
        buildStep,
        dimensionKind: source.dimensionKind,
        inlineTransforms: source.inlineTransforms,
        makeViewportVectorSized: source.makeViewportVectorSized,
      );
      return svgVectorDrawable.vectorDrawable.body;
    } else if (source is VectorFromVd) {
      final vectorDrawable = await readVectorDrawable(source.vdPath, buildStep);
      return vectorDrawable.body;
    }
    throw TypeError();
  }

  dynamic generateForAnnotatedTopLevelVariable(
    TopLevelVariableElement element,
    ConstantReader annotationReader,
    BuildStep buildStep,
  ) async {
    final annotation = annotationFromReader(annotationReader);
    final variableName = element.name;
    final outputVariableName = '_\$$variableName';
    final Vector vector;
    // ignore: deprecated_member_use
    if (annotation is VectorSource) {
      vector = await vectorFromSource(annotation, buildStep);
    } else if (annotation is VectorWithSomeStyles) {
      if (vectorWithExtractedStylesTypeChecker.isExactlyType(element.type)) {
        throw StateError('dont');
      }
      final inputVector =
          await vectorFromSource(annotation.targetVector, buildStep);
      final vecWithExtractedStyles = visitAndExtractUsedStyles(inputVector);
      final overrides = overridesFromWantedStyles(annotation.wantedStyles);
      final styleResolver = ExtractedResolver.manyOverriden(
        vecWithExtractedStyles.extractedResolver,
        overrides: overrides,
      );
      vector = inlineStyles(vecWithExtractedStyles.vector, styleResolver);
    } else {
      throw TypeError();
    }
    // will we need to extract the styles?
    if (vectorWithExtractedStylesTypeChecker.isExactlyType(element.type)) {
      final processedVector = visitAndExtractUsedStyles(vector);
      final sb = StringBuffer('const ')
        ..write(outputVariableName)
        ..write(' = VectorWithExtractedStyles(');
      vector.accept(CodegenVectorDrawableVisitor(), sb);
      sb.write(', ');
      serializeConstExtractedResolver(processedVector.extractedResolver, sb);
      sb.write(');');
      return sb.toString();
    }
    // nice
    final sb = StringBuffer('const ')
      ..write(outputVariableName)
      ..write(' = ');
    vector.accept(CodegenVectorDrawableVisitor(), sb);
    sb.write(';');
    return sb.toString();
  }

  @override
  dynamic generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    if (element is TopLevelVariableElement) {
      return generateForAnnotatedTopLevelVariable(
          element, annotation, buildStep);
    }
    throw StateError(
        'The variable annotated with must be a top level variable');
  }
}
