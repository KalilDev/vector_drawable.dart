import 'package:vector_drawable_core/vector_drawable_core.dart';

void main() {
  final vector = Vector(
    height: 24.0.dp,
    width: 24.0.dp,
    viewportHeight: 24.0,
    viewportWidth: 24.0,
    children: [
      Group(
        scaleX: 24.0.asStyle,
        scaleY: 24.0.asStyle,
        children: [
          Path(
            pathData: PathData.fromString('M 0 0 L 1 1 L 1 0 Z').asStyle,
          )
        ],
      )
    ],
  );
}
