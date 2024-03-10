import 'package:vector_drawable_annotation/vector_drawable_annotation.dart';
import 'package:vector_drawable_style_extractor/model.dart';
import 'package:vector_drawable_core/model.dart';

part 'pitu.g.dart';

const debugSvgPath = 'debug.svg';
const debugSvg = VectorFromSvg(debugSvgPath,
    inlineTransforms: false, makeViewportVectorSized: false);
const debugSvgInlinedTransforms = VectorFromSvg(debugSvgPath,
    inlineTransforms: true, makeViewportVectorSized: false);
const debugSvgViewportSized = VectorFromSvg(debugSvgPath,
    inlineTransforms: false, makeViewportVectorSized: true);
const debugSvgInlinedTransformsAndViewportSized = VectorFromSvg(debugSvgPath,
    inlineTransforms: true, makeViewportVectorSized: true);

const pituSvgPath = 'full.svg';
const pituSvg = VectorFromSvg(pituSvgPath,
    inlineTransforms: false,
    makeViewportVectorSized: true,
    dimensionKind: DimensionKind.dp);

@pituSvg
const Vector pituVectorWithoutExtractedStyles =
    _$pituVectorWithoutExtractedStyles;

/*
@debugSvg
const Vector debugVectorWithoutExtractedStyles =
    _$debugVectorWithoutExtractedStyles;

@debugSvgInlinedTransforms
const Vector debugVectorInlinedTransformsWithoutExtractedStyles =
    _$debugVectorInlinedTransformsWithoutExtractedStyles;

@debugSvgViewportSized
const Vector debugVectorViewportSizedWithoutExtractedStyles =
    _$debugVectorViewportSizedWithoutExtractedStyles;

@debugSvgInlinedTransformsAndViewportSized
const Vector
    debugVectorInlinedTransformsAndViewportSizedWithoutExtractedStyles =
    _$debugVectorInlinedTransformsAndViewportSizedWithoutExtractedStyles;
*/
enum Feature {
  inlinedTransforms,
  viewportSized,
}

const _inlineTransforms = 1;
const _viewportSized = 2;

const _inlineTransformsAndViewportSized = _inlineTransforms | _viewportSized;

Vector debugVectorWithFeatures(Set<Feature> features) {
  return pituVectorWithoutExtractedStyles;
  var bitset = 0;
  if (features.contains(Feature.inlinedTransforms)) bitset |= _inlineTransforms;
  if (features.contains(Feature.viewportSized)) bitset |= _viewportSized;
  const featureList = [
    /*
    debugVectorWithoutExtractedStyles,
    debugVectorInlinedTransformsWithoutExtractedStyles,
    debugVectorViewportSizedWithoutExtractedStyles,
    debugVectorInlinedTransformsAndViewportSizedWithoutExtractedStyles*/
  ];
  return featureList[bitset];
}
/*
@pituSvg
const VectorWithExtractedStyles pituVectorWithExtractedStyles =
    _$pituVectorWithExtractedStyles;*/

@pituSvg
const Vector pituVector = _$pituVector;

const liamEarDetail = StyleProperty('color', 'liam:earDetail');
const liamShyCheeks = StyleProperty('color', 'liam:shyCheeks');
const liamStroke = StyleProperty('color', 'liam:stroke');
const liamWhiskers = StyleProperty('color', 'liam:whiskers');
const liamWhiskersWidth = StyleProperty('color', 'liam:whiskersWidth');
const liamNose = StyleProperty('color', 'liam:nose');
const liamEyes = StyleProperty('color', 'liam:eyes');
const liamFill = StyleProperty('color', 'liam:fill');

const kalilStroke = StyleProperty('color', 'kalil:stroke');
const kalilEyes = StyleProperty('color', 'kalil:eyes');
const kalilNose = StyleProperty('color', 'kalil:nose');
const kalilWhiskers = StyleProperty('color', 'kalil:whiskers');
const kalilBodyFill = StyleProperty('color', 'kalil:bodyFill');
const kalilTailFill = StyleProperty('color', 'kalil:tailFill');

const heartStroke = StyleProperty('color', 'heart:stroke');
const heartFill = StyleProperty('color', 'heart:fill');

const liamRed = StyleProperty('color', 'liam:red');
const kalilPurple = StyleProperty('color', 'kalil:purple');

const yinX = StyleProperty('animation', 'yin:x');
const yanX = StyleProperty('animation', 'yan:x');
const heartScale = StyleProperty('animation', 'heart:scale');

const yinFill = liamRed;
const yanFill = kalilPurple;

const _g28_2 = Symbol('g28-2');
const _rect29_8 = Symbol('rect29-8');
const _path7_5 = Symbol('path7-5');
const _path19_9 = Symbol('path19-9');
const _path22_6 = Symbol('path22-6');
const _path22_6_97 = Symbol('path22-6-97');

const _path27_3_9 = Symbol('path27-3-9');
const _path27_6 = Symbol('path27-6');
const _path27_3_9_6 = Symbol('path27-3-9-6');
const _path18_5 = Symbol('path18-5');
const _path39_2 = Symbol('path39-2');
const _path20_2 = Symbol('path20-2');
const _path2_1_9 = Symbol('path2-1-9');
const _path3_5_3 = Symbol('path3-5-3');
const _path4_4_6 = Symbol('path4-4-6');
const _path19_7_9_1 = Symbol('path19-7-9-1');
const _path19_7_3_3_9 = Symbol('path19-7-3-3-9');
const _path6_7_5_9 = Symbol('path6-7-5-9');
const _path21_2_6_3 = Symbol('path21-2-6-3');
const _path6_6_2 = Symbol('path6-6-2');
const _path21_7_4 = Symbol('path21-7-4');
const _path22_6_7_5_8 = Symbol('path22-6-7-5-8');
const _path22_6_9_5_2_4 = Symbol('path22-6-9-5-2-4');
const _path20_2_9_5_5 = Symbol('path20-2-9-5-5');
const _path23_7_3 = Symbol('path23-7-3');
const _path23_9_4_6 = Symbol('path23-9-4-6');
const _path23_4_4_1 = Symbol('path23-4-4-1');
const _path23_1_0_6 = Symbol('path23-1-0-6');
const _path23_9_0_7_3 = Symbol('path23-9-0-7-3');
const _path23_4_6_8_2 = Symbol('path23-4-6-8-2');
const _path1_5_7 = Symbol('path1-5-7');
const _path5_7_1 = Symbol('path5-7-1');
@VectorWithSomeStyles(pituSvg, wantedStyles: {
  VectorDrawableNodeType.Group: {
    _g28_2: {
      #translateX: yanX,
    },
    #g28: {
      #translateX: yinX,
    },
    #g1: {
      #scaleX: heartScale,
      #scaleY: heartScale,
    },
  },
  VectorDrawableNodeType.Path: {
    // Bg
    #rect29: {
      #fillColor: yanFill,
    },
    _rect29_8: {
      #fillColor: yinFill,
    },
    // Yin
    #path27: {
      #fillColor: yinFill,
    },
    _path27_3_9: {
      #fillColor: yanFill,
    },
    // Yan
    _path27_6: {
      #fillColor: yanFill,
    },
    _path27_3_9_6: {
      #fillColor: yinFill,
    },
    // Kalil
    // - Fill
    //   - Body
    #path52: {
      #fillColor: kalilBodyFill,
    },
    //   end Body
    //   - Tail
    _path18_5: {
      #fillColor: kalilTailFill,
    },
    //   end Tail
    // - Stroke
    //   - Contour
    //     - Body
    //       - Feet
    #path7: {
      #strokeColor: kalilStroke,
    },
    _path7_5: {
      #strokeColor: kalilStroke,
    },
    //       end Feet
    #path8: {
      #strokeColor: kalilStroke,
    },
    #path9: {
      #strokeColor: kalilStroke,
    },
    #path10: {
      #strokeColor: kalilStroke,
    },
    #path11: {
      #strokeColor: kalilStroke,
    },
    #path14: {
      #strokeColor: kalilStroke,
    },
    //       - Ears
    //         - Left
    #path12: {
      #strokeColor: kalilStroke,
    },
    #path13: {
      #strokeColor: kalilStroke,
    },
    //         end Left
    //         - Right
    #path15: {
      #strokeColor: kalilStroke,
    },
    //         end Right
    //       end Ears
    //     end Body
    //     - Tail
    #path16: {
      #strokeColor: kalilStroke,
    },
    #path17: {
      #strokeColor: kalilStroke,
    },
    #path18: {
      #strokeColor: kalilStroke,
    },
    //     end Tail
    //   end Contour
    //  - Eyes
    #path19: {
      #fillColor: kalilEyes,
    },
    _path19_9: {
      #fillColor: kalilEyes,
    },
    //  end Eyes
    //  - Whiskers
    _path22_6: {
      #strokeColor: kalilWhiskers,
    },
    _path22_6_97: {
      #strokeColor: kalilWhiskers,
    },
    _path20_2: {
      #fillColor: kalilNose,
    },
    //    end Whiskers
    //  end Stroke
    // end Kalil
    // Liam
    // - Fill
    _path39_2: {
      #fillColor: liamFill,
    },
    // - Stroke
    #path44: {
      #strokeColor: liamStroke,
    },
    _path2_1_9: {
      #strokeColor: liamStroke,
    },
    #path43: {
      #strokeColor: liamStroke,
    },
    //  - Feet
    _path1_5_7: {
      #strokeColor: liamStroke,
    },
    _path3_5_3: {
      #strokeColor: liamStroke,
    },
    //  end Feet
    _path4_4_6: {
      #strokeColor: liamStroke,
    },
    _path5_7_1: {
      #strokeColor: liamStroke,
    },
    #path40: {
      #strokeColor: liamStroke,
    },
    //  - Eyes
    _path19_7_9_1: {
      #fillColor: liamEyes,
    },
    _path19_7_3_3_9: {
      #fillColor: liamEyes,
    },
    //  end Eyes
    //  - Ears
    //    - Right
    _path6_7_5_9: {
      #strokeColor: liamEarDetail,
    },
    _path21_2_6_3: {
      #strokeColor: liamStroke,
    },
    //    end Right
    //    - Left
    _path6_6_2: {
      #strokeColor: liamStroke,
    },
    _path21_7_4: {
      #strokeColor: liamEarDetail,
    },
    //    end Left
    //  end Ears
    //  - Whiskers
    _path22_6_7_5_8: {
      #strokeColor: liamWhiskers,
      #strokeWidth: liamWhiskersWidth,
    },
    _path22_6_9_5_2_4: {
      #strokeColor: liamWhiskers,
      #strokeWidth: liamWhiskersWidth,
    },
    _path20_2_9_5_5: {
      #fillColor: liamNose,
    },
    //  end Whiskers
    //  - Cheeks
    //    - Left
    _path23_7_3: {
      #strokeColor: liamShyCheeks,
    },
    _path23_9_4_6: {
      #strokeColor: liamShyCheeks,
    },
    _path23_4_4_1: {
      #strokeColor: liamShyCheeks,
    },
    //    end Left
    //    - Right
    _path23_1_0_6: {
      #strokeColor: liamShyCheeks,
    },
    _path23_9_0_7_3: {
      #strokeColor: liamShyCheeks,
    },
    _path23_4_6_8_2: {
      #strokeColor: liamShyCheeks,
    },
    //    end Right
    //  end Cheeks
    // end Liam
    // Heart
    #path23: {
      #strokeColor: heartStroke,
      #fillColor: heartFill,
    },
  },
  VectorDrawableNodeType.ChildOutlet: {
    #ChildOutlet: {
      #x: StyleProperty('animation', 'child:x'),
      #y: StyleProperty('animation', 'child:y'),
      #width: StyleProperty('animation', 'child:width'),
      #height: StyleProperty('animation', 'child:height'),
    },
  },
})
const Vector pituVectorForAnimation = _$pituVectorForAnimation;
