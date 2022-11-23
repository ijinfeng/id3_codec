// ignore_for_file: constant_identifier_names

import 'dart:convert';

enum ByteCodecType {
  // Other
  Unknown,
  // Can't encode/decode [中文]
  ISO_8859_1,
  UTF16,
  UTF16BE,
  UTF16LE,
  UTF8
}

class ByteCodec {
  ByteCodec({int textEncodingByte = 0x00}) {
    if (textEncodingByte == 0x00) {
      _codecType = ByteCodecType.ISO_8859_1;
    } else if (textEncodingByte == 0x01) {
      _codecType = ByteCodecType.UTF16;
    } else if (textEncodingByte == 0x02) {
      _codecType = ByteCodecType.UTF16BE;
    } else if (textEncodingByte == 0x03) {
      _codecType = ByteCodecType.UTF8;
    } else {
      _codecType = ByteCodecType.Unknown;
    }
  }

  late ByteCodecType _codecType;

  ByteCodecType get codecType => _codecType;

  String decode(List<int> bytes, {ByteCodecType? forceType}) {
    final decodeType = forceType ?? codecType;
    if (decodeType == ByteCodecType.ISO_8859_1) {
      return latin1.decode(bytes, allowInvalid: true);
    } else if (decodeType == ByteCodecType.UTF16) {
      return _decodeWithUTF16(bytes);
    } else if (decodeType == ByteCodecType.UTF16BE) {
      return _decodeWithUTF16BE(bytes);
    } else if (decodeType == ByteCodecType.UTF8) {
      return utf8.decode(bytes, allowMalformed: true);
    } else {
      return '';
    }
  }

  // https://zh.wikipedia.org/wiki/UTF-16
  String _decodeWithUTF16(List<int> bytes) {
    final bom = bytes.sublist(0, 2);
    if (bom[0] == 0xFF && bom[1] == 0xFE) {
      return _decodeWithUTF16LE(bytes.sublist(2));
    } else if (bom[0] == 0xFE && bom[1] == 0xFF) {
      return _decodeWithUTF16BE(bytes.sublist(2));
    }
    return '';
  }

  // BE 即 big-endian，大端的意思。大端就是将高位的字节放在低地址表示
  String _decodeWithUTF16BE(List<int> bytes) {
    _codecType = ByteCodecType.UTF16BE;
    
    final utf16bes = List.generate((bytes.length / 2).ceil(), (index) => 0);

    for (int i = 0; i < bytes.length; i++) {
      if (i % 2 == 0) {
        utf16bes[i ~/ 2] = (bytes[i] << 8);
      } else {
        utf16bes[i ~/ 2] |= bytes[i];
      }
    }
    return String.fromCharCodes(utf16bes);
  }

  // LE 即 little-endian，小端的意思。小端就是将高位的字节放在高地址表示
  String _decodeWithUTF16LE(List<int> bytes) {
    _codecType = ByteCodecType.UTF16LE;

    final utf16les = List.generate((bytes.length / 2).ceil(), (index) => 0);

    for (int i = 0; i < bytes.length; i++) {
      if (i % 2 == 0) {
        utf16les[i ~/ 2] = bytes[i];
      } else {
        utf16les[i ~/ 2] |= (bytes[i] << 8);
      }
    }
    return String.fromCharCodes(utf16les);
  }

  List<int> _encodeWithUTF16(String string) {
    return [];
  }

  List<int> _encodeWithUTF16BE(String string) {
    return [];
  }

  List<int> _encodeWithUTF16LE(String string) {
    return [];
  }

  SubBytes readBytesUtilTerminator(List<int> bytes, {List<int>? terminator}) {
    if (bytes.isEmpty) return SubBytes.o(bytes);
    // ignore: no_leading_underscores_for_local_identifiers
    List<int> _terminator;
    if (terminator == null || terminator.isEmpty == true) {
      if (codecType == ByteCodecType.UTF16 ||
      codecType == ByteCodecType.UTF16BE ||
      codecType == ByteCodecType.UTF16LE) {
        _terminator = [0x00, 0x00];
      } else {
        _terminator = [0x00];
      }
    } else {
      _terminator = terminator;
    }
    if (_terminator.isEmpty || _terminator.length > bytes.length) return SubBytes.o(bytes);
    int findTerminatorIndex = 0;
    for (int i = 0; i < bytes.length; i = i + _terminator.length) {
      final sub = bytes.sublist(i, i + _terminator.length);
      bool match = true;
      for (var j = 0; j < sub.length; j++) {
        if (sub[j] != _terminator[j]) {
          match = false;
          break;
        }
      }
      if (match) {
        findTerminatorIndex = i + _terminator.length;
        break;
      }
    }
    final subBytes = findTerminatorIndex > 0 ? bytes.sublist(0, findTerminatorIndex - _terminator.length) : bytes;
    if (findTerminatorIndex > 0) {
      return SubBytes(bytes: subBytes, terminator: _terminator);
    } else {
      return SubBytes.o(bytes);
    }
  }

  List<int> encode(String string, {int? limitByteLength, ByteCodecType? forceType}) {
    final decodeType = forceType ?? codecType;
    if (decodeType == ByteCodecType.ISO_8859_1) {
      return transferToLength(latin1.encode(string), byteLength: limitByteLength);
    } else if (decodeType == ByteCodecType.UTF16) {
      return _encodeWithUTF16(string);
    } else if (decodeType == ByteCodecType.UTF16BE) {

    } else if (decodeType == ByteCodecType.UTF8) {
      return transferToLength(utf8.encode(string), byteLength: limitByteLength);
    } else {
      return [];
    }
    return [];
  }

  /// Convert bytes to bytes of specified length
  /// - bytes
  /// - byteLength[Optional]
  List<int> transferToLength(List<int> bytes, {int? byteLength}) {
    if (byteLength == null) return bytes;
    final List<int> ret = List.from(bytes);
    if (bytes.length <= byteLength) {
      ret.addAll(List.filled(byteLength - bytes.length, 0x00));
      return ret;
    } else {
      ret.removeRange(byteLength, bytes.length);
      return ret;
    }
  }
}

class SubBytes {
  SubBytes({
    required this.bytes,
    required this.terminator
  });

  SubBytes.o(this.bytes) : terminator = [];

  final List<int> bytes;
  final List<int> terminator;

  int get length => bytes.length + terminator.length;
}