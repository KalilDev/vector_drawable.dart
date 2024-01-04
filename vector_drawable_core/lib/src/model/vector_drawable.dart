// ignore_for_file: deprecated_member_use_from_same_package

import 'dart:collection';

import 'package:vector_drawable_core/vector_drawable_core.dart';

import 'path.dart';
import 'style.dart';
import '../serializing/vector_drawable.dart';
import 'package:xml/xml.dart';
import '../parsing/vector_drawable.dart';
import 'color.dart';
import 'diagnostics.dart';
import 'resource.dart';

enum TintMode { plus, multiply, screen, srcATop, srcIn, srcOver }

// TODO: pt, mm, in
enum DimensionKind { dip, dp, px, sp }

class Dimension extends VectorDiagnosticable {
  final double value;
  final DimensionKind kind;

  const Dimension(this.value, this.kind);
  @override
  String toString() => '$value${kind.name}';

  @override
  List<VectorProperty<void>> properties() => [
        VectorDoubleProperty('value', value),
        VectorEnumProperty<DimensionKind>('kind', kind)
      ];
}

extension DimensionFromDoubleE on double {
  Dimension get dip => Dimension(this, DimensionKind.dip);
  Dimension get dp => Dimension(this, DimensionKind.dp);
  Dimension get px => Dimension(this, DimensionKind.px);
  Dimension get sp => Dimension(this, DimensionKind.sp);
  // TODO
  /*Dimension get pt => Dimension(this, DimensionKind.pt);
  Dimension get mm => Dimension(this, DimensionKind.mm);
  Dimension get in => Dimension(this, DimensionKind.in);*/
}

class VectorDrawable extends Resource {
  final Vector body;

  VectorDrawable(this.body, ResourceReference? source) : super(source);
  static VectorDrawable parseDocument(
          XmlDocument document, ResourceReference source) =>
      parseVectorDrawable(document.rootElement, source);
  static VectorDrawable parseElement(XmlElement element) =>
      parseVectorDrawable(element, null);

  static XmlDocument serializeDocument(VectorDrawable drawable) {
    final builder = XmlBuilder();
    serializeElement(builder, drawable);
    return builder.buildDocument();
  }

  static void serializeElement(XmlBuilder b, VectorDrawable drawable) =>
      serializeVectorDrawable(b, drawable);

  R accept<R, Context>(VectorDrawableRawVisitor<R, Context> visitor,
          [Context? context]) =>
      visitor.visitVectorDrawable(this, context);
}

/*extension ExpandoPutIfAbsent<T extends Object> on Expando<T> {
  T putIfAbsent(Object obj, T Function() ifAbsent) {
    final res = this[obj];
    if (res != null) {
      return res;
    }
    return this[obj] = ifAbsent();
  }
}*/

final Expando<Set<StyleProperty>> _usedStylesExpando =
    Expando('VectorDrawableNode.usedStyles');

final Expando<List<ValueOrProperty<Object>>> _localValuesOrPropertiesExpando =
    Expando('VectorDrawableNode.localValuesOrProperties');

// https://developer.android.com/reference/android/graphics/drawable/VectorDrawable
abstract class VectorDrawableNode implements VectorDiagnosticable {
  final String? name;
  const VectorDrawableNode({
    this.name,
  });
  Iterable<StyleProperty> get _usedStyles;
  List<ValueOrProperty<Object>> get _localValuesOrProperties;
  List<ValueOrProperty<Object>> get localValuesOrProperties =>
      _localValuesOrPropertiesExpando.putIfAbsent(
          this, () => UnmodifiableListView(_localValuesOrProperties));
  Set<StyleProperty> get usedStyles =>
      _usedStylesExpando.putIfAbsent(this, _usedStyles.toSet);
  R accept<R, Context>(VectorDrawableNodeRawVisitor<R, Context> visitor,
      [Context? context]);
}

abstract class VectorPart extends VectorDrawableNode {
  const VectorPart({required String? name}) : super(name: name);
  @override
  R accept<R, Context>(VectorDrawablePartRawVisitor<R, Context> visitor,
      [Context? context]);
}

class Vector extends VectorDrawableNode with VectorDiagnosticableTreeMixin {
  final Dimension width;
  final Dimension height;
  final double viewportWidth;
  final double viewportHeight;
  final StyleOr<VectorColor> tint;
  final TintMode tintMode;
  final bool autoMirrored;
  final StyleOr<double> opacity;
  final List<VectorPart> children;

  const Vector({
    String? name,
    required this.width,
    required this.height,
    required this.viewportWidth,
    required this.viewportHeight,
    this.tint = const Value<VectorColor>(VectorColor.transparent),
    this.tintMode = TintMode.srcIn,
    this.autoMirrored = false,
    this.opacity = const Value<double>(1.0),
    required this.children,
  }) : super(name: name);
  @override
  List<VectorDiagnosticsNode> diagnosticsChildren() =>
      children.map((e) => e.toDiagnosticsNode()).toList();

  @override
  List<VectorProperty<void>> properties() => [
        VectorNullableProperty<String>('name', name),
        VectorProperty<Dimension>('width', width),
        VectorProperty<Dimension>('height', height),
        VectorDoubleProperty('viewportWidth', viewportWidth),
        VectorDoubleProperty('viewportHeight', viewportHeight),
        VectorStyleableProperty<VectorColor>('tint', tint),
        VectorEnumProperty<TintMode>('tintMode', tintMode,
            defaultValue: TintMode.srcIn),
        VectorFlagProperty(
          'autoMirrored',
          value: autoMirrored,
          defaultValue: false,
          ifTrue: 'mirrored on rtl',
        ),
        VectorStyleableProperty<double>.withDefault('opacity', opacity,
            defaultValue: 1.0)
      ];

  @override
  Iterable<StyleProperty> get _usedStyles =>
      children.expand((e) => e._usedStyles).followedBy(_localUsedStyles);

  @override
  List<ValueOrProperty<Object>> get _localValuesOrProperties => [
        tint,
        opacity,
      ];

  static const List<String> stylablePropertyNames = [
    'tint',
    'opacity',
  ];

  @override
  Iterable<StyleProperty> get _localUsedStyles => [
        if (tint.styled != null) tint.styled!,
        if (opacity.styled != null) opacity.styled!,
      ];
  @override
  VectorDiagnosticsNode toDiagnosticsNode([String? name]) =>
      super.toDiagnosticsNode(this.name);
  @override
  R accept<R, Context>(VectorDrawableNodeRawVisitor<R, Context> visitor,
          [Context? context]) =>
      visitor.visitVector(this, context);
}

class ClipPath extends VectorPart with VectorDiagnosticableTreeMixin {
  final StyleOr<PathData> pathData;
  final List<VectorPart> children;

  const ClipPath({
    String? name,
    required this.pathData,
    required this.children,
  }) : super(name: name);

  @override
  Iterable<StyleProperty> get _usedStyles =>
      _localUsedStyles.followedBy(children.expand((e) => e._usedStyles));

  @override
  List<ValueOrProperty<Object>> get _localValuesOrProperties => [pathData];

  static const List<String> stylablePropertyNames = [
    'pathData',
  ];

  @override
  Iterable<StyleProperty> get _localUsedStyles => [
        if (pathData.styled != null) pathData.styled!,
      ];

  @override
  List<VectorDiagnosticsNode> diagnosticsChildren() =>
      children.map((e) => e.toDiagnosticsNode()).toList();

  @override
  List<VectorProperty<void>> properties() => [
        VectorNullableProperty<String>('name', name),
        VectorStyleableProperty<PathData>('pathData', pathData),
      ];
  @override
  VectorDiagnosticsNode toDiagnosticsNode([String? name]) =>
      super.toDiagnosticsNode(this.name);

  @override
  R accept<R, Context>(VectorDrawablePartRawVisitor<R, Context> visitor,
          [Context? context]) =>
      visitor.visitClipPath(this, context);
}

class Group extends VectorPart with VectorDiagnosticableTreeMixin {
  final StyleOr<double> rotation;
  final StyleOr<double> pivotX;
  final StyleOr<double> pivotY;
  final StyleOr<double> scaleX;
  final StyleOr<double> scaleY;
  final StyleOr<double> translateX;
  final StyleOr<double> translateY;
  final List<VectorPart> children;

  const Group({
    String? name,
    this.rotation = const Value<double>(0.0),
    this.pivotX = const Value<double>(0.0),
    this.pivotY = const Value<double>(0.0),
    this.scaleX = const Value<double>(1.0),
    this.scaleY = const Value<double>(1.0),
    this.translateX = const Value<double>(0.0),
    this.translateY = const Value<double>(0.0),
    required this.children,
  }) : super(name: name);

  @override
  List<VectorDiagnosticsNode> diagnosticsChildren() =>
      children.map((e) => e.toDiagnosticsNode()).toList();

  @override
  List<VectorProperty<void>> properties() => [
        VectorNullableProperty('name', name),
        VectorStyleableProperty<double>.withDefault('rotation', rotation,
            defaultValue: 0.0),
        VectorStyleableProperty<double>.withDefault('pivotX', pivotX,
            defaultValue: 0.0),
        VectorStyleableProperty<double>.withDefault('pivotY', pivotY,
            defaultValue: 0.0),
        VectorStyleableProperty<double>.withDefault('scaleX', scaleX,
            defaultValue: 1.0),
        VectorStyleableProperty<double>.withDefault('scaleY', scaleY,
            defaultValue: 1.0),
        VectorStyleableProperty<double>.withDefault('translateX', translateX,
            defaultValue: 0.0),
        VectorStyleableProperty<double>.withDefault('translateY', translateY,
            defaultValue: 0.0),
      ];

  @override
  Iterable<StyleProperty> get _usedStyles =>
      _localUsedStyles.followedBy(children.expand((e) => e._usedStyles));
  @override
  Iterable<StyleProperty> get _localUsedStyles => [
        if (rotation.styled != null) rotation.styled!,
        if (pivotX.styled != null) pivotX.styled!,
        if (pivotY.styled != null) pivotY.styled!,
        if (scaleX.styled != null) scaleX.styled!,
        if (scaleY.styled != null) scaleY.styled!,
        if (translateX.styled != null) translateX.styled!,
        if (translateY.styled != null) translateY.styled!,
      ];

  @override
  List<ValueOrProperty<Object>> get _localValuesOrProperties => [
        rotation,
        pivotX,
        pivotY,
        scaleX,
        scaleY,
        translateX,
        translateY,
      ];

  static const List<String> stylablePropertyNames = [
    'rotation',
    'pivotX',
    'pivotY',
    'scaleX',
    'scaleY',
    'translateX',
    'translateY',
  ];

  @override
  VectorDiagnosticsNode toDiagnosticsNode([String? name]) =>
      super.toDiagnosticsNode(this.name);

  @override
  R accept<R, Context>(VectorDrawablePartRawVisitor<R, Context> visitor,
          [Context? context]) =>
      visitor.visitGroup(this, context);
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

class Path extends VectorPart with VectorDiagnosticableMixin {
  final StyleOr<PathData> pathData;
  final StyleOr<VectorColor> fillColor;
  final StyleOr<VectorColor> strokeColor;
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

  const Path({
    String? name,
    required this.pathData,
    this.fillColor = const Value<VectorColor>(VectorColor.transparent),
    this.strokeColor = const Value<VectorColor>(VectorColor.transparent),
    this.strokeWidth = const Value<double>(0.0),
    this.strokeAlpha = const Value<double>(1.0),
    this.fillAlpha = const Value<double>(1.0),
    this.trimPathStart = const Value<double>(0.0),
    this.trimPathEnd = const Value<double>(1.0),
    this.trimPathOffset = const Value<double>(0.0),
    this.strokeLineCap = StrokeLineCap.butt,
    this.strokeLineJoin = StrokeLineJoin.miter,
    this.strokeMiterLimit = 4.0,
    this.fillType = FillType.nonZero,
  }) : super(name: name);

  @override
  List<VectorProperty<void>> properties() => [
        VectorNullableProperty<String>('name', name),
        VectorStyleableProperty<PathData>('pathData', pathData),
        VectorStyleableProperty<VectorColor>.withDefault('fillColor', fillColor,
            defaultValue: VectorColor.transparent),
        VectorStyleableProperty<VectorColor>.withDefault(
            'strokeColor', strokeColor,
            defaultValue: VectorColor.transparent),
        VectorStyleableProperty<double>.withDefault('strokeWidth', strokeWidth,
            defaultValue: 0.0),
        VectorStyleableProperty<double>.withDefault('strokeAlpha', strokeAlpha,
            defaultValue: 0.0),
        VectorStyleableProperty<double>.withDefault('fillAlpha', fillAlpha,
            defaultValue: 1.0),
        VectorStyleableProperty<double>.withDefault(
            'trimPathStart', trimPathStart,
            defaultValue: 0.0),
        VectorStyleableProperty<double>.withDefault('trimPathEnd', trimPathEnd,
            defaultValue: 1.0),
        VectorStyleableProperty<double>.withDefault(
            'trimPathOffset', trimPathOffset,
            defaultValue: 0.0),
        VectorEnumProperty<StrokeLineCap>('strokeLineCap', strokeLineCap,
            defaultValue: StrokeLineCap.butt),
        VectorEnumProperty<StrokeLineJoin>('strokeLineJoin', strokeLineJoin,
            defaultValue: StrokeLineJoin.miter),
        VectorDoubleProperty('strokeMiterLimit', strokeMiterLimit,
            defaultValue: 4),
        VectorEnumProperty<FillType>('fillType', fillType,
            defaultValue: FillType.nonZero),
      ];

  @override
  Iterable<StyleProperty> get _localUsedStyles => _usedStyles;
  @override
  Iterable<StyleProperty> get _usedStyles => [
        if (pathData.styled != null) pathData.styled!,
        if (fillColor.styled != null) fillColor.styled!,
        if (strokeColor.styled != null) strokeColor.styled!,
        if (strokeWidth.styled != null) strokeWidth.styled!,
        if (strokeAlpha.styled != null) strokeAlpha.styled!,
        if (fillAlpha.styled != null) fillAlpha.styled!,
        if (trimPathStart.styled != null) trimPathStart.styled!,
        if (trimPathEnd.styled != null) trimPathEnd.styled!,
        if (trimPathOffset.styled != null) trimPathOffset.styled!,
      ];

  @override
  List<ValueOrProperty<Object>> get _localValuesOrProperties => [
        pathData,
        fillColor,
        strokeColor,
        strokeWidth,
        strokeAlpha,
        fillAlpha,
        trimPathStart,
        trimPathEnd,
        trimPathOffset,
      ];

  static const List<String> stylablePropertyNames = [
    'pathData',
    'fillColor',
    'strokeColor',
    'strokeWidth',
    'strokeAlpha',
    'fillAlpha',
    'trimPathStart',
    'trimPathEnd',
    'trimPathOffset',
  ];

  @override
  VectorDiagnosticsNode toDiagnosticsNode([String? name]) =>
      super.toDiagnosticsNode(this.name);

  @override
  R accept<R, Context>(VectorDrawablePartRawVisitor<R, Context> visitor,
          [Context? context]) =>
      visitor.visitPath(this, context);
}
