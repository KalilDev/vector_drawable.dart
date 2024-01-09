import 'package:flutter/cupertino.dart';
import 'package:flutter/src/foundation/diagnostics.dart';

import '../../vector_drawable.dart';
import 'package:vector_drawable_core/vector_drawable_core.dart';

Color colorFromVectorColor(VectorColor vectorColor) => Color(vectorColor.argb);
VectorColor vectorColorFromColor(Color color) => VectorColor(color.value);

extension VectorColorAsColor on VectorColor {
  Color get asColor => colorFromVectorColor(this);
}

extension ColorAsVectorColor on Color {
  VectorColor get asVectorColor => vectorColorFromColor(this);
}

class DiagnosticsNodeVectorDiagnosticsNodeAdapter extends DiagnosticsNode {
  final VectorDiagnosticsNode node;

  DiagnosticsNodeVectorDiagnosticsNodeAdapter(this.node)
      : super(name: node.describeSelfShort());

  @override
  List<DiagnosticsNode> getChildren() => node
      .getChildren()
      .map(DiagnosticsNodeVectorDiagnosticsNodeAdapter.new)
      .toList();

  @override
  List<DiagnosticsNode> getProperties() => node
      .getProperties()
      .map(DiagnosticsNodeVectorDiagnosticsNodeAdapter.new)
      .toList();

  @override
  String toDescription({TextTreeConfiguration? parentConfiguration}) {
    return node.describeSelfShort();
  }

  @override
  Object? get value => node.value;
}

BlendMode blendModeFromTintMode(TintMode tintMode) {
  switch (tintMode) {
    case TintMode.plus:
      return BlendMode.plus;
    case TintMode.multiply:
      return BlendMode.multiply;
    case TintMode.screen:
      return BlendMode.screen;
    case TintMode.srcATop:
      return BlendMode.srcATop;
    case TintMode.srcIn:
      return BlendMode.srcIn;
    case TintMode.srcOver:
      return BlendMode.srcOver;
  }
}

extension TintModeAsBlendMode on TintMode {
  BlendMode get asBlendMode => blendModeFromTintMode(this);
}
