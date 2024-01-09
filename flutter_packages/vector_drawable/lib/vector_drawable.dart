library vector_drawable;

import 'package:vector_drawable_core/vector_drawable_core.dart'
    show PathEvaluator;
export 'package:vector_drawable_core/model.dart';
export 'src/utils/compat.dart';
export 'src/style_resolver/color_scheme_style_resolver.dart';
export 'src/widget/raw_vector.dart';
export 'src/widget/vector.dart';
import 'src/path_evaluator.dart';

void initializeVectorDrawableFlutter() {
  PathEvaluator.initialize(const FlutterPathEvaluator());
}
