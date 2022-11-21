// ignore_for_file: constant_identifier_names

import 'dart:convert';

enum ByteCodecType {
  // Other
  Unknown,
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
      return latin1.decode(bytes);
    } else if (decodeType == ByteCodecType.UTF16) {
      return _decodeToUTF16(bytes);
    } else if (decodeType == ByteCodecType.UTF16BE) {
      return _decodeToUTF16BE(bytes);
    } else if (decodeType == ByteCodecType.UTF8) {
      return utf8.decode(bytes);
    } else {
      return '';
    }
  }

  // https://zh.wikipedia.org/wiki/UTF-16
  String _decodeToUTF16(List<int> bytes) {
    final bom = bytes.sublist(0, 2);
    if (bom[0] == 0xFF && bom[1] == 0xFE) {
      return _decodeToUTF16LE(bytes.sublist(2));
    } else if (bom[0] == 0xFE && bom[1] == 0xFF) {
      return _decodeToUTF16BE(bytes.sublist(2));
    }
    return '';
  }

  // BE 即 big-endian，大端的意思。大端就是将高位的字节放在低地址表示
  String _decodeToUTF16BE(List<int> bytes) {
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
  String _decodeToUTF16LE(List<int> bytes) {
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