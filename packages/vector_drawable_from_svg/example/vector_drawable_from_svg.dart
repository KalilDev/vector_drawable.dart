import 'dart:convert';

import 'package:vector_drawable_from_svg/vector_drawable_from_svg.dart';
import 'package:vector_drawable_core/vector_drawable_core.dart';
import 'package:vector_drawable_path_utils/vector_drawable_path_utils.dart';
import 'dart:io';

import 'package:xml/xml.dart';

extension _<T> on List<T> {
  T atOrElse(int i, T Function() orElse) {
    return length > i ? this[i] : orElse();
  }

  T atOr(int i, T orElse) {
    return length > i ? this[i] : orElse;
  }
}

Future<SvgVectorDrawable> readSvgFromPath(String svgPath, Config config) async {
  final svgFile = File(svgPath);
  final svgAbsolutePath = svgFile.absolute.path;
  final svgString = await svgFile.readAsString();
  final svgDoc = XmlDocument.parse(svgString);
  final pathComponents = svgAbsolutePath.split(Platform.pathSeparator);
  final folder = pathComponents[pathComponents.length - 2];
  final file = pathComponents[pathComponents.length - 1];
  return SvgVectorDrawable.parseDocument(
    svgDoc,
    ResourceReference(
      folder,
      file,
    ),
    dimensionKind: config.dimensionKind,
    makeViewportVectorSized: config.makeViewportVectorSized,
    //inlineTransforms: config.inlineTransforms,
  );
}

Future<void> writeVectorToPath(
  String outputCodePath,
  Vector vector,
  String outputVectorName,
) async {
  final outputCodeFile = File(outputCodePath);
  final outBuffer = StringBuffer();
  outBuffer
    ..write(r'''library generated;
import 'package:vector_drawable_core/vector_drawable_core.dart';
const Vector ''')
    ..write(outputVectorName)
    ..write(' = ');

  vector.accept(CodegenVectorDrawableVisitor(), outBuffer);
  outBuffer..write(';');
  final outString = outBuffer.toString();
  await outputCodeFile.writeAsString(outString, flush: true);
}

class Config {
  final DimensionKind dimensionKind;
  final bool makeViewportVectorSized;
  final bool inlineTransforms;

  const Config(
    this.dimensionKind,
    this.makeViewportVectorSized,
    this.inlineTransforms,
  );
  static const Config base = Config(DimensionKind.dp, true, false);

  Config copyWith({
    DimensionKind? dimensionKind,
    bool? makeViewportVectorSized,
    bool? inlineTransforms,
  }) =>
      Config(
        dimensionKind ?? this.dimensionKind,
        makeViewportVectorSized ?? this.makeViewportVectorSized,
        inlineTransforms ?? this.inlineTransforms,
      );
}

Config parseConfigFromJson(String jsonString) {
  final jsonObj = json.decode(jsonString) as Map<String, Object?>;
  final dimensionKindString = jsonObj['dimensionKind'] as String?;
  final dimensionKind = dimensionKindString == null
      ? null
      : DimensionKind.values
          .singleWhere((dk) => dk.name == dimensionKindString);
  final makeViewportVectorSized = jsonObj['makeViewportVectorSized'] as bool?;
  final inlineTransforms = jsonObj['inlineTransforms'] as bool?;
  return Config.base.copyWith(
      dimensionKind: dimensionKind,
      makeViewportVectorSized: makeViewportVectorSized,
      inlineTransforms: inlineTransforms);
}

Future<int> main(List<String> args) async {
  final svgPath = args.atOr(0, 'svg.svg');
  final outputCodePathAndVectorName = args.atOr(1, 'svg.g.dart');
  final configJson = args.atOr(2, '{"makeViewportVectorSized": false}');
  final outputCodePathAndVectorNameComponents =
      outputCodePathAndVectorName.split(':');
  final outputCodePath = outputCodePathAndVectorNameComponents[0];
  final outputVectorName =
      outputCodePathAndVectorNameComponents.atOr(1, r'$vector');

  final config = parseConfigFromJson(configJson);
  final svgVectorDrawable = await readSvgFromPath(svgPath, config);
  final vectorDrawable = svgVectorDrawable.vectorDrawable;
  final vector = vectorDrawable.body;
  await writeVectorToPath(outputCodePath, vector, outputVectorName);
  print('Wrote $outputCodePath');
  return 0;
}
