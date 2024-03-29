abstract class Clonable<Self> {
  Self clone();
}

T cloneAn<T extends Clonable<T>>(Clonable<T> clonable) => clonable.clone();

class ResourceReference {
  final String namespace;
  final String folder;
  final String name;

  static ResourceReference? parse<T extends Resource>(String ref) {
    final split = ref.split('/');
    if (!ref.startsWith('@') || split.length != 2) {
      return null;
    }
    final namespaceAndFolder = split[0].substring(1).split(':');

    return ResourceReference(
      namespaceAndFolder[namespaceAndFolder.length - 1],
      split[1],
      namespaceAndFolder.length == 1 ? '' : namespaceAndFolder[0],
    );
  }

  ResourceReference(
    this.folder,
    this.name, [
    this.namespace = '',
  ]);

  @override
  String toString() => '@${namespace == '' ? '' : '$namespace:'}$folder/$name';
}

abstract class Resource {
  final ResourceReference? source;

  Resource(this.source);

  bool get isInline => source == null;
}

class ResourceOrReference<T extends Resource>
    implements Clonable<ResourceOrReference<T>> {
  ResourceOrReference.empty() : reference = null;
  ResourceOrReference.reference(this.reference);
  ResourceOrReference.resource(this.resource) : reference = null;
  ResourceOrReference(this.resource, this.reference);
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

  R runWithResourceType<R>(
    R Function<T extends Resource>(ResourceOrReference<T> self) fn,
  ) =>
      fn<T>(this);

  @override
  ResourceOrReference<T> clone() => ResourceOrReference(resource, reference);
}
