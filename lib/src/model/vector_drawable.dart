import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:xml/xml.dart';
import 'package:path_parsing/path_parsing.dart';
import 'package:path_parsing/src/path_segment_type.dart';

import '../parsing/util.dart';
import '../parsing/vector_drawable.dart';
import 'resource.dart';

// TODO: pt, mm, in
enum DimensionKind { dip, dp, px, sp }

class Dimension {
  final double value;
  final DimensionKind kind;

  Dimension(this.value, this.kind);
}

class VectorDrawable extends Resource {
  final Vector body;

  VectorDrawable(this.body, ResourceReference? source) : super(source);
  static VectorDrawable parseDocument(
          XmlDocument document, ResourceReference source) =>
      parseVectorDrawable(document, source);
  static VectorDrawable parseElement(XmlElement element) =>
      parseVectorDrawable(element, null);
}

// https://developer.android.com/reference/android/graphics/drawable/VectorDrawable
abstract class VectorDrawableNode implements Diagnosticable {
  final String? name;
  VectorDrawableNode({
    this.name,
  });
}

abstract class VectorPart extends VectorDrawableNode {
  VectorPart({required String? name}) : super(name: name);
}

class Vector extends VectorDrawableNode with DiagnosticableTreeMixin {
  final Dimension width;
  final Dimension height;
  final double viewportWidth;
  final double viewportHeight;
  final Color? tint;
  final BlendMode tintMode;
  final bool autoMirrored;
  final double opacity;
  final List<VectorPart> children;

  Vector({
    required String? name,
    required this.width,
    required this.height,
    required this.viewportWidth,
    required this.viewportHeight,
    required this.tint,
    this.tintMode = BlendMode.srcIn,
    this.autoMirrored = false,
    this.opacity = 1.0,
    required this.children,
  }) : super(name: name);

  @override
  List<DiagnosticsNode> debugDescribeChildren() =>
      children.map((e) => e.toDiagnosticsNode()).toList();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty('width', width));
    properties.add(DiagnosticsProperty('height', height));
    properties.add(DoubleProperty('viewportWidth', viewportWidth));
    properties.add(DoubleProperty('viewportHeight', viewportHeight));
    properties.add(ColorProperty('tint', tint));
    properties
        .add(EnumProperty('tintMode', tintMode, defaultValue: BlendMode.srcIn));
    properties.add(
        FlagProperty('autoMirrored', value: autoMirrored, defaultValue: false));
    properties.add(DoubleProperty('opacity', opacity, defaultValue: 1.0));
  }

  Iterable<StyleColor> _expandColorsFromVectorPart(VectorPart part) =>
      part is Group
          ? part.children.expand(_expandColorsFromVectorPart)
          : part is Path
              ? [
                  if (part.strokeColor?.styleColor != null)
                    part.strokeColor!.styleColor!,
                  if (part.fillColor?.styleColor != null)
                    part.fillColor!.styleColor!,
                ]
              : [];

  late final Set<StyleColor> usedColors =
      (children.expand(_expandColorsFromVectorPart)).toSet();
}

class PathData {
  PathData.fromString(String asString) : _asString = asString;
  PathData.fromSegments(Iterable<PathSegmentData> segments)
      : _segments = segments.toList();
  String? _asString;
  List<PathSegmentData>? _segments;
  static List<PathSegmentData> _parse(String asString) {
    final SvgPathStringSource parser = SvgPathStringSource(asString);
    try {
      return parser.parseSegments().toList();
    } catch (e) {
      print(e);
      return [];
    }
  }

  static String _toString(List<PathSegmentData> segments) {
    final result = StringBuffer();
    throw UnimplementedError('TODO');
    return result.toString();
  }

  UnmodifiableListView<PathSegmentData> get segments =>
      UnmodifiableListView(_segments ??= _parse(_asString!));

  String get asString => _asString ??= _toString(segments);
}

class Group extends VectorPart with DiagnosticableTreeMixin {
  final double? rotation;
  final double? pivotX;
  final double? pivotY;
  final double? scaleX;
  final double? scaleY;
  final double? translateX;
  final double? translateY;
  final List<VectorPart> children;

  Group({
    required String? name,
    required this.rotation,
    required this.pivotX,
    required this.pivotY,
    required this.scaleX,
    required this.scaleY,
    required this.translateX,
    required this.translateY,
    required this.children,
  }) : super(name: name);

  @override
  List<DiagnosticsNode> debugDescribeChildren() =>
      children.map((e) => e.toDiagnosticsNode()).toList();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DoubleProperty('rotation', rotation));
    properties.add(DoubleProperty('pivotX', pivotX));
    properties.add(DoubleProperty('pivotY', pivotY));
    properties.add(DoubleProperty('scaleX', scaleX));
    properties.add(DoubleProperty('scaleY', scaleY));
    properties.add(DoubleProperty('translateX', translateX));
    properties.add(DoubleProperty('translateY', translateY));
  }
}

class ColorOrStyleColor {
  final Color? color;
  final StyleColor? styleColor;

  ColorOrStyleColor.styleColor(this.styleColor) : color = null;
  ColorOrStyleColor.color(this.color) : styleColor = null;
  factory ColorOrStyleColor.parse(String colorOrThemeColor) {
    if (colorOrThemeColor.startsWith('#')) {
      return ColorOrStyleColor.color(parseHexColor(colorOrThemeColor));
    } else if (colorOrThemeColor.startsWith('?')) {
      return ColorOrStyleColor.styleColor(
          StyleColor.fromString(colorOrThemeColor));
    } else {
      throw UnimplementedError();
    }
  }
}

class StyleColor {
  final String namespace;
  final String name;

  const StyleColor(this.namespace, this.name);
  factory StyleColor.fromString(String themeColor) {
    if (!themeColor.startsWith('?')) {
      throw StateError('');
    }
    final split = themeColor.split(':');
    if (split.length != 2 && split.length != 1) {
      throw StateError('');
    }
    return StyleColor(split.length == 1 ? '' : split[0].substring(1),
        split.length == 1 ? split[0].substring(1) : split[1]);
  }
  int get hashCode => Object.hashAll([namespace, name]);
  bool operator ==(other) =>
      other is StyleColor && other.namespace == namespace && other.name == name;
}

enum FillType { nonZero, evenOdd }
enum StrokeLineCap {
  butt,
  round,
  square,
}
enum StrokeLineJoin {
  miter,
  round,
  bevel,
}

class Path extends VectorPart with Diagnosticable {
  final PathData pathData;
  final ColorOrStyleColor? fillColor;
  final ColorOrStyleColor? strokeColor;
  final double strokeWidth;
  final double strokeAlpha;
  final double fillAlpha;
  final double trimPathStart;
  final double trimPathEnd;
  final double trimPathOffset;
  final StrokeLineCap strokeLineCap;
  final StrokeLineJoin strokeLineJoin;
  final double strokeMiterLimit;
  final FillType fillType;

  Path({
    required String? name,
    required this.pathData,
    required this.fillColor,
    required this.strokeColor,
    this.strokeWidth = 0,
    this.strokeAlpha = 1,
    this.fillAlpha = 1,
    this.trimPathStart = 0,
    this.trimPathEnd = 1,
    this.trimPathOffset = 0,
    this.strokeLineCap = StrokeLineCap.butt,
    this.strokeLineJoin = StrokeLineJoin.miter,
    this.strokeMiterLimit = 4,
    this.fillType = FillType.nonZero,
  }) : super(name: name);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('name', name));
    properties.add(DiagnosticsProperty('pathData', pathData));
    properties.add(DiagnosticsProperty('fillColor', fillColor));
    properties.add(DiagnosticsProperty('strokeColor', strokeColor));
    properties.add(DoubleProperty('strokeWidth', strokeWidth, defaultValue: 0));
    properties.add(DoubleProperty('strokeAlpha', strokeAlpha, defaultValue: 1));
    properties.add(DoubleProperty('fillAlpha', fillAlpha, defaultValue: 1));
    properties
        .add(DoubleProperty('trimPathStart', trimPathStart, defaultValue: 0));
    properties.add(DoubleProperty('trimPathEnd', trimPathEnd, defaultValue: 1));
    properties
        .add(DoubleProperty('trimPathOffset', trimPathOffset, defaultValue: 0));
    properties.add(EnumProperty('strokeLineCap', strokeLineCap,
        defaultValue: StrokeLineCap.butt));
    properties.add(EnumProperty('strokeLineJoin', strokeLineJoin,
        defaultValue: StrokeLineJoin.miter));
    properties.add(
        DoubleProperty('strokeMiterLimit', strokeMiterLimit, defaultValue: 4));
    properties.add(
        EnumProperty('fillType', fillType, defaultValue: FillType.nonZero));
  }
}
