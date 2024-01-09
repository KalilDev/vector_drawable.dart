library animated_vector_drawable;

import 'package:vector_drawable/vector_drawable.dart'
    show initializeVectorDrawableFlutter;
export 'package:vector_drawable/vector_drawable.dart';
export 'package:animated_vector_drawable_core/model.dart';

export 'src/widget/animated_vector.dart';

void initializeAnimatedVectorDrawableFlutter() =>
    initializeVectorDrawableFlutter();
