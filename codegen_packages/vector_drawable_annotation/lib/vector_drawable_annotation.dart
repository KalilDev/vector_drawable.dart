// ignore_for_file: deprecated_member_use_from_same_package

import 'package:vector_drawable_core/model.dart';
export 'package:vector_drawable_core/model.dart'
    show VectorDrawableNodeType, StyleProperty;

// annotation
typedef WantedStyles = Map<VectorDrawableNodeType,
    Map<NodeId, Map<PropertyName, StyleProperty>>>;
typedef PropertyName = Symbol;
typedef NodeId = Symbol;

@Deprecated('Dont use this.')
abstract class VectorSource {
  const VectorSource();
}

/// Annotates:
/// - An constant named `constantVectorName` of type [Vector] that equals `_$constantVectorName`.
/// - An constant named `constantVectorName` of type [VectorWithExtractedStyles] that equals `_$constantVectorName`.
class VectorFromSvg extends VectorSource {
  const VectorFromSvg(
    this.svgPath, {
    this.dimensionKind = DimensionKind.dp,
    this.inlineTransforms = true,
    this.makeViewportVectorSized = true,
  });
  final String svgPath;
  final DimensionKind dimensionKind;
  final bool inlineTransforms;
  final bool makeViewportVectorSized;
}

/// Annotates:
/// - An constant named `constantVectorName` of type [Vector] that equals `_$constantVectorName`.
/// - An constant named `constantVectorName` of type [VectorWithExtractedStyles] that equals `_$constantVectorName`.
class VectorFromVd extends VectorSource {
  const VectorFromVd(this.vdPath);
  final String vdPath;
}

/// Annotates:
/// - An constant named `constantVectorName` [Vector] that equals `_$constantVectorName`.
class VectorWithSomeStyles {
  const VectorWithSomeStyles(
    this.targetVector, {
    required this.wantedStyles,
  });

  /// An generated vector from this file that extends [VectorWithExtractedStyles]
  final VectorSource targetVector;
  final WantedStyles wantedStyles;
}

// user code
/*
@VectorFromSvg('vec.svg') // or @VectorFromVd('vec.vd')
const VectorWithExtractedStyles myVector = $_myVector;
 
@VectorFromSvg('vec.svg') // or @VectorFromVd('vec.vd')
class MyVector = VectorWithExtractedStyles with _$MyVector;

@VectorFromSvg('vec.svg') // or @VectorFromVd('vec.vd')
class MyVector extends VectorWithExtractedStyles with _$MyVector {
  const MyVector();
  // optional
  static const MyVector instance = MyVector();
}

const WantedStyles _myVectorOptimizedForFadeWantedStyles = {
  ElementType.Vector: {
    #root: {#opacity: StyleProperty('root-opacity')}
  }
};

@VectorWithSomeStyles(
  MyVector,
  wantedStyles: _myVectorOptimizedForFadeWantedStyles,
)
const Vector myVectorOptimizedForFade = _$myVectorOptimizedForFade;
*/
