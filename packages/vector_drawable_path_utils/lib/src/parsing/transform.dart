import 'package:vector_drawable_path_utils/model.dart';
import 'package:vector_math/vector_math_64.dart';

import '../model/transform.dart';

Never _parseException(String input) =>
    throw StateError('fuck, fuck you, and fuck "$input"');

double _parseCssDouble(String str) =>
    double.tryParse(str) ??
    int.tryParse(str)?.toDouble() ??
    _parseException(str);

Scale _parseTransformScale(String transform) {
  assert(transform.startsWith('scale('));
  assert(transform.endsWith(')'));
  // Assuming the matrix string is in the form "matrix(a, b, c, d, e, f)"
  final scaleString = transform.substring(6, transform.length - 1);
  List<double> values = scaleString
      .split(",")
      .map((str) => str.trim())
      .map(_parseCssDouble)
      .toList();
  double x, y;
  if (values.length == 1) {
    x = values[0];
    y = x;
  } else if (values.length == 2) {
    x = values[0];
    y = values[1];
  } else {
    throw Exception('unsupported scale transform');
  }
  return Scale(x, y);
}

Matrix _parseTransformMatrix(String transform) {
  assert(transform.startsWith('matrix('));
  assert(transform.endsWith(')'));
  // Assuming the matrix string is in the form "matrix(a, b, c, d, e, f)"
  final matrixString = transform.substring(7, transform.length - 1);
  List<double> values = matrixString
      .split(",")
      .map((str) => str.trim())
      .map(_parseCssDouble)
      .toList();

  final a = values[0];
  final b = values[1];
  final c = values[2];
  final d = values[3];
  final tx = values[4];
  final ty = values[5];
  assert(values.length == 6);
  return Matrix(a, b, c, d, tx, ty);
}

Rotate _parseTransformRotate(String transform) {
  assert(transform.startsWith('rotate('));
  assert(transform.endsWith(')'));
  // Assuming the matrix string is in the form "(a, b, c)"
  final matrixString = transform.substring(7, transform.length - 1);
  List<double> values = matrixString
      .split(",")
      .map((str) => str.trim())
      .map(_parseCssDouble)
      .toList();

  if (values.length == 3) {
    final a = values[0];
    final b = values[1];
    final c = values[2];
    return Rotate(a * degrees2Radians, b, c);
  }
  assert(values.length == 1);
  final a = values[0];
  return Rotate(a * degrees2Radians);
}

Translate _parseTransformTranslate(String transform) {
  assert(transform.startsWith('translate('));
  assert(transform.endsWith(')'));
  // Assuming the matrix string is in the form "(a, b)"
  final matrixString = transform.substring(10, transform.length - 1);
  List<double> values = matrixString
      .split(",")
      .map((str) => str.trim())
      .map(_parseCssDouble)
      .toList();


  if (values.length == 2) {
    final a = values[0];
    final b = values[1];
    assert(values.length == 2);

    double translateX = a;
    double translateY = b;

    return Translate(translateX, translateY);
  }

  final a = values[0];
  assert(values.length == 1);

  double translateX = a;
  double translateY = 0.0;

  return Translate(translateX, translateY);
}

Transform parseTransform(String transform) {
  transform = transform.trim();
  if (transform.startsWith('matrix(')) {
    return _parseTransformMatrix(transform);
  }
  if (transform.startsWith('rotate(')) {
    return _parseTransformRotate(transform);
  }
  if (transform.startsWith('translate(')) {
    return _parseTransformTranslate(transform);
  }
  if (transform.startsWith('scale(')) {
    return _parseTransformScale(transform);
  }
  if (transform.startsWith('skew(')) {
    //return _parseTransformScale(transform, transformContext);
  }
  throw UnimplementedError('unsuported transform "$transform"');
}
