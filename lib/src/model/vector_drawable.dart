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

  Dimension(this.value, this.kind);
  @override
  String toString() => '$value${kind.name}';

  @override
  List<VectorProperty<void>> properties() => [
        VectorDoubleProperty('value', value),
        VectorEnumProperty<DimensionKind>('kind', kind)
      ];
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
}

// https://developer.android.com/reference/android/graphics/drawable/VectorDrawable
abstract class VectorDrawableNode implements VectorDiagnosticable {
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

  Vector({
    required String? name,
    required this.width,
    required this.height,
    required this.viewportWidth,
    required this.viewportHeight,
    this.tint = const StyleOr.value(VectorColor.transparent),
    this.tintMode = TintMode.srcIn,
    this.autoMirrored = false,
    this.opacity = const StyleOr.value(1.0),
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
  Iterable<StyleProperty> get _localUsedStyles => [
        if (tint.styled != null) tint.styled!,
        if (opacity.styled != null) opacity.styled!,
      ];
  @override
  VectorDiagnosticsNode toDiagnosticsNode([String? name]) =>
      super.toDiagnosticsNode(this.name);
}

class ClipPath extends VectorPart with VectorDiagnosticableTreeMixin {
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

  Group({
    required String? name,
    this.rotation = const StyleOr.value(0.0),
    this.pivotX = const StyleOr.value(0.0),
    this.pivotY = const StyleOr.value(0.0),
    this.scaleX = const StyleOr.value(1.0),
    this.scaleY = const StyleOr.value(1.0),
    this.translateX = const StyleOr.value(0.0),
    this.translateY = const StyleOr.value(0.0),
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
  VectorDiagnosticsNode toDiagnosticsNode([String? name]) =>
      super.toDiagnosticsNode(this.name);
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

  Path({
    required String? name,
    required this.pathData,
    this.fillColor = const StyleOr.value(VectorColor.transparent),
    this.strokeColor = const StyleOr.value(VectorColor.transparent),
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
  VectorDiagnosticsNode toDiagnosticsNode([String? name]) =>
      super.toDiagnosticsNode(this.name);
}
