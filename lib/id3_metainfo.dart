import 'package:id3_codec/content_decoder.dart';

class ID3MetataInfo {
  final Map<String, dynamic> _metadata = {};
  final Map<String, dynamic> _tagMap = {};

  final List _containers = [];
  final List _tagMapContainers = [];

  MetadataRange range = MetadataRange();

  /// Obtain id3 tag information in the form of a dictionary.
  Map<String, dynamic> toTagMap() {
    return _tagMap;
  }

  bool get _hasContainer => _containers.isNotEmpty;

  void setRangeStart(int start) {
    if (start < 0) return;
    range._start = start;
  }

  void setRangeLength(int length) {
    if (length < 0) return;
    range._length = length;
  }

  _getContainer() {
    if (_hasContainer) {
      return _containers.last;
    } else {
      return null;
    }
  }

  _getTagMapContainer() {
    if (_hasContainer) {
      return _tagMapContainers.last;
    } else {
      return null;
    }
  } 

  _unwrapperValue(dynamic value) {
    if (value is FrameContent) {
      return value.content;
    } else if (value is _ID3MetadataValue) {
      return value.value;
    } else {
      return value;
    }
  }

  void set({required dynamic value, required String key, String? desc}) {
    final lastContainer = _getContainer();
    if (lastContainer != null) {
      if (lastContainer is List) {
        List list = lastContainer;
        list.add({key: _ID3MetadataValue(value: value, desc: desc)});
        List tagList = _getTagMapContainer();
        tagList.add({key: _unwrapperValue(value)});
      } else if (lastContainer is Map) {
        Map map = lastContainer;
        map[key] = _ID3MetadataValue(value: value, desc: desc);
        Map tagMap = _getTagMapContainer();
        tagMap[key] = _unwrapperValue(value);
      } else {
        assert(false, "Unknown container: $lastContainer.");
      }
    } else {
      _metadata[key] = _ID3MetadataValue(value: value, desc: desc);
      _tagMap[key] = _unwrapperValue(value);
    }
  }

  void enterMapContainer(String name) {
    assert(!_metadata.containsKey(name),
        'The same boundary key[$name] already exists.');
    final lastContainer = _getContainer();
    if (lastContainer != null) {
      if (lastContainer is List) {
        List container = lastContainer;
        Map map = {};
        container.add(map);
        _containers.add(map);

        List tagContainer = _getTagMapContainer();
        Map tagMap = {};
        tagContainer.add(tagMap);
        _tagMapContainers.add(tagMap);
      } else if (lastContainer is Map) {
        Map container = lastContainer;
        Map map = {};
        container[name] = map;
        _containers.add(map);

        Map tagContainer = _getTagMapContainer();
        Map tagMap = {};
        tagContainer[name] = tagMap;
        _tagMapContainers.add(tagMap);
      }
    } else {
      _metadata[name] = {};
      _containers.add(_metadata[name]);

      _tagMap[name] = {};
      _tagMapContainers.add(_tagMap[name]);
    }
  }

  void enterListContainer(String name) {
    assert(!_metadata.containsKey(name),
        'The same boundary key[$name] already exists.');
    final lastContainer = _getContainer();
    if (lastContainer != null) {
      if (lastContainer is List) {
        List container = lastContainer;
        List list = [];
        container.add(list);
        _containers.add(list);

        List tagContainer = _getTagMapContainer();
        List tagList = [];
        tagContainer.add(tagList);
        _tagMapContainers.add(tagList);
      } else if (lastContainer is Map) {
        Map container = lastContainer;
        List list = [];
        container[name] = list;
        _containers.add(list);

        Map tagContainer = _getTagMapContainer();
        List tagList = [];
        tagContainer[name] = tagList;
        _tagMapContainers.add(tagList);
      }
    } else {
      _metadata[name] = [];
      _containers.add(_metadata[name]);

      _tagMap[name] = [];
      _tagMapContainers.add(_tagMap[name]);
    }
  }

  void leaveContainer() {
    if (_hasContainer) {
      _containers.removeLast();
      _tagMapContainers.removeLast();
    }
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
    ret += "=========> All data received <=======";
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