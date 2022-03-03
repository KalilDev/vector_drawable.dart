import 'dart:collection';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:vector_drawable/src/model/path.dart';
import 'package:vector_drawable/src/model/style.dart';
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
  @override
  String toString() => '$value${kind.name}';
}

class VectorDrawable extends Resource {
  final Vector body;

  VectorDrawable(this.body, ResourceReference? source) : super(source);
  static VectorDrawable parseDocument(
          XmlDocument document, ResourceReference source) =>
      parseVectorDrawable(document.rootElement, source);
  static VectorDrawable parseElement(XmlElement element) =>
      parseVectorDrawable(element, null);
}

// https://developer.android.com/reference/android/graphics/drawable/VectorDrawable
abstract class VectorDrawableNode implements Diagnosticable {
  final String? name;
  VectorDrawableNode({
    this.name,
  });
  Iterable<StyleProperty> get _usedStyles;
  Iterable<StyleProperty> get _localUsedStyles;
  late final Set<StyleProperty> localUsedStyles = _localUsedStyles.toSet();
  late final Set<StyleProperty> usedStyles = _usedStyles.toSet();
}

abstract class VectorPart extends VectorDrawableNode {
  VectorPart({required String? name}) : super(name: name);
}

class Vector extends VectorDrawableNode with DiagnosticableTreeMixin {
  final Dimension width;
  final Dimension height;
  final double viewportWidth;
  final double viewportHeight;
  final StyleOr<Color>? tint;
  final BlendMode tintMode;
  final bool autoMirrored;
  final StyleOr<double> opacity;
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
    this.opacity = const StyleOr.value(1.0),
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
    properties.add(DiagnosticsProperty('tint', tint));
    properties
        .add(EnumProperty('tintMode', tintMode, defaultValue: BlendMode.srcIn));
    properties.add(FlagProperty(
      'autoMirrored',
      value: autoMirrored,
      defaultValue: false,
      ifTrue: 'mirrored on rtl',
    ));
    properties.add(DiagnosticsProperty('opacity', opacity, defaultValue: 1.0));
  }

  @override
  Iterable<StyleProperty> get _usedStyles =>
      children.expand((e) => e._usedStyles).followedBy(_localUsedStyles);

  @override
  Iterable<StyleProperty> get _localUsedStyles => [
        if (tint?.styled != null) tint!.styled!,
        if (opacity.styled != null) opacity.styled!,
      ];
}

class ClipPath extends VectorPart with DiagnosticableTreeMixin {
  final StyleOr<PathData> pathData;
  final List<VectorPart> children;

  ClipPath({
    String? name,
    required this.pathData,
    required this.children,
  }) : super(name: name);

  @override
  Iterable<StyleProperty> get _usedStyles =>
      _localUsedStyles.followedBy(children.expand((e) => e._usedStyles));
  @override
  Iterable<StyleProperty> get _localUsedStyles => [
        if (pathData.styled != null) pathData.styled!,
      ];

  @override
  List<DiagnosticsNode> debugDescribeChildren() =>
      children.map((e) => e.toDiagnosticsNode()).toList();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty('pathData', pathData));
  }
}

class Group extends VectorPart with DiagnosticableTreeMixin {
  final StyleOr<double>? rotation;
  final StyleOr<double>? pivotX;
  final StyleOr<double>? pivotY;
  final StyleOr<double>? scaleX;
  final StyleOr<double>? scaleY;
  final StyleOr<double>? translateX;
  final StyleOr<double>? translateY;
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
    properties.add(DiagnosticsProperty('rotation', rotation));
    properties.add(DiagnosticsProperty('pivotX', pivotX));
    properties.add(DiagnosticsProperty('pivotY', pivotY));
    properties.add(DiagnosticsProperty('scaleX', scaleX));
    properties.add(DiagnosticsProperty('scaleY', scaleY));
    properties.add(DiagnosticsProperty('translateX', translateX));
    properties.add(DiagnosticsProperty('translateY', translateY));
  }

  @override
  Iterable<StyleProperty> get _usedStyles =>
      _localUsedStyles.followedBy(children.expand((e) => e._usedStyles));
  @override
  Iterable<StyleProperty> get _localUsedStyles => [
        if (rotation?.styled != null) rotation!.styled!,
        if (pivotX?.styled != null) pivotX!.styled!,
        if (pivotY?.styled != null) pivotY!.styled!,
        if (scaleX?.styled != null) scaleX!.styled!,
        if (scaleY?.styled != null) scaleY!.styled!,
        if (translateX?.styled != null) translateX!.styled!,
        if (translateY?.styled != null) translateY!.styled!,
      ];
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
  final StyleOr<PathData> pathData;
  final StyleOr<Color>? fillColor;
  final StyleOr<Color>? strokeColor;
  final StyleOr<double> strokeWidth;
  final StyleOr<double> strokeAlpha;
  final StyleOr<double> fillAlpha;
  final StyleOr<double> trimPathStart;
  final StyleOr<double> trimPathEnd;
  final StyleOr<double> trimPathOffset;
  final StrokeLineCap strokeLineCap;
  final StrokeLineJoin strokeLineJoin;
  final double strokeMiterLimit;
  final FillType fillType;

  Path({
    required String? name,
    required this.pathData,
    required this.fillColor,
    required this.strokeColor,
    this.strokeWidth = const StyleOr.value(0),
    this.strokeAlpha = const StyleOr.value(1),
    this.fillAlpha = const StyleOr.value(1),
    this.trimPathStart = const StyleOr.value(0),
    this.trimPathEnd = const StyleOr.value(1),
    this.trimPathOffset = const StyleOr.value(0),
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
    properties
        .add(DiagnosticsProperty('strokeWidth', strokeWidth, defaultValue: 0));
    properties
        .add(DiagnosticsProperty('strokeAlpha', strokeAlpha, defaultValue: 1));
    properties
        .add(DiagnosticsProperty('fillAlpha', fillAlpha, defaultValue: 1));
    properties.add(
        DiagnosticsProperty('trimPathStart', trimPathStart, defaultValue: 0));
    properties
        .add(DiagnosticsProperty('trimPathEnd', trimPathEnd, defaultValue: 1));
    properties.add(
        DiagnosticsProperty('trimPathOffset', trimPathOffset, defaultValue: 0));
    properties.add(EnumProperty('strokeLineCap', strokeLineCap,
        defaultValue: StrokeLineCap.butt));
    properties.add(EnumProperty('strokeLineJoin', strokeLineJoin,
        defaultValue: StrokeLineJoin.miter));
    properties.add(
        DoubleProperty('strokeMiterLimit', strokeMiterLimit, defaultValue: 4));
    properties.add(
        EnumProperty('fillType', fillType, defaultValue: FillType.nonZero));
  }

  @override
  Iterable<StyleProperty> get _localUsedStyles => _usedStyles;
  @override
  Iterable<StyleProperty> get _usedStyles => [
        if (pathData.styled != null) pathData.styled!,
        if (fillColor?.styled != null) fillColor!.styled!,
        if (strokeColor?.styled != null) strokeColor!.styled!,
        if (strokeWidth.styled != null) strokeWidth.styled!,
        if (strokeAlpha.styled != null) strokeAlpha.styled!,
        if (fillAlpha.styled != null) fillAlpha.styled!,
        if (trimPathStart.styled != null) trimPathStart.styled!,
        if (trimPathEnd.styled != null) trimPathEnd.styled!,
        if (trimPathOffset.styled != null) trimPathOffset.styled!,
      ];
}
