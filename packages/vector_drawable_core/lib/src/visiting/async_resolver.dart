import 'dart:async';

import '../model/resource.dart';
import '../model/vector_drawable.dart';

Iterable<R> _walkVectorPart<R>(
  VectorPart part, {
  required R Function(Path) onPath,
  required R Function(Group) onGroup,
  required R Function(ClipPath) onClipPath,
}) sync* {
  if (part is Path) {
    yield onPath(part);
  } else if (part is Group) {
    yield onGroup(part);
    for (final part in part.children) {
      yield* _walkVectorPart(
        part,
        onPath: onPath,
        onGroup: onGroup,
        onClipPath: onClipPath,
      );
    }
  } else if (part is ClipPath) {
    yield onClipPath(part);
    for (final part in part.children) {
      yield* _walkVectorPart(
        part,
        onPath: onPath,
        onGroup: onGroup,
        onClipPath: onClipPath,
      );
    }
  } else {
    throw TypeError();
  }
}

Iterable<R> walkVectorDrawable<R>(
  VectorDrawable vector, {
  required R Function(VectorDrawable) onVectorDrawable,
  required R Function(Vector) onVector,
  required R Function(Path) onPath,
  required R Function(Group) onGroup,
  required R Function(ClipPath) onClipPath,
}) sync* {
  yield onVectorDrawable(vector);
  yield onVector(vector.body);
  for (final part in vector.body.children) {
    yield* _walkVectorPart(
      part,
      onPath: onPath,
      onGroup: onGroup,
      onClipPath: onClipPath,
    );
  }
}

Iterable<T> _empty<T>(_) => <T>[];
