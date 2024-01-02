library vector_drawable;

import 'package:vector_drawable_core/vector_drawable_core.dart';

import 'src/path_evaluator.dart';

export 'package:vector_drawable_core/vector_drawable_core.dart';

export 'src/widget/vector.dart';
export 'src/widget/animated_vector.dart';

void initializeVectorDrawableFlutter() {
  PathEvaluator.initialize(const FlutterPathEvaluator());
}
