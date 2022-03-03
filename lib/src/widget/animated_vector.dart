import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide Animation, ClipPath;
import 'package:vector_drawable/src/model/style.dart';
import 'package:vector_drawable/src/widget/src/attributes.dart';
import '../model/vector_drawable.dart';
import 'src/animator/animator.dart';
import 'src/animator/object.dart';
import 'src/animator/set.dart';
import 'src/interpolation.dart';
import 'vector.dart';
import '../model/animated_vector_drawable.dart';
import '../model/animation.dart';
import 'package:value_notifier/value_notifier.dart';

class _StartOffsetAndThemableAttributes {
  final int startOffset;
  final List<String> themableAttributes;

  _StartOffsetAndThemableAttributes(this.startOffset, this.themableAttributes);
}

class AnimationStyleResolver extends StyleMapping with DiagnosticableTreeMixin {
  final StyleMapping parentResolver;
  final List<StyleResolvable<Object>?> properties;

  AnimationStyleResolver(
    this.parentResolver,
    this.properties,
  );

  static const kNamespace = 'runtime-animation';

  @override
  T? resolve<T>(StyleProperty property) {
    if (property.namespace != kNamespace) {
      return parentResolver.resolve(property);
    }
    final index = int.parse(property.name);
    final prop = properties[index];
    if (prop == null) {
      return null;
    }
    return resolveStyledAs(prop, parentResolver) as T;
  }

  @override
  bool containsAny(Set<StyleProperty> props) =>
      props.any((e) => e.namespace == kNamespace) ||
      parentResolver.containsAny(props);

  @override
  bool contains(StyleProperty prop) =>
      prop.namespace == kNamespace || parentResolver.contains(prop);

  @override
  List<DiagnosticsNode> debugDescribeChildren() => properties
      .map((e) => e?.toDiagnosticsNode() ?? DiagnosticsProperty('prop', null))
      .toList();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty('parentResolver', parentResolver));
  }
}

class AnimatedVectorWidget extends StatefulWidget {
  const AnimatedVectorWidget({
    Key? key,
    required this.animatedVector,
    this.styleMapping = StyleMapping.empty,
    this.onStatusChange,
  }) : super(key: key);
  final AnimatedVector animatedVector;
  final StyleMapping styleMapping;
  final ValueChanged<AnimatorStatus>? onStatusChange;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty('animatedVector', animatedVector));
    properties.add(DiagnosticsProperty('styleMapping', styleMapping,
        defaultValue: StyleMapping.empty));
  }

  @override
  AnimatedVectorState createState() => AnimatedVectorState();
}

Map<String, VectorDrawableNode> _namedBaseVectorElements(
    VectorDrawableNode node) {
  if (node is Vector) {
    return node.children.map(_namedBaseVectorElements).fold({
      if (node.name != null) node.name!: node,
      for (final node in node.children.where((child) => child.name != null))
        node.name!: node,
    }, (acc, map) => acc..addAll(map));
  }
  if (node is Group) {
    return node.children.map(_namedBaseVectorElements).fold({
      if (node.name != null) node.name!: node,
      for (final node in node.children.where((child) => child.name != null))
        node.name!: node,
    }, (acc, map) => acc..addAll(map));
  }
  if (node is ClipPath) {
    return node.children.map(_namedBaseVectorElements).fold({
      if (node.name != null) node.name!: node,
      for (final node in node.children.where((child) => child.name != null))
        node.name!: node,
    }, (acc, map) => acc..addAll(map));
  }
  return {
    if (node.name != null) node.name!: node,
  };
}

class AnimatedVectorState extends State<AnimatedVectorWidget>
    with TickerProviderStateMixin
    implements Animator {
  AnimatedVector? _currentVector;
  late Vector base;
  late Vector animatable;
  final Map<VectorDrawableNode, AnimatorWithValues> targetAnimators = {};
  late Map<String, VectorDrawableNode> namedBaseElements;
  // owns all other animators
  late AnimatorSet root;
  late IDisposable _animatorStatusListener;
  final Map<VectorDrawableNode, _StartOffsetAndThemableAttributes>
      _nodePropsMap = {};
  int startOffset = 0;
  int propsLength = 0;
  void _removeStuffFromOldVector() {
    assert(_currentVector != null);
    _nodePropsMap.clear();
    startOffset = 0;
    propsLength = 0;
    targetAnimators.clear();
    root.dispose();
    _animatorStatusListener.dispose();
    _currentVector = null;
  }

  void _onStatus(AnimatorStatus status) => widget.onStatusChange?.call(status);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty('base', base));
    properties.add(DiagnosticsProperty('animatable', animatable));
    properties.add(DiagnosticsProperty('targetAnimators', targetAnimators));
    properties.add(DiagnosticsProperty('animationRoot', root));
    properties.add(DiagnosticsProperty('dynamicProps',
        _buildDynamicStyleResolver(StyleMapping.empty).properties));
  }

  void _createStuffForVector(AnimatedVector vector) {
    assert(_currentVector == null);
    assert(targetAnimators.isEmpty);
    assert(_nodePropsMap.isEmpty);
    assert(startOffset == 0);
    assert(propsLength == 0);
    base = vector.drawable.resource!.body;
    root = widget.animatedVector.children.isEmpty
        ? EmptyAnimatorSet()
        : _createTargetAnimators(_namedBaseVectorElements(base));
    _animatorStatusListener = root.status.unique().tap(_onStatus);
    animatable = _buildAnimatableVector();
    _currentVector = vector;
  }

  Animator? _createTargetAnimator(
      Map<String, VectorDrawableNode> namedBaseElements, Target target) {
    if (!namedBaseElements.containsKey(target.name)) {
      return null;
    }
    final targetElement = namedBaseElements[target.name]!;
    final anim = target.animation.resource!;
    AnimatorWithValues buildAnimator(AnimationNode node) {
      if (node is AnimationSet) {
        return AnimatorSet(animation: node, childFactory: buildAnimator);
      }
      if (node is ObjectAnimation) {
        return ObjectAnimator.from(
          target: targetElement,
          animation: node,
          vsync: this,
        );
      }
      throw UnimplementedError();
    }

    return targetAnimators[targetElement] =
        (buildAnimator(anim.body) as AnimatorWithValues);
  }

  AnimatorSet _createTargetAnimators(
    Map<String, VectorDrawableNode> namedBaseElements,
  ) =>
      TogetherAnimatorSet(widget.animatedVector.children
          .map((target) => _createTargetAnimator(namedBaseElements, target))
          .where((e) => e != null)
          .toList()
          .cast());

  void initState() {
    super.initState();
    _createStuffForVector(widget.animatedVector);
  }

  @override
  void didUpdateWidget(AnimatedVectorWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animatedVector != widget.animatedVector) {
      _removeStuffFromOldVector();
      _createStuffForVector(widget.animatedVector);
    }
  }

  void dispose() {
    _removeStuffFromOldVector();
    super.dispose();
  }

  List<String> _propertiesFromNode(
    VectorDrawableNode node,
  ) {
    if (!targetAnimators.containsKey(node)) {
      return const [];
    }
    final animator = targetAnimators[node]!;
    return animator.nonUniqueAnimatedAttributes.toSet().toList();
  }

  Iterable<StyleResolvable<Object>?> _dynamicPropsFrom(
    VectorDrawableNode node,
    AnimatorWithValues animator,
    List<String> themableAttrs,
  ) {
    final props = animator.values;
    return themableAttrs.map(
      (prop) {
        final themable = props[prop];
        if (themable == null) {
          final base = node.getThemeableAttribute(prop);
          return base == null ? null : SingleStyleResolvable<Object>(base);
        }
        return themable;
      },
    );
  }

  VectorDrawableNode buildAnimatableTargetFromProperties(
    List<String> animatableProperties,
    VectorDrawableNode target,
    VectorDrawableNode Function(
      VectorDrawableNode,
    )
        buildChild,
  ) {
    final targetStartOffset = startOffset;
    if (animatableProperties.isNotEmpty) {
      _nodePropsMap[target] = _StartOffsetAndThemableAttributes(
          targetStartOffset, animatableProperties);
    }
    startOffset += animatableProperties.length;
    propsLength += animatableProperties.length;

    StyleOr<T>? prop<T>(StyleOr<T>? otherwise, String name) {
      final i = animatableProperties.indexOf(name);
      if (i == -1) {
        return otherwise;
      }
      return StyleOr.style(
        StyleProperty(AnimationStyleResolver.kNamespace,
            (i + targetStartOffset).toString()),
      );
    }

    final t = target;
    if (t is Vector) {
      return Vector(
        name: t.name,
        width: t.width,
        height: t.height,
        viewportWidth: t.viewportWidth,
        viewportHeight: t.viewportHeight,
        tint: t.tint,
        tintMode: t.tintMode,
        autoMirrored: t.autoMirrored,
        opacity: prop(t.opacity, 'alpha')!,
        children: t.children.map(buildChild).toList().cast(),
      );
    } else if (t is Group) {
      return Group(
        name: t.name,
        rotation: prop(t.rotation, 'rotation'),
        pivotX: prop(t.pivotX, 'pivotX'),
        pivotY: prop(
          t.pivotY,
          'pivotY',
        ),
        scaleX: prop(
          t.scaleX,
          'scaleX',
        ),
        scaleY: prop(
          t.scaleY,
          'scaleY',
        ),
        translateX: prop(t.translateX, 'translateX'),
        translateY: prop(t.translateY, 'translateY'),
        children: t.children.map(buildChild).toList().cast(),
      );
    } else if (t is Path) {
      return Path(
        name: t.name,
        pathData: prop(t.pathData, 'pathData')!,
        fillColor: prop(t.fillColor, 'fillColor'),
        strokeColor: prop(t.strokeColor, 'strokeColor'),
        strokeWidth: prop(t.strokeWidth, 'strokeWidth')!,
        strokeAlpha: prop(t.strokeAlpha, 'strokeAlpha')!,
        fillAlpha: prop(t.fillAlpha, 'fillAlpha')!,
        trimPathStart: prop(t.trimPathStart, 'trimPathStart')!,
        trimPathEnd: prop(t.trimPathEnd, 'trimPathEnd')!,
        trimPathOffset: prop(t.trimPathOffset, 'trimPathOffset')!,
        strokeLineCap: t.strokeLineCap,
        strokeLineJoin: t.strokeLineJoin,
        strokeMiterLimit: t.strokeMiterLimit,
        fillType: t.fillType,
      );
    } else if (t is ClipPath) {
      return ClipPath(
        name: t.name,
        pathData: prop(t.pathData, 'pathData')!,
        children: t.children.map(buildChild).toList().cast(),
      );
    } else {
      throw UnimplementedError();
    }
  }

  VectorDrawableNode _buildNodeWithProperties(
    VectorDrawableNode node,
  ) {
    return buildAnimatableTargetFromProperties(
      _propertiesFromNode(node),
      node,
      _buildNodeWithProperties,
    );
  }

  Vector _buildAnimatableVector() {
    return _buildNodeWithProperties(base) as Vector;
  }

  AnimationStyleResolver _buildDynamicStyleResolver(StyleMapping mapping) {
    final props = List<StyleResolvable<Object>?>.filled(propsLength, null);
    for (final e in targetAnimators.entries) {
      final animationInfo = _nodePropsMap[e.key];
      if (animationInfo == null) {
        continue;
      }
      final elementProps =
          _dynamicPropsFrom(e.key, e.value, animationInfo.themableAttributes);
      var i = 0;
      for (final prop in elementProps) {
        props[i + animationInfo.startOffset] = prop;
        i++;
      }
    }
    return AnimationStyleResolver(
      mapping,
      props.cast(),
    );
  }

  Widget _buildVectorWidget(BuildContext context, StyleResolver resolver) {
    return RawVectorWidget(
      vector: animatable,
      styleMapping: resolver,
      cachingStrategy: (root.status.value == AnimatorStatus.forward ||
              root.status.value == AnimatorStatus.reverse)
          ? RenderVectorCachingStrategy.none
          : RenderVectorCachingStrategy.groupAndPath,
    );
  }

  @override
  Widget build(BuildContext context) {
    final styleMapping = widget.styleMapping
        .mergeWith(ColorSchemeStyleMapping(Theme.of(context).colorScheme));
    return AnimatedBuilder(
      animation: changes,
      builder: (context, _) {
        final styleResolver = _buildDynamicStyleResolver(styleMapping);
        return _buildVectorWidget(
          context,
          styleResolver,
        );
      },
    );
  }

  @override
  Listenable get changes => root.changes;

  @override
  ValueListenable<bool> get isCompleted => root.isCompleted;

  @override
  ValueListenable<bool> get isDismissed => root.isDismissed;

  @override
  Future<void> start({bool forward = true, bool fromStart = false}) =>
      root.start(
        forward: forward,
        fromStart: fromStart,
      );

  @override
  void reset({bool toFinish = false}) => root.reset(toFinish: toFinish);

  @override
  ValueListenable<AnimatorStatus> get status => root.status;

  @override
  void stop({bool reset = false}) => root.stop(reset: reset);

  @override
  Duration get totalDuration => root.totalDuration;

  @override
  Iterable<String> get nonUniqueAnimatedAttributes => [];
}
