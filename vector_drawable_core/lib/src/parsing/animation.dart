import 'resource.dart';
import 'style.dart';
import '../model/animation.dart';
import 'package:xml/xml.dart';

import '../model/path.dart';
import '../model/resource.dart';
import 'exception.dart';
import 'util.dart';

AnimationNode _parseAnimationNode(XmlElement node) {
  switch (node.name.qualified) {
    case 'set':
      return _parseAnimationSet(node);
    case 'objectAnimator':
      return _parseObjectAnimation(node);
    default:
      throw ParseException(node, 'is not valid type');
  }
}

Object _parseValue(String value, ValueType type) {
  if (value.startsWith('#')) {
    return parseHexColor(value);
  }
  if (value[0] == '-' || int.tryParse(value[0]) != null || value[0] == '.') {
    switch (type) {
      case ValueType.floatType:
        return double.parse(value);
      case ValueType.intType:
        return int.parse(value);
    }
  }
  return PathData.fromString(value);
}

Keyframe _parseKeyframe(XmlElement node) {
  final valueType =
      node.getAndroidAttribute('valueType')?.mapSelfTo(_parseValueType) ??
          ValueType.floatType;
  return Keyframe(
    valueType: valueType,
    value: node
        .getAndroidAttribute('value')!
        .mapSelfTo((v) => _parseValue(v, valueType)),
    fraction: node.getAndroidAttribute('fraction')!.mapSelfTo(double.parse),
    interpolator: node.inlineResourceOrAttribute(
      'interpolator',
      namespace: kAndroidXmlNamespace,
      parse: Interpolator.parseElement,
    ),
  );
}

PropertyValuesHolder _parsePropertyValuesHolder(XmlElement node) {
  if (node.name.qualified != 'propertyValuesHolder') {
    throw ParseException(node, 'is not propertyValuesHolder');
  }
  final useKeyframes = node.realChildElements.isNotEmpty;
  final valueType =
      node.getAndroidAttribute('valueType')?.mapSelfTo(_parseValueType) ??
          ValueType.floatType;
  return PropertyValuesHolder(
    valueType: valueType,
    propertyName: node.getAndroidAttribute('propertyName')!,
    valueFrom: useKeyframes
        ? null
        : node
            .getAndroidAttribute('valueFrom')
            ?.mapSelfTo((v) => _parseValue(v, valueType)),
    valueTo: useKeyframes
        ? null
        : node
            .getAndroidAttribute('valueTo')!
            .mapSelfTo((v) => _parseValue(v, valueType)),
    interpolator: useKeyframes
        ? null
        : node.inlineResourceOrAttribute(
            'interpolator',
            namespace: kAndroidXmlNamespace,
            parse: Interpolator.parseElement,
          ),
    keyframes: useKeyframes
        ? node.realChildElements.map(_parseKeyframe).toList()
        : null,
  );
}

ObjectAnimation _parseObjectAnimation(XmlElement node) {
  if (node.name.qualified != 'objectAnimator') {
    throw ParseException(node, 'is not objectAnimator');
  }
  final useHolders = node.realChildElements.isNotEmpty;
  final valueType =
      node.getAndroidAttribute('valueType')?.mapSelfTo(_parseValueType) ??
          ValueType.floatType;
  final useCoordinates = node.getAndroidAttribute('pathData') != null;
  return ObjectAnimation(
    propertyName:
        useCoordinates ? null : node.getAndroidAttribute('propertyName'),
    propertyXName:
        useCoordinates ? node.getAndroidAttribute('propertyXName') : null,
    propertyYName:
        useCoordinates ? node.getAndroidAttribute('propertyYName') : null,
    pathData: useCoordinates
        ? node.getStyleOrAndroidAttribute(
            'pathData',
            parse: PathData.fromString,
          )
        : null,
    duration: node.getAndroidAttribute('duration')?.mapSelfTo(int.parse) ?? 300,
    valueFrom: useHolders
        ? null
        : node.getStyleOrAndroidAttribute(
            'valueFrom',
            parse: (v) => _parseValue(v, valueType),
          ),
    valueTo: useHolders
        ? null
        : node.getStyleOrAndroidAttribute(
            'valueTo',
            parse: (v) => _parseValue(v, valueType),
          ),
    startOffset:
        node.getAndroidAttribute('startOffset')?.mapSelfTo(int.parse) ?? 0,
    repeatCount:
        node.getAndroidAttribute('repeatCount')?.mapSelfTo(int.parse) ?? 0,
    repeatMode:
        node.getAndroidAttribute('repeatMode')?.mapSelfTo(_parseRepeatMode) ??
            RepeatMode.repeat,
    valueType: valueType,
    interpolator: useHolders
        ? null
        : node.inlineResourceOrAttribute(
            'interpolator',
            namespace: kAndroidXmlNamespace,
            parse: Interpolator.parseElement,
          ),
    valueHolders: useHolders
        ? node.realChildElements.map(_parsePropertyValuesHolder).toList()
        : null,
  );
}

AnimationSet _parseAnimationSet(XmlElement node) {
  if (node.name.qualified != 'set') {
    throw ParseException(node, 'is not set');
  }
  return AnimationSet(
    node.getAndroidAttribute('ordering')?.mapSelfTo(_parseAnimationOrdering) ??
        AnimationOrdering.together,
    node.childElements.map(_parseAnimationNode).toList(),
  );
}

AnimationOrdering? _parseAnimationOrdering(String text) =>
    parseEnum(text, AnimationOrdering.values);
RepeatMode? _parseRepeatMode(String text) => parseEnum(text, RepeatMode.values);
ValueType? _parseValueType(String text) => parseEnum(text, ValueType.values);

AnimationResource parseAnimationResource(
        XmlElement el, ResourceReference? source) =>
    AnimationResource(
      _parseAnimationNode(el),
      source,
    );
