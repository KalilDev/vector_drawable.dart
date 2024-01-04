import 'resource.dart';
import 'style.dart';
import '../model/animation.dart';
import 'package:xml/xml.dart';

import '../model/color.dart';
import '../model/path.dart';
import 'util.dart';

void _serializeAnimationNode(XmlBuilder b, AnimationNode node) {
  if (node is AnimationSet) {
    _serializeAnimationSet(b, node);
  } else if (node is ObjectAnimation) {
    _serializeObjectAnimation(b, node);
  } else {
    throw TypeError();
  }
}

String _serializeValue(Object value) {
  if (value is VectorColor) {
    return serializeHexColor(value);
  }
  if (value is PathData) {
    return value.toPathDataString(needsSameInput: true);
  }
  return value.toString();
}

void _serializeKeyframe(XmlBuilder b, Keyframe node) {
  b.element('keyframe', nest: () {
    b.androidAttribute('value', node.value?.mapSelfTo(_serializeValue));
    b.androidAttribute('fraction', node.fraction);
    b.inlineResourceOrAttribute<Interpolator>(
      'interpolator',
      node.interpolator,
      namespace: kAndroidXmlNamespace,
      namespacePrefix: 'android',
      serialize: (i) => Interpolator.serializeElement(b, i),
    );
  });
}

void _serializePropertyValuesHolder(XmlBuilder b, PropertyValuesHolder node) {
  b.element('propertyValuesHolder', nest: () {
    b.androidAttribute('propertyName', node.propertyName);
    final useKeyframes = node.keyframes != null;
    if (useKeyframes) {
      for (final child in node.keyframes!) {
        _serializeKeyframe(b, child);
      }
    } else {
      b.androidAttribute(
          'valueFrom', node.valueFrom?.mapSelfTo(_serializeValue));
      b.androidAttribute('valueTo', node.valueTo!.mapSelfTo(_serializeValue));
      b.inlineResourceOrAttribute<Interpolator>(
        'interpolator',
        node.interpolator,
        namespace: kAndroidXmlNamespace,
        namespacePrefix: 'android',
        serialize: (i) => Interpolator.serializeElement(b, i),
      );
    }
  });
}

void _serializeObjectAnimation(XmlBuilder b, ObjectAnimation node) {
  final useHolders = node.valueHolders != null;
  final useCoordinates = node.pathData != null;
  b.element('objectAnimator', nest: () {
    if (useCoordinates) {
      b.androidAttribute('propertyXName', node.propertyXName);
      b.androidAttribute('propertyYName', node.propertyYName);
      b.styleOrAndroidAttribute<PathData>('pathData', node.pathData!,
          stringify: (p) => p.toPathDataString(needsSameInput: true));
    } else {
      b.androidAttribute('propertyName', node.propertyName);
    }
    b.androidAttribute('duration', node.duration);
    if (useHolders) {
      for (final child in node.valueHolders!) {
        _serializePropertyValuesHolder(b, child);
      }
    } else {
      b.styleOrAndroidAttribute('valueFrom', node.valueFrom,
          stringify: _serializeValue);
      b.styleOrAndroidAttribute('valueTo', node.valueTo,
          stringify: _serializeValue);
      b.inlineResourceOrAttribute<Interpolator>(
          'interpolator', node.interpolator,
          namespace: kAndroidXmlNamespace,
          namespacePrefix: 'android',
          serialize: (i) => Interpolator.serializeElement(b, i));
    }
    b.androidAttribute('startOffset', node.startOffset);
    b.androidAttribute('repeatCount', node.repeatCount);
    b.androidAttribute('repeatMode', node.repeatMode.mapSelfTo(serializeEnum));
  });
}

void _serializeAnimationSet(XmlBuilder b, AnimationSet node) {
  b.element('set', nest: () {
    b.androidAttribute('ordering', node.ordering.mapSelfTo(serializeEnum));
    for (final child in node.children) {
      _serializeAnimationNode(b, child);
    }
  });
}

void serializeAnimationResource(XmlBuilder b, AnimationResource node) {
  b.namespace(kAndroidXmlNamespace, 'android');
  b.namespace(kAaptXmlNamespace, 'aapt');
  _serializeAnimationNode(b, node.body);
}
