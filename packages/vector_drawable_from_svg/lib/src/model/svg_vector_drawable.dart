import 'package:vector_drawable_core/vector_drawable_core.dart';
import 'package:vector_drawable_from_svg/src/parsing/parse.dart';
import 'package:xml/xml.dart';

abstract class SvgNode {
  String get id;
  VectorDrawableNode get node;
}

abstract class SvgPart extends SvgNode {
  IdAndLabel get idAndLabel;
  VectorPart get part;
  String get id => idAndLabel.id;
  VectorDrawableNode get node => part;
}

abstract class SvgPathOrGroup extends SvgPart {}

class SvgPath extends SvgPathOrGroup {
  final IdAndLabel idAndLabel;
  final Path path;

  SvgPath(this.idAndLabel, this.path);
  @override
  VectorPart get part => path;
}

class SvgGroup extends SvgPathOrGroup {
  final IdAndLabel idAndLabel;
  final SvgNameMapping labels;
  final Group group;

  SvgGroup(this.idAndLabel, this.labels, this.group);
  @override
  VectorPart get part => group;
}

class SvgChildOutlet extends SvgPart {
  final IdAndLabel idAndLabel;
  final ChildOutlet childOutlet;

  SvgChildOutlet(this.idAndLabel, this.childOutlet);

  @override
  VectorPart get part => childOutlet;
}

typedef Id = String;
typedef Label = String;

class IdAndLabel {
  final Id id;
  final Label? label;

  const IdAndLabel(this.id, this.label);
}

class SvgNameMapping {
  final Map<Label, SvgPathOrGroup> labels;
  final Map<Id, SvgPathOrGroup> names;

  SvgNameMapping(this.labels, {Map<String, SvgPathOrGroup>? names})
      : names = names ?? {};
  SvgNameMapping.empty()
      : labels = {},
        names = {};

  void addChild(SvgPathOrGroup child) {
    final idAndLabel = child.idAndLabel;
    names[idAndLabel.id] = child;
    final label = idAndLabel.label;
    if (label != null) {
      labels[label] = child;
    }
  }

  void addChildren(Iterable<SvgPathOrGroup> childen) {
    for (final child in childen) {
      addChild(child);
    }
  }
}

class SvgVector extends SvgNode {
  final Vector vector;
  final SvgNameMapping labels;

  SvgVector(this.vector, this.labels);

  @override
  String get id => vector.name!;

  @override
  VectorDrawableNode get node => vector;
}

class SvgVectorDrawable {
  final VectorDrawable vectorDrawable;
  final SvgNameMapping labels;

  SvgVectorDrawable(this.vectorDrawable, this.labels);

  static SvgVectorDrawable parseDocument(
    XmlDocument document,
    ResourceReference source, {
    DimensionKind dimensionKind = DimensionKind.dp,
  }) =>
      parseSvgIntoVectorDrawable(
        document.rootElement,
        source,
        dimensionKind: dimensionKind,
      );
  static SvgVectorDrawable parseElement(
    XmlElement element, {
    DimensionKind dimensionKind = DimensionKind.dp,
  }) =>
      parseSvgIntoVectorDrawable(
        element,
        null,
        dimensionKind: dimensionKind,
      );
}
