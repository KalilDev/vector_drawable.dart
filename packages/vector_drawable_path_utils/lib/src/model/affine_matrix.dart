import 'dart:math';

import 'package:vector_drawable_path_utils/src/model/transform_context.dart';
import 'package:vector_math/vector_math_64.dart';

MatrixImpl _makeRotated<MatrixImpl extends _AffineMatrix>(
  _MakeImpl<MatrixImpl> make,
  double radians, [
  Vector2? center,
]) {
  final pivot = center ?? Vector2.zero();
  final cosTheta = cos(radians);
  final sinTheta = sin(radians);
  final pivotX = pivot.x;
  final pivotY = pivot.y;
  return make(
    cosTheta,
    sinTheta,
    -sinTheta,
    cosTheta,
    pivotX * (1 - cosTheta) + pivotY * sinTheta,
    pivotY * (1 - cosTheta) - pivotX * sinTheta,
  );
}

MatrixImpl _makeScaled<MatrixImpl extends _AffineMatrix>(
    _MakeImpl<MatrixImpl> make, double x,
    [double? y]) {
  return make(
    x,
    0,
    0,
    y ?? x,
    0,
    0,
  );
}

MatrixImpl _makeTranslated<MatrixImpl extends _AffineMatrix>(
    _MakeImpl<MatrixImpl> make, Vector2 vector2) {
  return make(
    1,
    0,
    0,
    1,
    vector2.x,
    vector2.y,
  );
}

/*

class _Matrix3AffineMatrix extends _AffineMatrix {
  final Matrix3 _matrix;
  _Matrix3AffineMatrix(
    double a,
    double b,
    double c,
    double d,
    double tx,
    double ty,
  )   : _matrix = Matrix3.fromList([
          a, b, 0, //
          c, d, 0, //
          tx, ty, 1.0, //
        ]),
        super._();
  _Matrix3AffineMatrix.identity()
      : _matrix = Matrix3.identity(),
        super._();
  @override
  double get a => _matrix[0];
  @override
  double get b => _matrix[1];
  @override
  double get c => _matrix[3];
  @override
  double get d => _matrix[4];
  @override
  double get e => _matrix[6];
  @override
  double get f => _matrix[7];
  @override
  double get tx => _matrix[6];
  @override
  double get ty => _matrix[7];

  @override
  _Matrix3AffineMatrix clone() =>
      _Matrix3AffineMatrix.identity()..setFromOther(this);

  @override
  void setFromOther(_Matrix3AffineMatrix other) {
    _matrix.setFrom(other._matrix);
  }

  @override
  void multiply(AffineMatrix other) {
    _matrix.multiply((other as _Matrix3AffineMatrix)._matrix);
  }

  @override
  void transformPoint(Vector2 point) {
    final temp = Vector3(point.x, point.y, 1);
    _matrix.transform(temp);
    point.x = temp.x;
    point.y = temp.y;
  }

  @override
  void rotate(double radians, [Vector2? center]) {
    multiply(
      _makeRotated(
        _Matrix3AffineMatrix.new,
        radians,
        center,
      ),
    );
  }

  @override
  void setIdentity() => _matrix.setIdentity();

  @override
  void scale(dynamic x, [double? y]) {
    multiply(_makeScaled(_Matrix3AffineMatrix.new, x as double, y));
  }

  @override
  void translate(Vector2 offset) {
    multiply(_makeTranslated(_Matrix3AffineMatrix.new, offset));
  }
}*/

class AffineMatrix extends _AffineMatrix with ReadableTransformProxyPathMixin {
  final Matrix4 _matrix;
  AffineMatrix(
    double a,
    double b,
    double c,
    double d,
    double e,
    double f,
  )   : _matrix = Matrix4.fromList([
          a, b, 0, 0, //
          c, d, 0, 0, //
          0, 0, 1, 0, //
          e, f, 0, 1, //
        ]),
        super._();
  AffineMatrix.identity()
      : _matrix = Matrix4.identity(),
        super._();
  @override
  double get a => _matrix[0];
  @override
  double get b => _matrix[1];
  @override
  double get c => _matrix[4];
  @override
  double get d => _matrix[5];
  @override
  double get e => _matrix[8];
  @override
  double get f => _matrix[9];
  @override
  double get tx => _matrix[12];
  @override
  double get ty => _matrix[13];

  @override
  AffineMatrix clone() => AffineMatrix.identity()..setFromOther(this);

  Matrix4 getMatrix() => _matrix;

  /// https://www.w3.org/TR/css-transforms-1/#interpolation-of-2d-matrices
  DecomposedAffineTransformValues? transformDecompose() {
    final matrix = getMatrix();

    final scale = Vector2.zero();
    final translation = Vector2.zero();
    final x = Vector2.zero();
    final y = Vector2.zero();
    final double rotation;
    double m(int x, int y) {
      const row = 4;
      final i = x * row + y;
      return matrix[i];
    }

    var row0x = m(0, 0); // a
    var row0y = m(0, 1); // b
    var row1x = m(1, 0); // c
    var row1y = m(1, 1); // d

    translation[0] = m(3, 0); // e
    translation[1] = m(3, 1); // f

    scale[0] = sqrt(row0x * row0x + row0y * row0y);
    scale[1] = sqrt(row1x * row1x + row1y * row1y);

// If determinant is negative, one axis was flipped.
    double determinant = row0x * row1y - row0y * row1x;
    if (determinant < 0)
    // Flip axis with minimum unit vector dot product.
    if (row0x < row1y)
      scale[0] = -scale[0];
    else
      scale[1] = -scale[1];

// Renormalize matrix to remove scale.
    if (scale[0] != 0.0) row0x *= 1 / scale[0];
    row0y *= 1 / scale[0];
    if (scale[1] != 0.0) row1x *= 1 / scale[1];
    row1y *= 1 / scale[1];

// Compute rotation and renormalize matrix.
    rotation = atan2(row0y, row0x);

    if (rotation != 0.0) {
      // Rotate(-angle) = [cos(angle), sin(angle), -sin(angle), cos(angle)]
      //                = [row0x, -row0y, row0y, row0x]
      // Thanks to the normalization above.
      final sn = -row0y;
      final cs = row0x;
      final m11 = row0x;
      final m12 = row0y;
      final m21 = row1x;
      final m22 = row1y;
      row0x = cs * m11 + sn * m21;
      row0y = cs * m12 + sn * m22;
      row1x = -sn * m11 + cs * m21;
      row1y = -sn * m12 + cs * m22;
    }
    x[0] = row0x;
    x[1] = row0y;
    y[0] = row1x;
    y[1] = row1y;

    return DecomposedAffineTransformValues(
      scale: scale,
      translation: translation,
      x: x,
      y: y,
      rotation: rotation,
    );
  }

  @override
  void setFromOther(AffineMatrix other) {
    _matrix.setFrom(other._matrix);
  }

  @override
  void multiply(AffineMatrix other) {
    _matrix.multiply(other._matrix);
  }

  @override
  void transformPoint(Vector2 point) {
    final temp = Vector4(point.x, point.y, 1, 1);
    _matrix.transform(temp);
    point.x = temp.x;
    point.y = temp.y;
  }

  @override
  void rotate(double radians, [Vector2? center]) {
    multiply(
      _makeRotated(
        AffineMatrix.new,
        radians,
        center,
      ),
    );
  }

  @override
  void setIdentity() => _matrix.setIdentity();

  @override
  void scale(dynamic x, [double? y]) {
    if (x is Vector2) {
      // This is the TransformProxy impl
      final scale = x;
      multiply(_makeScaled(AffineMatrix.new, scale.x, scale.y));
      return;
    }
    if (x is int) {
      // This is an compat impl
      assert(false, 'x is an int, use double');
      x = x.toDouble();
    }
    if (x is! double) {
      throw TypeError();
    }
    multiply(_makeScaled(AffineMatrix.new, x, y));
  }

  @override
  void translate(Vector2 offset) {
    multiply(_makeTranslated(AffineMatrix.new, offset));
  }
}

class DecomposedAffineMatrixValues {
  final Vector2 _scale;
  final Vector2 _translation;
  final double rotation;

  DecomposedAffineMatrixValues({
    required Vector2 scale,
    required Vector2 translation,
    required this.rotation,
  })  : _scale = scale.clone(),
        _translation = translation.clone();

  Vector2 get scale => _scale.clone();
  Vector2 get translation => _translation.clone();
}

class DecomposedAffineTransformValues {
  final Vector2 _scale;
  final Vector2 _translation;
  final Vector2 _x;
  final Vector2 _y;
  final double rotation;

  DecomposedAffineTransformValues({
    required Vector2 scale,
    required Vector2 translation,
    required Vector2 x,
    required Vector2 y,
    required this.rotation,
  })  : _scale = scale.clone(),
        _translation = translation.clone(),
        _x = x.clone(),
        _y = y.clone();

  Vector2 get scale => _scale.clone();
  Vector2 get translation => _translation.clone();
  Vector2 get x => _x.clone();
  Vector2 get y => _y.clone();
}

abstract class _AffineMatrix implements ReadableTransformProxy {
  _AffineMatrix._();

  DecomposedAffineMatrixValues decompose() => DecomposedAffineMatrixValues(
        scale: getScale(),
        translation: getTranslation(),
        rotation: getRotation(),
      );
  double get a;
  double get b;
  double get c;
  double get d;
  double get e;
  double get f;
  double get tx => e;
  double get ty => f;

  bool isIdentity() =>
      a == 1 && b == 0 && c == 0 && d == 1 && tx == 0 && ty == 0;
  bool get isScaleAndOrTranslate => b == 0 && c == 0;
  bool get isRotateNoPivot => isRotate && tx == 0 && ty == 0;
  bool get isRotate => a == d && b == -c;

  _AffineMatrix clone();

  Vector2 getScale() => Vector2(sqrt(a * a + c * c), sqrt(b * b + d * d));
  double getScalarScale() => (sqrt(a * a + c * c) + sqrt(b * b + d * d)) / 2;

  void setFromOther(covariant _AffineMatrix other);

  void translate(Vector2 offset);

  void multiply(covariant _AffineMatrix other);

  void rotate(double radians, [Vector2? center]);

  double getRotation() => atan2(b, a);

  String toCssString() {
    String n(double d) => d.toStringAsFixed(4);
    return 'matrix(${n(a)}, ${n(b)}, ${n(c)}, ${n(d)}, ${n(e)}, ${n(f)})';
  }

  void transformPoint(Vector2 point);

  @override
  String toString() => '''
[ $a, $c, $e ]
[ $b, $d, $f ]
[ 0.0, 0.0, 1.0 ]
''';

  /// Creates a new affine matrix rotated by `x` and `y`.
  ///
  /// If `y` is not specified, it is defaulted to the same value as `x`.
  void scale(dynamic x, [double? y]);

  Vector2 getTranslation() => Vector2(tx, ty);
  void setIdentity();
}

typedef _MakeImplIdentity<MatrixImpl extends _AffineMatrix> = MatrixImpl
    Function();
typedef _MakeImpl<MatrixImpl extends _AffineMatrix> = MatrixImpl Function(
    double a, double b, double c, double d, double tx, double ty);
