import 'package:vector_drawable_path_utils/src/model/affine_matrix.dart';
import 'package:vector_drawable_path_utils/src/model/transform_context.dart';
import 'package:vector_drawable_path_utils/src/parsing/transform.dart';
import 'package:vector_math/vector_math_64.dart';
@Deprecated("Transform already encodes an list")
typedef TransformOrTransformList = Transform;
abstract class Transform {
  const Transform();
  factory Transform.parse(String? transform) {
    // assume there is only one transform for now
    // TODO
    return Transform.parseSingle(transform);
  }
  factory Transform.parseSingle(String? transform) {
    if (transform == null) {
      return Transform.none;
    }
    return parseTransform(transform);
  }

  @Deprecated("use Transform.identity")
  static const Transform none = NoneTransform();
  static const Transform identity = IdentityTransform();

  AffineMatrix toMatrix() {
    final out = AffineMatrix.identity();
    applyToProxy(out);
    return out;
  }

  AffineMatrix toMatrixWithParent(AffineMatrix matrix) {
    final out = matrix.clone();
    applyToProxy(out);
    return out;
  }

  void applyToProxy(TransformProxy matrix);
}
@Deprecated("use IdentityTransform")
typedef NoneTransform = IdentityTransform;
class IdentityTransform extends Transform {
  const IdentityTransform();
  @override
  AffineMatrix toMatrix() {
    return AffineMatrix.identity();
  }

  @override
  AffineMatrix toMatrixWithParent(AffineMatrix matrix) {
    return matrix.clone();
  }

  @override
  void applyToProxy(TransformProxy matrix) {}
}

class TransformList extends Transform {
  final List<Transform> transforms;

  const TransformList(this.transforms);

  @override
  void applyToProxy(TransformProxy matrix) {
    for (final t in transforms) {
      t.applyToProxy(matrix);
    }
  }
}

class Rotate extends Transform {
  const Rotate(this.radians, [this.x, this.y])
      : assert(
          (x == null && y == null) || //
              (x != null && y != null),
        );
  final double radians;
  final double? x, y;
  bool get hasPivot => x != null && y != null;

  Vector2 get pivot => Vector2(x!, y!);

  @override
  void applyToProxy(TransformProxy matrix) {
    if (hasPivot) {
      matrix.rotate(radians, pivot);
      return;
    }
    matrix.rotate(radians);
  }
}

class Translate extends Transform {
  const Translate(this.x, this.y);
  final double x, y;

  Vector2 get offset => Vector2(x, y);
  @override
  void applyToProxy(TransformProxy matrix) {
    matrix.translate(offset);
  }
}

class Matrix extends Transform {
  const Matrix(this.a, this.b, this.c, this.d, this.tx, this.ty);
  factory Matrix.fromAffine(AffineMatrix matrix) => Matrix(
        matrix.a,
        matrix.b,
        matrix.c,
        matrix.d,
        matrix.tx,
        matrix.ty,
      );
  final double a, b, c, d;
  final double tx, ty;
  AffineMatrix get matrix => AffineMatrix(a, b, c, d, tx, ty);

  @override
  void applyToProxy(TransformProxy matrix) {
    matrix.multiply(this.matrix);
  }
}

class Scale extends Transform {
  const Scale(this.x, [double? y]) : y = y ?? x;
  final double x, y;

  Vector2 get scale => Vector2(x, y);
  @override
  void applyToProxy(TransformProxy matrix) {
    matrix.scale(scale);
  }
}

class ScaleX extends Transform {
  const ScaleX(this.x);
  final double x;

  @override
  void applyToProxy(TransformProxy matrix) {
    matrix.scale(Vector2(x, 1.0));
  }
}

class ScaleY extends Transform {
  const ScaleY(this.y);
  final double y;

  @override
  void applyToProxy(TransformProxy matrix) {
    matrix.scale(Vector2(1.0, y));
  }
}