import 'dart:collection';

import 'package:flutter/material.dart' hide ClipPath;
import 'package:vector_drawable/src/parsing/style.dart';
import 'package:xml/xml.dart';
import 'package:path_parsing/path_parsing.dart';
import 'package:path_parsing/src/path_segment_type.dart';

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
    tint: node.getStyleOrAndroidAttribute('tint', parse: parseHexColor),
    tintMode: node.getAndroidAttribute('tintMode')?.map(_parseTintMode) ??
        BlendMode.srcIn,
    autoMirrored:
        node.getAndroidAttribute('autoMirrored')?.map(parseBool) ?? false,
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
    rotation: node.getStyleOrAndroidAttribute('rotation', parse: double.parse),
    pivotX: node.getStyleOrAndroidAttribute('pivotX', parse: double.parse),
    pivotY: node.getStyleOrAndroidAttribute('pivotY', parse: double.parse),
    scaleX: node.getStyleOrAndroidAttribute('scaleX', parse: double.parse),
    scaleY: node.getStyleOrAndroidAttribute('scaleY', parse: double.parse),
    translateX:
        node.getStyleOrAndroidAttribute('translateX', parse: double.parse),
    translateY:
        node.getStyleOrAndroidAttribute('translateY', parse: double.parse),
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
    fillColor:
        node.getStyleOrAndroidAttribute('fillColor', parse: parseHexColor),
    strokeColor:
        node.getStyleOrAndroidAttribute('strokeColor', parse: parseHexColor),
    strokeWidth: node.getStyleOrAndroidAttribute(
      'strokeWidth',
      parse: double.parse,
      defaultValue: 0,
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
    case 'clip-path':
      return _parseClipPath(node);
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
