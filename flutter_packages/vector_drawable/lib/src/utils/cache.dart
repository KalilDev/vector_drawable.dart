abstract class Cache<K, V> {
  void clear();
  Iterable<K> get keys;
  void remove(K key);
  V putIfAbsent(K key, V Function() ifAbsent);
}

class MapCache<K, V> extends Cache<K, V> {
  final Map<K, V> _map = {};
  void clear() => _map.clear();
  Iterable<K> get keys => _map.keys;
  void remove(K key) => _map.remove(key);
  V putIfAbsent(K key, V Function() ifAbsent) =>
      _map.putIfAbsent(key, ifAbsent);
}

class _SingleIterator<V> extends Iterator<V> {
  final V _value;
  bool _didEmit = false;

  _SingleIterator(this._value);
  @override
  V get current => _value;

  @override
  bool moveNext() {
    final move = _didEmit;
    _didEmit = true;
    return !move;
  }
}

class _SingleIterable<V> extends Iterable<V> {
  final V _v;

  _SingleIterable(this._v);
  @override
  Iterator<V> get iterator => _SingleIterator(_v);
}

class SingleCache<K, V> extends Cache<K, V> {
  K? _key;
  V? _value;
  @override
  void clear() => _key = _value = null;

  @override
  Iterable<K> get keys =>
      _key == null ? Iterable<K>.empty() : _SingleIterable<K>(_key!);

  @override
  V putIfAbsent(K key, V Function() ifAbsent) {
    if (_key == key) {
      return _value!;
    }
    _key = key;
    return _value = ifAbsent();
  }

  @override
  void remove(K key) => _key == key ? clear() : null;
}
