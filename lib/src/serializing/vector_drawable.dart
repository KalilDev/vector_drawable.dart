import 'dart:collection';

import 'package:flutter/material.dart' hide ClipPath;
import 'package:vector_drawable/src/parsing/style.dart';
import 'package:vector_drawable/src/serializing/style.dart';
import 'package:vector_drawable/vector_drawable.dart';
import 'package:xml/xml.dart';
import 'package:path_parsing/path_parsing.dart';
import 'package:path_parsing/src/path_segment_type.dart';

import '../model/path.dart';
import '../model/resource.dart';
import '../model/vector_drawable.dart';
import 'exception.dart';
import 'util.dart';

void serializeVectorDrawable(
  XmlBuilder b,
  VectorDrawable doc,
) {
  b.namespace(kAndroidXmlNamespace, 'android');
  b.namespace(kAaptXmlNamespace, 'aapt');
  _serializeVector(b, doc.body);
}

void _serializeVector(XmlBuilder b, Vector node) {
  b.element('vector', nest: () {
    b.androidAttribute('name', node.name);
    b.androidAttribute('width', node.width);
    b.androidAttribute('height', node.height);
    b.androidAttribute('viewportWidth', node.viewportWidth);
    b.androidAttribute('viewportHeight', node.viewportHeight);
    b.styleOrAndroidAttribute('tint', node.tint, stringify: serializeHexColor);
    b.androidAttribute('tintMode', node.tintMode.map(_serializeTintMode));
    b.androidAttribute('autoMirrored', node.autoMirrored);
    b.styleOrAndroidAttribute('opacity', node.opacity);
    for (final child in node.children) {
      _serializeVectorPart(b, child);
    }
  });
}

void _serializeGroup(XmlBuilder b, Group node) {
  b.element('group', nest: () {
    b.androidAttribute('name', node.name);
    b.styleOrAndroidAttribute('rotation', node.rotation);
    b.styleOrAndroidAttribute('pivotX', node.pivotX);
    b.styleOrAndroidAttribute('pivotY', node.pivotY);
    b.styleOrAndroidAttribute('scaleX', node.scaleX);
    b.styleOrAndroidAttribute('scaleY', node.scaleY);
    b.styleOrAndroidAttribute('translateX', node.translateX);
    b.styleOrAndroidAttribute('translateY', node.translateY);
    for (final child in node.children) {
      _serializeVectorPart(b, child);
    }
  });
}

void _serializeClipPath(XmlBuilder b, ClipPath node) {
  b.element('clip-path', nest: () {
    b.androidAttribute('name', node.name);
    b.styleOrAndroidAttribute<PathData>(
      'pathData',
      node.pathData,
      stringify: (p) => p.asString,
    );
    for (final child in node.children) {
      _serializeVectorPart(b, child);
    }
  });
}

void _serializePath(XmlBuilder b, Path node) {
  b.element('path', nest: () {
    b.androidAttribute('name', node.name);
    b.styleOrAndroidAttribute<PathData>(
      'pathData',
      node.pathData,
      stringify: (p) => p.asString,
    );
    b.styleOrAndroidAttribute(
      'fillColor',
      node.fillColor,
      stringify: serializeHexColor,
    );
    b.styleOrAndroidAttribute(
      'strokeColor',
      node.strokeColor,
      stringify: serializeHexColor,
    );
    b.styleOrAndroidAttribute('strokeWidth', node.strokeWidth);
    b.styleOrAndroidAttribute('strokeAlpha', node.strokeAlpha);
    b.styleOrAndroidAttribute('fillAlpha', node.fillAlpha);
    b.styleOrAndroidAttribute('trimPathStart', node.trimPathStart);
    b.styleOrAndroidAttribute('trimPathEnd', node.trimPathEnd);
    b.styleOrAndroidAttribute('trimPathOffset', node.trimPathOffset);
    b.androidAttribute('strokeLineCap', node.strokeLineCap.map(serializeEnum));
    b.androidAttribute(
        'strokeLineJoin', node.strokeLineJoin.map(serializeEnum));
    b.androidAttribute('strokeMiterLimit', node.strokeMiterLimit);
    b.androidAttribute('fillType', node.fillType.map(serializeEnum));
  });
}

void _serializeVectorPart(XmlBuilder b, VectorPart node) {
  if (node is Group) {
    _serializeGroup(b, node);
  } else if (node is Path) {
    _serializePath(b, node);
  } else if (node is ClipPath) {
    _serializeClipPath(b, node);
  } else {
    throw TypeError();
  }
}

String? _serializeTintMode(BlendMode tintMode) {
  switch (tintMode) {
    case BlendMode.plus:
      return 'add';
    case BlendMode.multiply:
      return 'multiply';
    case BlendMode.screen:
      return 'screen';
    case BlendMode.srcATop:
      return 'src_atop';
    case BlendMode.srcIn:
      return 'src_in';
    case BlendMode.srcOver:
      return 'src_over';
    default:
      return null;
  }
}
