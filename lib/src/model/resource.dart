import 'package:xml/xml.dart';
import 'package:xml/src/xml/utils/namespace.dart';

class ResourceReference {
  final String folder;
  final String name;

  static ResourceReference? parse<T extends Resource>(String ref) {
    final split = ref.split('/');
    if (!ref.startsWith('@') || split.length != 2) {
      return null;
    }
    return ResourceReference(split[0].substring(1), split[1]);
  }

  ResourceReference(
    this.folder,
    this.name,
  );
}

abstract class Resource {
  final ResourceReference? source;

  Resource(this.source);

  bool get isInline => source == null;
}

class ResourceOrReference<T extends Resource> {
  ResourceOrReference.empty() : reference = null;
  ResourceOrReference.reference(this.reference);
  ResourceOrReference.resource(this.resource) : reference = null;
  ResourceOrReference(this.reference, this.resource);
  final ResourceReference? reference;
  T? resource;

  bool get isResolved => resource != null;
  bool get isResolvable => isResolved || reference != null;
  bool get isInline => reference == null && resource != null;

  static ResourceOrReference<T>? parseReference<T extends Resource>(
    String ref,
  ) {
    final reference = ResourceReference.parse(ref);
    if (reference == null) {
      return null;
    }
    return ResourceOrReference.reference(reference);
  }
}
