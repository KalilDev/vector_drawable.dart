import 'package:source_gen/source_gen.dart';
import 'package:vector_drawable_annotation/vector_drawable_annotation.dart';
import 'package:vector_drawable_code_generator/src/models.dart';
import 'package:vector_drawable_core/model.dart';

TypeChecker vectorFromSvgTypeChecker = TypeChecker.fromRuntime(VectorFromSvg);
TypeChecker vectorFromVdTypeChecker = TypeChecker.fromRuntime(VectorFromVd);
TypeChecker vectorWithSomeStylesTypeChecker =
    TypeChecker.fromRuntime(VectorWithSomeStyles);

// ignore: deprecated_member_use
VectorSource vectorSourceFromReader(ConstantReader reader) {
  if (reader.instanceOf(vectorFromSvgTypeChecker)) {
    return vectorFromSvgFromReader(reader);
  }
  if (reader.instanceOf(vectorFromVdTypeChecker)) {
    return vectorFromVdFromReader(reader);
  }
  throw TypeError();
}

Object annotationFromReader(ConstantReader reader) {
  if (reader.instanceOf(vectorFromSvgTypeChecker)) {
    return vectorFromSvgFromReader(reader);
  }
  if (reader.instanceOf(vectorFromVdTypeChecker)) {
    return vectorFromVdFromReader(reader);
  }
  if (reader.instanceOf(vectorWithSomeStylesTypeChecker)) {
    return vectorWithSomeStylesFromReader(reader);
  }
  print(reader.revive());
  throw TypeError();
}

VectorFromSvg vectorFromSvgFromReader(ConstantReader reader) {
  return VectorFromSvg(
    reader.read('svgPath').stringValue,
    dimensionKind: DimensionKind
        .values[reader.read('dimensionKind').read('index').intValue],
    inlineTransforms: reader.read('inlineTransforms').boolValue,
    makeViewportVectorSized: reader.read('makeViewportVectorSized').boolValue,
  );
}

VectorFromVd vectorFromVdFromReader(ConstantReader reader) {
  return VectorFromVd(reader.read('vdPath').stringValue);
}

StyleProperty stylePropertyFromReader(ConstantReader reader) {
  return StyleProperty(
      reader.read('namespace').stringValue, reader.read('name').stringValue);
}

VectorWithSomeStyles vectorWithSomeStylesFromReader(ConstantReader reader) {
  return VectorWithSomeStyles(
    vectorSourceFromReader(reader.read('targetVector')),
    wantedStyles:
        reader.read('wantedStyles').mapValue.map((nodeType, rest) => MapEntry(
              VectorDrawableNodeType
                  .values[ConstantReader(nodeType).read('index').intValue],
              ConstantReader(rest).mapValue.map((nodeName, rest) => MapEntry(
                    ConstantReader(nodeName).symbolValue,
                    ConstantReader(rest)
                        .mapValue
                        .map((propName, styleProperty) => MapEntry(
                              ConstantReader(propName).symbolValue,
                              stylePropertyFromReader(
                                  ConstantReader(styleProperty)),
                            )),
                  )),
            )),
  );
}
