import '../../model/vector_drawable.dart';

extension VectorAttributeE on Vector {
  Object? getThemeableAttribute(String name) {
    switch (name) {
      case 'alpha':
        return opacity;
    }
  }
}

extension PathAttributeE on Path {
  Object? getThemeableAttribute(String name) {
    switch (name) {
      case 'pathData':
        return pathData;
      case 'fillColor':
        return fillColor;
      case 'strokeColor':
        return strokeColor;
      case 'strokeWidth':
        return strokeWidth;
      case 'strokeAlpha':
        return strokeAlpha;
      case 'fillAlpha':
        return fillAlpha;
      case 'trimPathStart':
        return trimPathStart;
      case 'trimPathEnd':
        return trimPathEnd;
      case 'trimPathOffset':
        return trimPathOffset;
    }
  }
}

extension ClipPathAttributeE on ClipPath {
  Object? getThemeableAttribute(String name) {
    switch (name) {
      case 'pathData':
        return pathData;
    }
  }
}

extension GroupAttributeE on Group {
  Object? getThemeableAttribute(String name) {
    switch (name) {
      case 'rotation':
        return rotation;
      case 'pivotX':
        return pivotX;
      case 'pivotY':
        return pivotY;
      case 'scaleX':
        return scaleX;
      case 'scaleY':
        return scaleY;
      case 'translateX':
        return translateX;
      case 'translateY':
        return translateY;
    }
  }
}

extension VectorDrawableNodeE on VectorDrawableNode {
  Object? getThemeableAttribute(String name) {
    if (this is Group) {
      return (this as Group).getThemeableAttribute(name);
    } else if (this is Path) {
      return (this as Path).getThemeableAttribute(name);
    } else if (this is Vector) {
      return (this as Vector).getThemeableAttribute(name);
    } else if (this is ClipPath) {
      return (this as ClipPath).getThemeableAttribute(name);
    }
  }
}
