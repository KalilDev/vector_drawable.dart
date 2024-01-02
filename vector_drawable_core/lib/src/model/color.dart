abstract class RGBA {
  static const int _rShift = 24;
  static const int _gShift = 16;
  static const int _bShift = 8;
  static const int _aShift = 0;
}

class VectorColor {
  static const int _maxComponent = 0xFF;
  static const int _componentMask = 0xFF;
  static const int _aShift = 24;
  static const int _rShift = 16;
  static const int _gShift = 8;
  static const int _bShift = 0;
  static const int _colorMask = 0xFFFFFFFF;
  final int argb;
  const VectorColor.rgba(int rgba)
      : argb = (((rgba >> RGBA._rShift & _componentMask) << _rShift) |
                ((rgba >> RGBA._gShift & _componentMask) << _gShift) |
                ((rgba >> RGBA._bShift & _componentMask) << _bShift) |
                ((rgba >> RGBA._aShift & _componentMask) << _aShift)) &
            _colorMask;
  const VectorColor.argb(this.argb);
  const factory VectorColor(int argb) = VectorColor.argb;
  const VectorColor.components(int r, int g, int b, [int a = 0])
      : assert(r <= _maxComponent),
        assert(g <= _maxComponent),
        assert(b <= _maxComponent),
        assert(a <= _maxComponent),
        argb = ((a << _aShift) |
                (r << _rShift) |
                (g << _gShift) |
                (b << _bShift)) &
            _colorMask;
  static const transparent = VectorColor.rgba(0);
  int get alpha => (argb >> _aShift) & _componentMask;
  int get red => (argb >> _rShift) & _componentMask;
  int get green => (argb >> _gShift) & _componentMask;
  int get blue => (argb >> _bShift) & _componentMask;
  double get opacity => alpha / _maxComponent;
}
