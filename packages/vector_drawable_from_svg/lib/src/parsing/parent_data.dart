// ignore_for_file: depend_on_referenced_packages

import 'package:vector_drawable_core/model.dart';
import 'package:vector_drawable_core/serializing.dart';
import 'package:vector_drawable_core/vector_drawable_core.dart';
import 'package:vector_drawable_from_svg/src/model/svg_vector_drawable.dart';
import 'package:vector_math/vector_math_64.dart' show Vector2;
import 'package:xml/xml.dart';
import 'package:path_parsing/src/path_parsing.dart';
import 'package:path_parsing/src/path_segment_type.dart';

import '../../parsing.dart';

typedef StyleMap = Map<String, String>;

extension on BasicTransformContext {}

class ParentData extends ReadableSaveableTransformProxy
    with TransformProxyLegacyCompatMixin {
  final IdAndLabel current;
  final ParentData? previous;
  final StyleMap styles;
  final TransformContext _transformContext;
  final BasicTransformContext rootTransformContext;
  int _savedTransformCount = 0;
  AffineMatrix getTransform([bool global = true]) =>
      _transformContext.getTransform(global);
  AffineMatrix getGlobalTransform() => _transformContext.getGlobalTransform();
  AffineMatrix getLocalTransform() => _transformContext.getLocalTransform();
  BasicTransformContext getTransformContext([bool global = true]) =>
      _transformContext.getTransformContext(global);
  BasicTransformContext getTransformContextLocal() =>
      _transformContext.getTransformContextLocal();
  BasicTransformContext getTransformContextGlobal() =>
      _transformContext.getTransformContextGlobal();

  TransformList getTransformList([bool global = true]) =>
      _transformContext.getTransformList(global);
  TransformList getGlobalTransformList() =>
      _transformContext.getGlobalTransformList();
  TransformList getLocalTransformList() =>
      _transformContext.getLocalTransformList();

  @override
  void save() {
    _transformContext.save();
    _savedTransformCount++;
  }

  @override
  void restore() {
    _transformContext.restore();
    _savedTransformCount--;
  }

  bool get hasSavedTransforms => _savedTransformCount > 0;

  @override
  void transformPoint(Vector2 point) {
    _transformContext.transformPoint(point);
  }

  void setRootTransform() {
    _transformContext
        .getLocalTransformList()
        .applyToProxy(rootTransformContext);
  }

  void applyTransformString(String s) {
    final transform = parseTransform(s);
    transform.applyToProxy(_transformContext);
  }

  ParentData.forked(this.current, ParentData this.previous, this.styles)
      : _transformContext = previous._transformContext.fork(),
        rootTransformContext = previous.rootTransformContext;

  ParentData.root(this.current)
      : previous = null,
        styles = {},
        _transformContext = TransformContext.identity(),
        rootTransformContext = BasicTransformContext.identity();

  Iterable<ParentData> get previousParentDatasReversed sync* {
    var it = previous;
    while (it != null) {
      yield it;
      it = it.previous;
    }
  }

  Iterable<ParentData> get previousParentDatas =>
      previousParentDatasReversed.toList().reversed;

  Iterable<ParentData> get parentDatas =>
      previousParentDatas.followedBy([this]);

  Iterable<IdAndLabel> get groups => parentDatas.map((e) => e.current);

  ParentData cloneForChild(IdAndLabel newCurrent) =>
      ParentData.forked(newCurrent, this, {...styles});

  void extractStylesFromElement(XmlElement element) {
    const kStyle = 'style';
    final newStyles =
        element.getAttribute(kStyle)?.mapSelfTo(stylesFromStyleString);
    styles.addAll(newStyles ?? const {});
  }

  void pushPathTransform(String? pathTransform) {
    if (pathTransform != null) {
      _transformContext.save();
      applyTransformString(pathTransform);
    }
  }

  void popPathTransform(String? pathTransform) {
    if (pathTransform != null) {
      _transformContext.restore();
    }
  }

  @override
  void multiply(AffineMatrix mat) {
    _transformContext.multiply(mat);
  }

  @override
  void rotate(double radians, [Vector2? center]) =>
      _transformContext.rotate(radians, center);

  @override
  void scale(Vector2 scale) => _transformContext.scale(scale);

  @override
  void translate(Vector2 offset) => _transformContext.translate(offset);

  @override
  double getScalarScale([bool global = true]) =>
      _transformContext.getScalarScale(global);

  @override
  bool isIdentity([bool global = true]) => _transformContext.isIdentity(global);

  double scaleStrokeWidth(double strokeWidth, [bool global = true]) =>
      _transformContext.getScalarScale(global) * strokeWidth;

  PathData multiplyPath(PathData path, [bool global = true]) =>
      _transformContext.transformPath(path, global);

  @override
  PathData transformPath(PathData path, [bool global = true]) =>
      _transformContext.transformPath(path, global);

  @override
  PathSegmentData transformPathSegment(PathSegmentData pathSegment,
          [bool global = true]) =>
      _transformContext.transformPathSegment(pathSegment, global);

  @override
  ParentData clone() => ParentData.forked(current, this, styles);

  @override
  Vector2 getScale() => _transformContext.getScale();
}

StyleMap mergeStylesWithParent(StyleMap styles, StyleMap parentStyles) => {
      ...parentStyles,
      ...styles,
    };
