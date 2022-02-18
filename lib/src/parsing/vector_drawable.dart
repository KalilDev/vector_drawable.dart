import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:xml/xml.dart';
import 'package:path_parsing/path_parsing.dart';
import 'package:path_parsing/src/path_segment_type.dart';

import '../model/resource.dart';
import '../model/vector_drawable.dart';
import 'exception.dart';
import 'util.dart';

VectorDrawable parseVectorDrawable(
        XmlHasChildren doc, ResourceReference? source) =>
    VectorDrawable(
      _parseVector(doc.childElements.single),
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
    tint: node.getAndroidAttribute('tint')?.map(parseHexColor),
    tintMode: node.getAndroidAttribute('tintMode')?.map(_parseTintMode) ??
        BlendMode.srcIn,
    autoMirrored:
        node.getAndroidAttribute('autoMirrored')?.map(parseBool) ?? false,
    opacity: node.getAndroidAttribute('opacity')?.map(double.parse) ?? 1.0,
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
    rotation: node.getAndroidAttribute('rotation')?.map(double.parse),
    pivotX: node.getAndroidAttribute('pivotX')?.map(double.parse),
    pivotY: node.getAndroidAttribute('pivotY')?.map(double.parse),
    scaleX: node.getAndroidAttribute('scaleX')?.map(double.parse),
    scaleY: node.getAndroidAttribute('scaleY')?.map(double.parse),
    translateX: node.getAndroidAttribute('translateX')?.map(double.parse),
    translateY: node.getAndroidAttribute('translateY')?.map(double.parse),
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
    pathData: node.getAndroidAttribute('pathData')!.map(PathData.fromString),
    fillColor:
        node.getAndroidAttribute('fillColor')?.map(ColorOrStyleColor.parse),
    strokeColor:
        node.getAndroidAttribute('strokeColor')?.map(ColorOrStyleColor.parse),
    strokeWidth:
        node.getAndroidAttribute('strokeWidth')?.map(double.parse) ?? 0,
    strokeAlpha:
        node.getAndroidAttribute('strokeAlpha')?.map(double.parse) ?? 1,
    fillAlpha: node.getAndroidAttribute('fillAlpha')?.map(double.parse) ?? 1,
    trimPathStart:
        node.getAndroidAttribute('trimPathStart')?.map(double.parse) ?? 0,
    trimPathEnd:
        node.getAndroidAttribute('trimPathEnd')?.map(double.parse) ?? 1,
    trimPathOffset:
        node.getAndroidAttribute('trimPathOffset')?.map(double.parse) ?? 0,
    strokeLineCap:
        node.getAndroidAttribute('strokeLineCap')?.map(_parseStrokeLineCap) ??
            StrokeLineCap.butt,
    strokeLineJoin:
        node.getAndroidAttribute('strokeLineJoin')?.map(_parseStrokeLineJoin) ??
            StrokeLineJoin.miter,
    strokeMiterLimit:
        node.getAndroidAttribute('strokeMiterLimit')?.map(double.parse) ?? 4,
    fillType: node.getAndroidAttribute('fillType')?.map(_parseFillType) ??
        FillType.nonZero,
  );
}

VectorPart? _parseVectorPart(XmlElement node) {
  switch (node.name.qualified) {
    case 'group':
      return _parseGroup(node);
    case 'path':
      return _parsePath(node);
    default:
      return null;
  }
}

BlendMode? _parseTintMode(String tintMode) {
  switch (tintMode) {
    case 'add':
      return BlendMode.plus;
    case 'multiply':
      return BlendMode.multiply;
    case 'screen':
      return BlendMode.screen;
    case 'src_atop':
      return BlendMode.srcATop;
    case 'src_in':
      return BlendMode.srcIn;
    case 'src_over':
      return BlendMode.srcOver;
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
