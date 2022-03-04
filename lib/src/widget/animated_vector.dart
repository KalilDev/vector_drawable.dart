import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide Animation, ClipPath;
import 'package:vector_drawable/src/model/style.dart';
import 'package:vector_drawable/src/widget/src/attributes.dart';
import '../model/vector_drawable.dart';
import 'src/animator/animator.dart';
import 'src/animator/object.dart';
import 'src/animator/set.dart';
import 'src/animator/targets.dart';
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
    this.controller,
  }) : super(key: key);
  final AnimatedVector animatedVector;
  final StyleMapping styleMapping;
  final ValueChanged<AnimatorStatus>? onStatusChange;
  final AnimatorController? controller;

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
    with SingleTickerProviderStateMixin {
  late AnimatorController _ownedController;
  AnimatorController? _currentController;
  AnimatedVector? _currentVector;
  late Vector base;
  late Vector animatable;
  final Map<VectorDrawableNode, List<Animator>> targetAnimators = {};
  late Map<String, VectorDrawableNode> namedBaseElements;
  // owns all other animators
  late TargetsAnimator root;
  late Animated<TargetsAnimator> animatedRoot;
  late IDisposable _animatorStatusListener;
  final Map<String, _StartOffsetAndThemableAttributes> _nodePropsMap = {};
  final List<StyleResolvable<Object>> propDefaults = [];
  int startOffset = 0;
  int propsLength = 0;
  void _removeStuffFromOldAnimatorController() {
    assert(_currentController != null);
    animatedRoot.dispose();
    _animatorStatusListener.dispose();
    _currentController = null;
  }

  void _removeStuffFromOldVector() {
    assert(_currentVector != null);
    _nodePropsMap.clear();
    propDefaults.clear();
    startOffset = 0;
    propsLength = 0;
    targetAnimators.clear();
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

  void _createStuffForAnimatorController(AnimatorController controller) {
    assert(_currentController == null);
    animatedRoot = controller.animate(root);
    _status.base = animatedRoot.status;
    _animatorStatusListener = animatedRoot.status.unique().tap(_onStatus);
    _currentController = controller;
  }

  void _createStuffForVector(AnimatedVector vector) {
    assert(_currentVector == null);
    assert(targetAnimators.isEmpty);
    assert(_nodePropsMap.isEmpty);
    assert(propDefaults.isEmpty);
    assert(startOffset == 0);
    assert(propsLength == 0);
    base = vector.drawable.resource!.body;
    root = widget.animatedVector.children.isEmpty
        ? TargetsAnimator([])
        : _createTargetAnimators(_namedBaseVectorElements(base));
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
    Animator buildAnimator(AnimationNode node) {
      if (node is AnimationSet) {
        return AnimatorSet(animation: node, childFactory: buildAnimator);
      }
      if (node is ObjectAnimation) {
        return ObjectAnimator.from(
          target: targetElement,
          animation: node,
        );
      }
      throw UnimplementedError();
    }

    final animatorList = targetAnimators.putIfAbsent(targetElement, () => []);
    final newAnimator = buildAnimator(anim.body);
    animatorList.add(newAnimator);
    return newAnimator;
  }

  TargetsAnimator _createTargetAnimators(
    Map<String, VectorDrawableNode> namedBaseElements,
  ) =>
      TargetsAnimator(widget.animatedVector.children
          .map((target) {
            final animator = _createTargetAnimator(namedBaseElements, target);
            return animator == null
                ? null
                : TargetAndAnimator(target.name, animator);
          })
          .where((e) => e != null)
          .toList()
          .cast());

  @override
  void initState() {
    super.initState();
    _ownedController = AnimatorController(vsync: this);
    _createStuffForVector(widget.animatedVector);
    _createStuffForAnimatorController(widget.controller ?? _ownedController);
  }

  @override
  void didUpdateWidget(AnimatedVectorWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animatedVector != widget.animatedVector) {
      _removeStuffFromOldAnimatorController();
      _removeStuffFromOldVector();
      _createStuffForVector(widget.animatedVector);
      _createStuffForAnimatorController(widget.controller ?? _ownedController);
      return;
    }
    if (oldWidget.controller != widget.controller) {
      _removeStuffFromOldAnimatorController();
      _createStuffForAnimatorController(widget.controller ?? _ownedController);
      return;
    }
  }

  @override
  void dispose() {
    _removeStuffFromOldVector();
    _removeStuffFromOldAnimatorController();
    _ownedController.dispose();
    _status.dispose();
    super.dispose();
  }

  List<String> _propertiesFromNode(
    VectorDrawableNode node,
  ) {
    if (!targetAnimators.containsKey(node)) {
      return const [];
    }
    final animators = targetAnimators[node]!;
    final attrs = animators.expand((e) => e.nonUniqueAnimatedAttributes);
    return attrs.toSet().toList();
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
      _nodePropsMap[target.name!] = _StartOffsetAndThemableAttributes(
          targetStartOffset, animatableProperties);
    }
    startOffset += animatableProperties.length;
    propsLength += animatableProperties.length;
    propDefaults.addAll(animatableProperties
        .map(target.getThemeableAttribute)
        .cast<Object>()
        .map((e) =>
            e is StyleResolvable<Object> ? e : SingleStyleResolvable(e)));

    StyleOr<T> prop<T>(StyleOr<T> otherwise, String name) {
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
        opacity: prop(t.opacity, 'alpha'),
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
        pathData: prop(t.pathData, 'pathData'),
        fillColor: prop(t.fillColor, 'fillColor'),
        strokeColor: prop(t.strokeColor, 'strokeColor'),
        strokeWidth: prop(t.strokeWidth, 'strokeWidth'),
        strokeAlpha: prop(t.strokeAlpha, 'strokeAlpha'),
        fillAlpha: prop(t.fillAlpha, 'fillAlpha'),
        trimPathStart: prop(t.trimPathStart, 'trimPathStart'),
        trimPathEnd: prop(t.trimPathEnd, 'trimPathEnd'),
        trimPathOffset: prop(t.trimPathOffset, 'trimPathOffset'),
        strokeLineCap: t.strokeLineCap,
        strokeLineJoin: t.strokeLineJoin,
        strokeMiterLimit: t.strokeMiterLimit,
        fillType: t.fillType,
      );
    } else if (t is ClipPath) {
      return ClipPath(
        name: t.name,
        pathData: prop(t.pathData, 'pathData'),
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
    final props = propDefaults.toList();
    final values = animatedRoot.values.value.map(
      (key, value) =>
          MapEntry(TargetAndAnimator.decodePropertyName(key), value),
    );
    for (final e in values.entries) {
      final targetAndPropName = e.key;
      final animationInfo = _nodePropsMap[targetAndPropName.target];
      if (animationInfo == null) {
        continue;
      }
      final propIndex = animationInfo.themableAttributes
          .indexOf(targetAndPropName.propertyName);
      if (propIndex == -1) {
        continue;
      }
      props[animationInfo.startOffset + propIndex] = e.value;
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
      cachingStrategy: (animatedRoot.status.value == AnimatorStatus.forward ||
              animatedRoot.status.value == AnimatorStatus.reverse)
          ? 0
          : 7,
    );
  }

  @override
  Widget build(BuildContext context) {
    final styleMapping = widget.styleMapping
        .mergeWith(ColorSchemeStyleMapping(Theme.of(context).colorScheme));
    return AnimatedBuilder(
      animation: animatedRoot.values,
      builder: (context, _) {
        final styleResolver = _buildDynamicStyleResolver(styleMapping);
        return _buildVectorWidget(
          context,
          styleResolver,
        );
      },
    );
  }

  ValueListenable<bool> get isCompleted =>
      animatedRoot.status.map((status) => status == AnimatorStatus.completed);

  ValueListenable<bool> get isDismissed =>
      animatedRoot.status.map((status) => status == AnimatorStatus.dismissed);

  void start({bool fromStart = true}) => _currentController!.start(
        fromStart: fromStart,
      );

  void reset() => _currentController!.reset();

  final ProxyValueListenable<AnimatorStatus> _status =
      ProxyValueListenable(SingleValueListenable(AnimatorStatus.dismissed));

  ValueListenable<AnimatorStatus> get status => _status.view();

  void stop({bool reset = false}) => _currentController!.stop(reset: reset);

  Duration get totalDuration => root.totalDuration;
}
