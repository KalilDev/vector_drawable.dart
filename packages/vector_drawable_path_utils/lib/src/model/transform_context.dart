// ignore_for_file: deprecated_member_use_from_same_package

import 'package:path_parsing/path_parsing.dart';
// ignore: implementation_imports
import 'package:path_parsing/src/path_segment_type.dart';
import 'package:vector_drawable_path_utils/src/model/path.dart';
import 'package:vector_drawable_path_utils/src/serializing/segments.dart';
import 'package:vector_math/vector_math_64.dart';

import '../parsing/transform.dart';
import 'affine_matrix.dart';
import 'transform.dart';
import 'package:meta/meta.dart';

extension _<T> on T {
  R mapSelfTo<R>(R Function(T) fn) => fn(this);
}

@Deprecated('Use TransformProxy')
abstract class LegacyTransformProxy {
  void multiplyBy(AffineMatrix mat);
  void scaleBy(Vector2 scale);
  void translateBy(Vector2 offset);
  void rotate(double radians, [Vector2? center]);
}

abstract class TransformProxy {
  void multiply(AffineMatrix mat);
  void scale(Vector2 scale);
  void translate(Vector2 offset);
  void rotate(double radians, [Vector2? center]);
  TransformProxy clone();
}

mixin TransformProxyLegacyCompatMixin on TransformProxy
    implements LegacyTransformProxy {
  @Deprecated('use multiply')
  @override
  void multiplyBy(AffineMatrix mat) => multiply(mat);

  @Deprecated('use scale')
  @override
  void scaleBy(Vector2 scale) => this.scale(scale);

  @Deprecated('use translate')
  @override
  void translateBy(Vector2 offset) => translate(offset);
}

abstract class ReadableTransformProxy implements TransformProxy {
  PathSegmentData transformPathSegment(PathSegmentData pathSegment);
  PathData transformPath(PathData path);

  void transformPoint(Vector2 point);
  Vector2 getScale();
  double getScalarScale();
  bool isIdentity();
}

abstract class SaveableTransformProxy implements TransformProxy {
  void save();

  void restore();
}

abstract class ReadableSaveableTransformProxy
    implements ReadableTransformProxy, SaveableTransformProxy {}

abstract class TransformProxyWithAffineMatrix implements TransformProxy {
  @protected
  AffineMatrix get protectedTransform;
}

abstract class TransformProxyWithTransformList implements TransformProxy {
  @protected
  TransformList get protectedTransformList;
}

abstract class ReadableTransformProxyWithAffineMatrix
    implements ReadableTransformProxy, TransformProxyWithAffineMatrix {}

abstract class ReadableTransformProxyWithTransformList
    implements ReadableTransformProxy, TransformProxyWithTransformList {}

abstract class TransformProxyWithAffineMatrixAndTransformList
    implements TransformProxyWithTransformList, TransformProxyWithAffineMatrix {
  @protected
  AffineMatrixWithTransformList get protectedAffineMatrixWithTransformList =>
      AffineMatrixWithTransformList(
        protectedTransform,
        protectedTransformList,
      );
}

abstract class ReadableTransformProxyWithAffineMatrixAndTransformList
    extends TransformProxyWithAffineMatrixAndTransformList
    implements
        ReadableTransformProxyWithTransformList,
        ReadableTransformProxyWithAffineMatrix {}

class AffineMatrixWithTransformList {
  final AffineMatrix transform;
  final TransformList transformList;

  AffineMatrixWithTransformList(this.transform, this.transformList);
}

mixin TransformProxyToAffineMatrixMixin on TransformProxyWithAffineMatrix {
  void multiply(AffineMatrix mat) => protectedTransform.multiply(mat);
  void scale(Vector2 scale) => protectedTransform.scale(scale);
  void translate(Vector2 offset) => protectedTransform.translate(offset);
  void rotate(double radians, [Vector2? center]) =>
      protectedTransform.rotate(radians, center);
}

mixin RecordingTransformProxyMixin
    on TransformProxyWithAffineMatrixAndTransformList {
  void multiply(AffineMatrix mat) {
    protectedTransform.multiply(mat);
    _addTransformToList(Matrix.fromAffine(mat));
  }

  void scale(Vector2 scale) {
    protectedTransform.scale(scale);
    _addTransformToList(Scale(scale.x, scale.y));
  }

  void translate(Vector2 offset) {
    protectedTransform.translate(offset);
    _addTransformToList(Translate(offset.x, offset.y));
  }

  void rotate(double radians, [Vector2? center]) {
    protectedTransform.rotate(radians, center);
    _addTransformToList(Rotate(radians, center?.x, center?.y));
  }

  void _addTransformToList(Transform transform) {
    protectedTransformList.transforms.add(transform);
  }
}

mixin SaveableTransformProxyMixin
    on TransformProxyWithAffineMatrixAndTransformList
    implements SaveableTransformProxy {
  @protected
  set protectedTransform(AffineMatrix transform);
  @protected
  set protectedTransformList(TransformList transformList);

  List<AffineMatrixWithTransformList> get protectedSavedTransforms;

  void save() {
    protectedSavedTransforms.add(protectedAffineMatrixWithTransformList);
  }

  void restore() {
    final saved = protectedSavedTransforms.removeLast();
    protectedTransform = saved.transform;
    protectedTransformList = saved.transformList;
  }
}

abstract class LocalAndGlobalTransformProxy implements TransformProxy {
  TransformProxy get protectedLocal;
  TransformProxy get protectedGlobal;
}

abstract class ReadableLocalAndGlobalTransformProxy
    implements LocalAndGlobalTransformProxy {
  @override
  ReadableTransformProxy get protectedLocal;
  @override
  ReadableTransformProxy get protectedGlobal;

  @override
  void transformPoint(Vector2 point, [bool global = true]);

  void transformPointLocal(Vector2 point);

  void transformPointGlobal(Vector2 point);

  @override
  double getScalarScale([bool global = true]);

  double getScalarScaleLocal();

  double getScalarScaleGlobal();

  @override
  bool isIdentity([bool global = true]);

  bool isIdentityLocal();

  bool isIdentityGlobal();
}

abstract class SaveableLocalAndGlobalTransformProxy
    implements LocalAndGlobalTransformProxy {
  @override
  SaveableTransformProxy get protectedLocal;
  @override
  SaveableTransformProxy get protectedGlobal;
}

abstract class ReadableSaveableLocalAndGlobalTransformProxy
    implements
        SaveableLocalAndGlobalTransformProxy,
        ReadableLocalAndGlobalTransformProxy {
  ReadableSaveableTransformProxy get protectedLocal;
  ReadableSaveableTransformProxy get protectedGlobal;
}

mixin ReadableTransformProxyPathMixin on ReadableTransformProxy {
  static final _unitXPathOffset = () {
    final SvgPathStringSource parser = SvgPathStringSource('M 1 0');
    return parser.parseSegment().targetPoint;
  }();
  static final _unitYPathOffset = () {
    final SvgPathStringSource parser = SvgPathStringSource('M 0 1');
    return parser.parseSegment().targetPoint;
  }();
// ignore: prefer_function_declarations_over_variables
  static final _pathOffset = (double dx, double dy) =>
      (_unitXPathOffset * dx) + (_unitYPathOffset * dy);

  static void _copySegmentInto(
          PathSegmentData source, PathSegmentData target) =>
      target
        ..command = source.command
        ..targetPoint = source.targetPoint
        ..point1 = source.point1
        ..point2 = source.point2
        ..arcSweep = source.arcSweep
        ..arcLarge = source.arcLarge;
  @override
  PathSegmentData transformPathSegment(PathSegmentData segment) {
    final newSegment = PathSegmentData();
    _copySegmentInto(segment, newSegment);
    void mulP1() {
      final point = Vector2(segment.point1.dx, segment.point1.dy);
      transformPoint(point);
      newSegment.point1 = _pathOffset(point.x, point.y);
    }

    void mulP2() {
      final point = Vector2(segment.point2.dx, segment.point2.dy);
      transformPoint(point);
      newSegment.point2 = _pathOffset(point.x, point.y);
    }

    void mulTarget() {
      final point = Vector2(segment.targetPoint.dx, segment.targetPoint.dy);
      transformPoint(point);
      newSegment.targetPoint = _pathOffset(point.x, point.y);
    }

    switch (segment.command) {
      case SvgPathSegType.unknown:
      case SvgPathSegType.close:
        return segment;
      case SvgPathSegType.lineToHorizontalAbs:
        mulTarget();
        return newSegment;
      case SvgPathSegType.lineToVerticalAbs:
        mulTarget();
        return newSegment;
      case SvgPathSegType.moveToAbs:
      case SvgPathSegType.moveToRel:
      case SvgPathSegType.lineToAbs:
      case SvgPathSegType.smoothQuadToAbs:
        mulTarget();
        return newSegment;
      case SvgPathSegType.cubicToAbs:
        mulP1();
        mulP2();
        mulTarget();
        return newSegment;
      case SvgPathSegType.quadToAbs:
        mulP1();
        mulTarget();
        return newSegment;
      case SvgPathSegType.smoothCubicToAbs:
        mulP2();
        mulTarget();
        return newSegment;
      case SvgPathSegType.arcToAbs:
        mulP1();
        mulTarget();
        return newSegment;
      case SvgPathSegType.smoothCubicToRel:
      case SvgPathSegType.arcToRel:
      case SvgPathSegType.quadToRel:
      case SvgPathSegType.cubicToRel:
      case SvgPathSegType.smoothQuadToRel:
      case SvgPathSegType.lineToRel:
      case SvgPathSegType.lineToVerticalRel:
      case SvgPathSegType.lineToHorizontalRel:
        throw UnimplementedError();
        return segment;
    }
  }

  @override
  PathData transformPath(PathData path) {
    if (isIdentity()) {
      return path;
    }

    final simplifiedPath =
        PathData.fromString(path.toSimplifiedPathDataString());
    final transformedPath = PathData.fromString(segmentsToPathString(
        simplifiedPath.segments.map(transformPathSegment)));
    return transformedPath;
  }
}

class BasicTransformContext
    extends ReadableTransformProxyWithAffineMatrixAndTransformList
    with
        SaveableTransformProxyMixin,
        RecordingTransformProxyMixin,
        ReadableTransformProxyPathMixin
    implements ReadableSaveableTransformProxy {
  AffineMatrix _transform;
  TransformList _transformList;
  BasicTransformContext.raw(
    AffineMatrix transform,
    TransformList transformList,
  )   : _transform = transform.clone(),
        _transformList = TransformList(transformList.transforms.toList());
  BasicTransformContext.identity()
      : _transform = AffineMatrix.identity(),
        _transformList = TransformList([]);

  BasicTransformContext clone() =>
      BasicTransformContext.raw(_transform, _transformList);

  final List<AffineMatrixWithTransformList> _savedTransforms = [];
  @override
  AffineMatrix get protectedTransform => _transform;

  @override
  TransformList get protectedTransformList => _transformList;

  AffineMatrix get transform => _transform.clone();

  TransformList get transformList =>
      TransformList(_transformList.transforms.toList());

  @override
  List<AffineMatrixWithTransformList> get protectedSavedTransforms =>
      _savedTransforms;

  @override
  set protectedTransformList(TransformList transformList) {
    _transformList = transformList;
  }

  @override
  set protectedTransform(AffineMatrix transform) {
    _transform = transform;
  }

  @override
  void transformPoint(Vector2 point) {
    _transform.transformPoint(point);
  }

  @override
  double getScalarScale() => _transform.getScalarScale();

  @override
  bool isIdentity() => _transform.isIdentity();

  @override
  Vector2 getScale() => _transform.getScale();
}

class TransformContext extends ReadableSaveableTransformProxy
    with TransformProxyLegacyCompatMixin
    implements ReadableSaveableLocalAndGlobalTransformProxy {
  final BasicTransformContext _local;
  final BasicTransformContext _global;

  @override
  PathSegmentData transformPathSegment(PathSegmentData segment,
          [bool global = true]) =>
      global
          ? _global.transformPathSegment(segment)
          : _local.transformPathSegment(segment);

  @override
  PathData transformPath(PathData path, [bool global = true]) =>
      global ? _global.transformPath(path) : _local.transformPath(path);
  TransformContext fork() => TransformContext(_global);

  TransformContext(BasicTransformContext parent)
      : _local = BasicTransformContext.identity(),
        _global = parent.clone();

  TransformContext.identity()
      : _local = BasicTransformContext.identity(),
        _global = BasicTransformContext.identity();

  @override
  void multiply(AffineMatrix mat) {
    _local.multiply(mat);
    _global.multiply(mat);
  }

  @override
  void restore() {
    _local.restore();
    _global.restore();
  }

  @override
  void rotate(double radians, [Vector2? center]) {
    _local.rotate(radians, center);
    _global.rotate(radians, center);
  }

  @override
  void save() {
    _local.save();
    _global.save();
  }

  @override
  void scale(Vector2 scale) {
    _local.scale(scale);
    _global.scale(scale);
  }

  @override
  AffineMatrix getTransform([bool global = true]) =>
      global ? getGlobalTransform() : getLocalTransform();
  AffineMatrix getGlobalTransform() => _global.transform;
  AffineMatrix getLocalTransform() => _local.transform;

  @override
  TransformList getTransformList([bool global = true]) =>
      global ? getGlobalTransformList() : getLocalTransformList();
  TransformList getGlobalTransformList() => _global.transformList;
  TransformList getLocalTransformList() => _local.transformList;

  @override
  void transformPoint(Vector2 point, [bool global = true]) {
    if (global) {
      return transformPointGlobal(point);
    }
    transformPointLocal(point);
  }

  void transformPointGlobal(Vector2 point) {
    _global.transformPoint(point);
  }

  @override
  void translate(Vector2 offset) {
    _local.translate(offset);
    _global.translate(offset);
  }

  @override
  ReadableSaveableTransformProxy get protectedGlobal => _global;

  @override
  ReadableSaveableTransformProxy get protectedLocal => _local;

  @override
  void transformPointLocal(Vector2 point) => _local.transformPoint(point);

  @override
  double getScalarScale([bool global = true]) =>
      global ? getScalarScaleGlobal() : getScalarScaleLocal();

  @override
  double getScalarScaleGlobal() => _global.getScalarScale();

  @override
  double getScalarScaleLocal() => _local.getScalarScale();

  @override
  bool isIdentity([bool global = true]) =>
      global ? isIdentityGlobal() : isIdentityLocal();
  bool isIdentityLocal() => _local.isIdentity();
  bool isIdentityGlobal() => _global.isIdentity();

  @override
  BasicTransformContext getTransformContext([bool global = true]) =>
      global ? getTransformContextGlobal() : getTransformContextLocal();
  BasicTransformContext getTransformContextLocal() => _local.clone();
  BasicTransformContext getTransformContextGlobal() => _global.clone();

  @override
  TransformContext clone([bool global = true]) =>
      TransformContext(getTransformContext(global));

  @override
  Vector2 getScale([bool global = true]) =>
      global ? getScaleGlobal() : getScaleLocal();

  Vector2 getScaleGlobal() => _global.getScale();
  Vector2 getScaleLocal() => _local.getScale();
}

/*
typedef MatrixImpl = AffineMatrix;

class TransformContext extends ReadableSaveableTransformProxy {
  //final MakeImplIdentity<MatrixImpl> _makeImplIdentity;
  final MatrixImpl _transform;
  final MatrixImpl _localTransform;

  final List<MatrixImpl> _savedTransforms = [];
  final List<TransformList> _previousOperationsString;
  final TransformList _localOperations = TransformList([]);

  double getRotation() => _transform.getRotation();
  double getLocalRotation() => _localTransform.getRotation();

  bool get isIdentity => _transform.isIdentity;
  bool get isLocalIdentity => _localTransform.isIdentity;

  Vector2 get totalTranslation => Vector2(_transform.e, _transform.f);
  Vector2 removeTotalTranslation({bool evenLocked = false}) {
    final t = totalTranslation;
    if (evenLocked) {
      translateBy(-t);
    } else {
      translateBy(-t);
    }
    if (t.x > 0.3 || t.y > 0.3) {
      print(_transform);
      print(_localTransform);
    }
    return t;
  }

  Vector2 get localTranslation => Vector2(_localTransform.e, _localTransform.f);
  Vector2 removeLocalTranslation({bool evenLocked = false}) {
    final t = localTranslation;
    if (evenLocked) {
      translateBy(-t);
    } else {
      translateBy(-t);
    }
    if (t.x.abs() > 0.3 || t.y.abs() > 0.3) {
      print(_transform);
      print(_localTransform);
    }
    return t;
  }

  TransformContext._(
    this._transform,
    this._localTransform,
    this._previousOperationsString,
    //this._makeImplIdentity,
  );
  TransformContext.identity(/*MakeImplIdentity<MatrixImpl> makeImplIdentity*/)
      : //_makeImplIdentity = makeImplIdentity,
        _localTransform = MatrixImpl.identity(),
        _transform = MatrixImpl.identity(),
        _previousOperationsString = '';
  TransformContext._fromOther(MatrixImpl transform,
      this._previousOperationsString /*, this._makeImplIdentity*/)
      : _localTransform = MatrixImpl.identity(),
        _transform = transform.clone() as MatrixImpl;

  factory TransformContext.parseFromString(String? transformString) {
    final id = TransformContext.identity();
    if (transformString == null) {
      return id;
    }
    return id..applyTransformString(transformString);
  }

  bool _isTransformLocked = false;
  void lockTransform() => _isTransformLocked = true;

  MatrixImpl getLocalTransform() => _localTransform.clone() as MatrixImpl;
  MatrixImpl getTransform() => _transform.clone() as MatrixImpl;

  void saveTransform() {
    _savedTransforms.add(_transform.clone());
    _savedLocalOperationsString.add(_localOperationsString);
    _savedSubtreeNeedsInlineTransform.add(_subtreeNeedsInlineTransform);
  }

  void restoreTransform() {
    _transform.setFromOther(_savedTransforms.removeLast());
    _localOperationsString = _savedLocalOperationsString.removeLast();
    _subtreeNeedsInlineTransform =
        _savedSubtreeNeedsInlineTransform.removeLast();
  }

  void transformPoint(Vector2 point) {
    _transform.transformPoint(point);
  }

  void transformPointLocal(Vector2 point) {
    _localTransform.transformPoint(point);
  }

  TransformContext fork() =>
      TransformContext._fromOther(_transform, operationsString);

  static Never _throwLocked() => throw StateError("Fuck youuuu");
  final List<bool> _savedSubtreeNeedsInlineTransform = [];
  bool _subtreeNeedsInlineTransform = false;

  bool get subtreeNeedsInlineTransform => _subtreeNeedsInlineTransform;
  void multiplyBy(
    AffineMatrix mat, {
    bool thisForSureIsSafeWithoutInlineTransform = false,
  }) {
    _multiplyBy(mat);
    if (!thisForSureIsSafeWithoutInlineTransform) {
      _subtreeNeedsInlineTransform |= !_transform.isIdentity &&
          !_transform.isRotateNoPivot &&
          !_transform.isScaleAndOrTranslate;
    }
    _appendTransform(Matrix(mat.a, mat.b, mat.c, mat.d, mat.e, mat.f));
  }

  void _multiplyBy(AffineMatrix matrix) {
    if (_isTransformLocked) {
      _throwLocked();
    }
    if (!matrix.isScaleAndOrTranslate) {
      _subtreeNeedsInlineTransform = true;
    }
    _transform.multiply(matrix);
    _localTransform.multiply(matrix);
  }

  void _scaleBy(Vector2 scale) {
    if (_isTransformLocked) {
      _throwLocked();
    }
    _transform.scale(scale.x, scale.y);
    _localTransform.scale(scale.x, scale.y);
  }

  void scaleBy(Vector2 scale) {
    _scaleBy(scale);
    _appendTransform(Scale(scale.x, scale.y));
  }

  void translateBy(Vector2 vector2) {
    _translateBy(vector2);
    _appendTransform(Translate(vector2.x, vector2.y));
  }

  void _translateBy(Vector2 vector2) {
    if (_isTransformLocked) {
      _throwLocked();
    }
    _transform.translate(vector2);
    _localTransform.translate(vector2);
  }

  void rotate(double radians, [Vector2? center]) {
    _rotate(radians, center);
    const EPSILON = 0.001;
    if (center != null && center.length2 > EPSILON) {
      _subtreeNeedsInlineTransform = true;
    }
    _appendTransformString(
        'rotate(${radians * radians2Degrees}${center?.x.mapSelfTo((x) => ' $x') ?? ''}${center?.x.mapSelfTo((y) => ' $y') ?? ''})');
  }

  void _appendTransformString(String s) => _localOperationsString.isEmpty
      ? _localOperationsString = s
      : _localOperationsString += ' $s';

  void _rotate(double radians, [Vector2? center]) {
    if (_isTransformLocked) {
      _throwLocked();
    }
    _transform.rotate(radians, center);
    _localTransform.rotate(radians, center);
  }

  String get operationsString =>
      _previousOperationsString + _localOperationsString;

  Vector2 getScale() => _transform.getScale();
  Vector2 getLocalScale() => _localTransform.getScale();
  double getScalarScale() => _transform.getScalarScale();
  double getLocalScalarScale() => _localTransform.getScalarScale();

  void applyTransformString(String s) => parseTransform(s, this);

  void saveAndApplyTransformString(String s) {
    saveTransform();
    applyTransformString(s);
  }
}
*/