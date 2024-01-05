library vector_drawable;

import 'package:vector_drawable_core/vector_drawable_core.dart'
    show PathEvaluator;
export 'package:vector_drawable_core/model.dart';

export 'src/widget/vector.dart';
import 'src/path_evaluator.dart';

void initializeVectorDrawableFlutter() {
  PathEvaluator.initialize(const FlutterPathEvaluator());
}
