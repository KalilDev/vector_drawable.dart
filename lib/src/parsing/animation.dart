import 'package:flutter/material.dart' hide Animation;
import 'package:md3_clock/widgets/animated_vector/parsing/resource.dart';
import '../model/animation.dart';
import 'package:xml/xml.dart';
import 'package:path_parsing/path_parsing.dart';

import '../model/animation.dart';
import '../model/resource.dart';
import '../model/vector_drawable.dart';
import 'animated_vector_drawable.dart';
import 'exception.dart';
import 'util.dart';

AnimationNode _parseAnimationNode(XmlElement node) {
  switch (node.name.qualified) {
    case 'set':
      return _parseAnimationSet(node);
    case 'objectAnimator':
      return _parseObjectAnimation(node);
    case 'animator':
      return _parseAnimation(node);
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

Animation _parseAnimation(XmlElement node) {
  if (node.name.qualified != 'animator') {
    throw ParseException(node, 'is not animator');
  }
  final valueType =
      node.getAndroidAttribute('valueType')?.map(_parseValueType) ??
          ValueType.floatType;
  return Animation(
    duration: node.getAndroidAttribute('duration')?.map(int.parse) ?? 300,
    valueFrom: node
        .getAndroidAttribute('valueFrom')!
        .map((v) => _parseValue(v, valueType)),
    valueTo: node
        .getAndroidAttribute('valueTo')!
        .map((v) => _parseValue(v, valueType)),
    startOffset: node.getAndroidAttribute('startOffset')?.map(int.parse) ?? 0,
    repeatCount: node.getAndroidAttribute('repeatCount')?.map(int.parse) ?? 0,
    repeatMode: node.getAndroidAttribute('repeatMode')?.map(_parseRepeatMode) ??
        RepeatMode.repeat,
    valueType: valueType,
  );
}

Keyframe _parseKeyframe(XmlElement node) {
  final valueType =
      node.getAndroidAttribute('valueType')?.map(_parseValueType) ??
          ValueType.floatType;
  return Keyframe(
    valueType: valueType,
    value: node
        .getAndroidAttribute('value')!
        .map((v) => _parseValue(v, valueType)),
    fraction: node.getAndroidAttribute('propertyName')!.map(double.parse),
    interpolator: node.inlineResourceOrAttribute('interpolator',
        parse: _parseInterpolator),
  );
}

Interpolator _parseInterpolator(XmlElement el) =>
    Interpolator(null, el.name.local);

PropertyValuesHolder _parsePropertyValuesHolder(XmlElement node) {
  if (node.name.qualified != 'propertyValuesHolder') {
    throw ParseException(node, 'is not propertyValuesHolder');
  }
  final useKeyframes = node.realChildElements.isNotEmpty;
  final valueType =
      node.getAndroidAttribute('valueType')?.map(_parseValueType) ??
          ValueType.floatType;
  return PropertyValuesHolder(
    valueType: valueType,
    propertyName: node.getAndroidAttribute('propertyName')!,
    valueFrom: useKeyframes
        ? null
        : node
            .getAndroidAttribute('valueFrom')
            ?.map((v) => _parseValue(v, valueType)),
    valueTo: useKeyframes
        ? null
        : node
            .getAndroidAttribute('valueTo')!
            .map((v) => _parseValue(v, valueType)),
    keyframes:
        useKeyframes ? node.childElements.map(_parseKeyframe).toList() : null,
  );
}

ObjectAnimation _parseObjectAnimation(XmlElement node) {
  if (node.name.qualified != 'objectAnimator') {
    throw ParseException(node, 'is not objectAnimator');
  }
  final useHolders = node.childElements.isNotEmpty;
  final valueType =
      node.getAndroidAttribute('valueType')?.map(_parseValueType) ??
          ValueType.floatType;
  return ObjectAnimation(
    propertyName: node.getAndroidAttribute('propertyName')!,
    duration: node.getAndroidAttribute('duration')?.map(int.parse) ?? 300,
    valueFrom: useHolders
        ? null
        : node
            .getAndroidAttribute('valueFrom')
            ?.map((v) => _parseValue(v, valueType)),
    valueTo: useHolders
        ? null
        : node
            .getAndroidAttribute('valueTo')!
            .map((v) => _parseValue(v, valueType)),
    startOffset: node.getAndroidAttribute('startOffset')?.map(int.parse) ?? 0,
    repeatCount: node.getAndroidAttribute('repeatCount')?.map(int.parse) ?? 0,
    repeatMode: node.getAndroidAttribute('repeatMode')?.map(_parseRepeatMode) ??
        RepeatMode.repeat,
    valueType: valueType,
    valueHolders: useHolders
        ? node.childElements.map(_parsePropertyValuesHolder).toList()
        : null,
  );
}

AnimationSet _parseAnimationSet(XmlElement node) {
  if (node.name.qualified != 'set') {
    throw ParseException(node, 'is not set');
  }
  return AnimationSet(
    node.getAndroidAttribute('ordering')?.map(_parseAnimationOrdering) ??
        AnimationOrdering.together,
    node.childElements.map(_parseAnimationNode).toList(),
  );
}

AnimationOrdering? _parseAnimationOrdering(String text) =>
    parseEnum(text, AnimationOrdering.values);
RepeatMode? _parseRepeatMode(String text) => parseEnum(text, RepeatMode.values);
ValueType? _parseValueType(String text) => parseEnum(text, ValueType.values);

AnimationResource parseAnimationResource(
        XmlHasChildren docOrEl, ResourceReference? source) =>
    AnimationResource(
      _parseAnimationNode(docOrEl.childElements.single),
      source,
    );
