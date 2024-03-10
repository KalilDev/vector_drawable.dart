import 'package:vector_drawable_core/model.dart';

import 'extracted_style_resolver.dart';

class VectorWithExtractedStyles {
  const VectorWithExtractedStyles(
    this.vector,
    this.extractedResolver,
  );
  final ExtractedResolver extractedResolver;
  final Vector vector;
}
