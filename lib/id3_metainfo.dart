class ID3MetataInfo {
  final Map<String, dynamic> _metadata = {};

  final List _containers = [];

  MetadataRange range = MetadataRange();

  bool get _hasContainer => _containers.isNotEmpty;

  void setRangeStart(int start) {
    if (start < 0) return;
    range._start = start;
  }

  void setRangeLength(int length) {
    if (length < 0) return;
    range._length = length;
  }

  getContainer() {
    if (_hasContainer) {
      return _containers.last;
    } else {
      return null;
    }
  }

  void set({required dynamic value, required String key, String? desc}) {
    final lastContainer = getContainer();
    if (lastContainer != null) {
      if (lastContainer is List) {
        List list = lastContainer;
        list.add({key: _ID3MetadataValue(value: value, desc: desc)});
      } else if (lastContainer is Map) {
        Map map = lastContainer;
        map[key] = _ID3MetadataValue(value: value, desc: desc);
      } else {
        assert(false, "Unknown container: $lastContainer.");
      }
    } else {
      _metadata[key] = _ID3MetadataValue(value: value, desc: desc);
    }
  }

  void enterMapContainer(String name) {
    assert(!_metadata.containsKey(name),
        'The same boundary key[$name] already exists.');
    final lastContainer = getContainer();
    if (lastContainer != null) {
      if (lastContainer is List) {
        List container = lastContainer;
        Map map = {};
        container.add(map);
        _containers.add(map);
      } else if (lastContainer is Map) {
        Map container = lastContainer;
        Map map = {};
        container[name] = map;
        _containers.add(map);
      }
    } else {
      _metadata[name] = {};
      _containers.add(_metadata[name]);
    }
  }

  void enterListContainer(String name) {
    assert(!_metadata.containsKey(name),
        'The same boundary key[$name] already exists.');
    final lastContainer = getContainer();
    if (lastContainer != null) {
      if (lastContainer is List) {
        List container = lastContainer;
        List list = [];
        container.add(list);
        _containers.add(list);
      } else if (lastContainer is Map) {
        Map container = lastContainer;
        List list = [];
        container[name] = list;
        _containers.add(list);
      }
    } else {
      _metadata[name] = [];
      _containers.add(_metadata[name]);
    }
  }

  void leaveContainer() {
    if (_hasContainer) {
      _containers.removeLast();
    }
  }

  Map<String, dynamic> toTagMap() {
    return _metadata;
  }

  @override
  String toString() {
    String ret = '[ ID3MetaInfo ]\n';
    ret += "- Range: $range\n";
    String tranferValue(dynamic value, String key) {
      String ret = '';
      if (value is _ID3MetadataValue) {
        ret += "- $key: ${value.toString()}\n";
      } else {
        if (value is Map) {
          for (var element in value.entries) {
            final key = element.key;
            final value = element.value;  
            ret += tranferValue(value, key);
          }
        } else if (value is List) {
          for (var element in value) {
            ret += tranferValue(element, key);
          }
        } else {
          ret += "- $key: $value\n";
        }
      }
      return ret;
    }

    for (var element in _metadata.entries) {
      final key = element.key;
      final value = element.value;
      ret += "== $key ==\n";
      ret += tranferValue(value, key);
    }
    ret += "=========> All data received <=======\n";
    return ret;
  }
}

class _ID3MetadataValue {
  _ID3MetadataValue({required this.value, this.desc});

  final dynamic value;
  final String? desc;

  @override
  String toString() {
    return desc != null ? "$value[$desc]" : "$value";
  }
}

class MetadataRange {
  MetadataRange();
  int _start = 0;
  int _length = 0;

  int get start => _start;
  int get length => _length;

  @override
  String toString() {
    return "{$_start, ${_start+_length}}";
  }
}