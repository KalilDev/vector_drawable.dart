library vector_drawable_code_generator.builder;

import 'package:build/build.dart';
import 'src/part_builder.dart';

/// Supports `package:build_runner` creation and configuration of
/// `vector_drawable`.
///
/// Not meant to be invoked by hand-authored code.
Builder vectorDrawable(BuilderOptions options) {
  try {
    return vectorDrawablePartBuilder();
  } on Exception catch (e) {
    final lines = <String>[
      'Could not parse the options provided for `vector_drawable`.'
    ];
    throw StateError(lines.join('\n'));
  }
}
