import 'style.dart';
import 'package:xml/xml.dart';

import '../model/color.dart';
import '../model/path.dart';
import '../model/resource.dart';
import '../model/vector_drawable.dart';
import 'exception.dart';
import 'util.dart';

VectorDrawable parseVectorDrawable(XmlElement doc, ResourceReference? source) =>
    VectorDrawable(
      _parseVector(doc),
      source,
    );

Vector _parseVector(XmlElement node) {
  if (node.name.qualified != 'vector') {
    throw ParseException(node, 'is not an vector');
  }
  return Vector(
    name: node.getAndroidAttribute('name'),
    width: _parseDimension(node.getAndroidAttribute('width')!),
    height: _parseDimension(node.getAndroidAttribute('height')!),
    viewportWidth: double.parse(node.getAndroidAttribute('viewportWidth')!),
    viewportHeight: double.parse(node.getAndroidAttribute('viewportHeight')!),
    tint: node.getStyleOrAndroidAttribute('tint',
        parse: parseHexColor, defaultValue: VectorColor.transparent)!,
    tintMode: node.getAndroidAttribute('tintMode')?.mapSelfTo(_parseTintMode) ??
        TintMode.srcIn,
    autoMirrored:
        node.getAndroidAttribute('autoMirrored')?.mapSelfTo(parseBool) ?? false,
    opacity: node.getStyleOrAndroidAttribute(
      'opacity',
      parse: double.parse,
      defaultValue: 1.0,
    )!,
    children: node.childElements
        .map(_parseVectorPart)
        .whereType<VectorPart>()
        .toList(),
  );
}

Group? _parseGroup(XmlElement node) {
  if (node.name.qualified != 'group') {
    throw ParseException(node, 'is not group');
  }

  return Group(
    name: node.getAndroidAttribute('name'),
    rotation: node.getStyleOrAndroidAttribute('rotation',
        parse: double.parse, defaultValue: 0.0)!,
    pivotX: node.getStyleOrAndroidAttribute('pivotX',
        parse: double.parse, defaultValue: 0.0)!,
    pivotY: node.getStyleOrAndroidAttribute('pivotY',
        parse: double.parse, defaultValue: 0.0)!,
    scaleX: node.getStyleOrAndroidAttribute('scaleX',
        parse: double.parse, defaultValue: 1.0)!,
    scaleY: node.getStyleOrAndroidAttribute('scaleY',
        parse: double.parse, defaultValue: 1.0)!,
    translateX: node.getStyleOrAndroidAttribute('translateX',
        parse: double.parse, defaultValue: 0.0)!,
    translateY: node.getStyleOrAndroidAttribute('translateY',
        parse: double.parse, defaultValue: 0.0)!,
    children: node.childElements
        .map(_parseVectorPart)
        .whereType<VectorPart>()
        .toList(),
  );
}

ClipPath? _parseClipPath(XmlElement node) {
  if (node.name.qualified != 'clip-path') {
    throw ParseException(node, 'is not clip-path');
  }

  return ClipPath(
    name: node.getAndroidAttribute('name'),
    pathData: node.getStyleOrAndroidAttribute('pathData',
        parse: PathData.fromString)!,
    children: node.childElements
        .map(_parseVectorPart)
        .whereType<VectorPart>()
        .toList(),
  );
}

StrokeLineCap? _parseStrokeLineCap(String text) =>
    parseEnum(text, StrokeLineCap.values);
StrokeLineJoin? _parseStrokeLineJoin(String text) =>
    parseEnum(text, StrokeLineJoin.values);
FillType? _parseFillType(String text) => parseEnum(text, FillType.values);

Path? _parsePath(XmlElement node) {
  if (node.name.qualified != 'path') {
    throw ParseException(node, 'is not path');
  }
  return Path(
    name: node.getAndroidAttribute('name'),
    pathData: node.getStyleOrAndroidAttribute('pathData',
        parse: PathData.fromString)!,
    fillColor: node.getStyleOrAndroidAttribute('fillColor',
        parse: parseHexColor, defaultValue: VectorColor.transparent)!,
    strokeColor: node.getStyleOrAndroidAttribute('strokeColor',
        parse: parseHexColor, defaultValue: VectorColor.transparent)!,
    strokeWidth: node.getStyleOrAndroidAttribute(
      'strokeWidth',
      parse: double.parse,
      defaultValue: 0.0,
    )!,
    strokeAlpha: node.getStyleOrAndroidAttribute(
      'strokeAlpha',
      parse: double.parse,
      defaultValue: 1,
    )!,
    fillAlpha: node.getStyleOrAndroidAttribute(
      'fillAlpha',
      parse: double.parse,
      defaultValue: 1,
    )!,
    trimPathStart: node.getStyleOrAndroidAttribute(
      'trimPathStart',
      parse: double.parse,
      defaultValue: 0,
    )!,
    trimPathEnd: node.getStyleOrAndroidAttribute(
      'trimPathEnd',
      parse: double.parse,
      defaultValue: 1,
    )!,
    trimPathOffset: node.getStyleOrAndroidAttribute(
      'trimPathOffset',
      parse: double.parse,
      defaultValue: 0,
    )!,
    strokeLineCap: node
            .getAndroidAttribute('strokeLineCap')
            ?.mapSelfTo(_parseStrokeLineCap) ??
        StrokeLineCap.butt,
    strokeLineJoin: node
            .getAndroidAttribute('strokeLineJoin')
            ?.mapSelfTo(_parseStrokeLineJoin) ??
        StrokeLineJoin.miter,
    strokeMiterLimit:
        node.getAndroidAttribute('strokeMiterLimit')?.mapSelfTo(double.parse) ??
            4,
    fillType: node.getAndroidAttribute('fillType')?.mapSelfTo(_parseFillType) ??
        FillType.nonZero,
  );
}

VectorPart? _parseVectorPart(XmlElement node) {
  switch (node.name.qualified) {
    case 'group':
      return _parseGroup(node);
    case 'path':
      return _parsePath(node);
    case 'clip-path':
      return _parseClipPath(node);
    default:
      return null;
  }
}

TintMode? _parseTintMode(String tintMode) {
  switch (tintMode) {
    case 'add':
      return TintMode.plus;
    case 'multiply':
      return TintMode.multiply;
    case 'screen':
      return TintMode.screen;
    case 'src_atop':
      return TintMode.srcATop;
    case 'src_in':
      return TintMode.srcIn;
    case 'src_over':
      return TintMode.srcOver;
    default:
      return null;
  }
}

Dimension _parseDimension(String text) => DimensionKind.values
    .map(
      (kind) => text.endsWith(kind.name)
          ? Dimension(
              double.parse(
                text.substring(0, text.length - kind.name.length),
              ),
              kind,
            )
          : null,
    )
    .whereType<Dimension>()
    .single;
