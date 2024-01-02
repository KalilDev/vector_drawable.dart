import 'package:vector_drawable/src/path_utils.dart';
import 'package:vector_drawable_core/vector_drawable_core.dart';
import 'package:vector_math/vector_math_64.dart';

class FlutterPathEvaluator implements PathEvaluator {
  const FlutterPathEvaluator();
  @override
  Vector2 evaluatePathAt(PathData path, double t) {
    final point = PathDataAdditionalData.forPath(path).evaluateAt(t);
    return Vector2(point.dx, point.dy);
  }
}
