import 'package:vector_drawable_path_utils/model.dart';
import 'package:vector_math/vector_math_64.dart';

abstract class PathEvaluator {
  static late final PathEvaluator _instance;
  static void initialize(PathEvaluator instance) => _instance = instance;
  static PathEvaluator get instance => _instance;
  Vector2 evaluatePathAt(PathData path, double t);
}
