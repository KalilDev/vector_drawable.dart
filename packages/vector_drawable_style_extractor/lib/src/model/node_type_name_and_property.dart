import 'package:vector_drawable_core/model.dart';

class NodeTypeNameAndProperty {
  final VectorDrawableNodeType type;
  final String name;
  final String propertyName;

  const NodeTypeNameAndProperty(this.name, this.type, this.propertyName);

  factory NodeTypeNameAndProperty.parse(String str) {
    var cs = str.split('-');
    final a = cs[0];
    final VectorDrawableNodeType type;
    switch (a) {
      case 'Vector':
        type = VectorDrawableNodeType.Vector;
        break;
      case 'Group':
        type = VectorDrawableNodeType.Group;
        break;
      case 'ClipPath':
        type = VectorDrawableNodeType.ClipPath;
        break;
      case 'Path':
        type = VectorDrawableNodeType.Path;
        break;
      case 'ChildOutlet':
        type = VectorDrawableNodeType.ChildOutlet;
        break;
      case 'AffineGroup':
        type = VectorDrawableNodeType.AffineGroup;
        break;
      default:
        throw ArgumentError();
    }
    str = cs.skip(1).join('-');
    cs = str.split(':');
    final b = cs.take(cs.length - 1).join(':');
    final c = cs.last;
    return NodeTypeNameAndProperty(b, type, c);
  }

  bool operator ==(Object other) {
    if (other is! NodeTypeNameAndProperty) {
      return false;
    }
    return name == other.name &&
        type == other.type &&
        propertyName == other.propertyName;
  }

  int get hashCode => Object.hash(name, type, propertyName);

  String get generatedPropertyName => '${type.name}-$name:$propertyName';
  ValueOrProperty<T> toProperty<T extends Object>() => Property(
        StyleProperty(
          'extractedFromNode',
          generatedPropertyName,
        ),
      );
}
