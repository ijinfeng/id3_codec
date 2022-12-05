class ByteUtil {
  /// Given 4 bytes, the high bit of each byte is 0, calculate its size
  /// - bytes: bytes which length is 4
  /// 
  /// ```dart
  /// final size = (bytes[3] & 0x7F) +
  ///      ((bytes[2] & 0x7F) << 7) +
  ///      ((bytes[1] & 0x7F) << 14) +
  ///      ((bytes[0] & 0x7F) << 21);
  /// ```
  static int calH0Size(List<int> bytes) {
    assert(bytes.length == 4);
    final size = (bytes[3] & 0x7F) +
        ((bytes[2] & 0x7F) << 7) +
        ((bytes[1] & 0x7F) << 14) +
        ((bytes[0] & 0x7F) << 21);
    return size;
  }

  /// Given 4 bytes, the high bit of each byte is 1, calculate its size
  /// - bytes: bytes which length is 4
  /// 
  /// ```dart
  /// int size = bytes[3] + (bytes[2] << 8) + (bytes[1] << 16) + (bytes[0] << 24);
  /// ```
  static int calH1Size(List<int> bytes) {
    assert(bytes.length == 4);
    int size = bytes[3] + (bytes[2] << 8) + (bytes[1] << 16) + (bytes[0] << 24);
    return size;
  }

  /// Convert the given size to 4 bytes, the high bit of each byte is 0
  /// 
  /// ```dart
  ///  sizeBytes[0] = ((size << 4) >>> 25) & 0x7F;
  ///  sizeBytes[1] = ((size << 11) >>> 25) & 0x7F;
  ///  sizeBytes[2] = ((size << 18) >>> 25) & 0x7F;
  ///  sizeBytes[3] = ((size << 25) >>> 25) & 0x7F;
  /// ```
  static List<int> toH0Bytes(int size) {
    List<int> sizeBytes = List.filled(4, 0x00);
    sizeBytes[0] = ((size << 4) >>> 25) & 0x7F;
    sizeBytes[1] = ((size << 11) >>> 25) & 0x7F;
    sizeBytes[2] = ((size << 18) >>> 25) & 0x7F;
    sizeBytes[3] = ((size << 25) >>> 25) & 0x7F;
    return sizeBytes;
  }

  /// Convert the given size to 4 bytes, the high bit of each byte is 1
  /// 
  /// ```dart
  ///  sizeBytes[0] = (size >>> 24) & 0xFF;
  ///  sizeBytes[1] = ((size << 8) >>> 24) & 0xFF;
  ///  sizeBytes[2] = ((size << 16) >>> 24) & 0xFF;
  ///  sizeBytes[3] = ((size << 24) >>> 24) & 0xFF;
  /// ```
  static List<int> toH1Bytes(int size) {
    List<int> sizeBytes = List.filled(4, 0x00);
    sizeBytes[0] = (size >>> 24) & 0xFF;
    sizeBytes[1] = ((size << 8) >>> 24) & 0xFF;
    sizeBytes[2] = ((size << 16) >>> 24) & 0xFF;
    sizeBytes[3] = ((size << 24) >>> 24) & 0xFF;
    return sizeBytes;
  }

  /// Remove a series of 0x00 in the header
  static List<int> trimStart(List<int> bytes) {
    if (bytes.isEmpty) return [];
    int i = 0;
    while (bytes[i] == 0x00) {
      i++;
      if (i >= bytes.length) {
        return [];
      }
    }
    return bytes.sublist(i, bytes.length);
  }

  /// Remove a series of 0x00 in the footer
  static List<int> trimEnd(List<int> bytes) {
    if (bytes.isEmpty) return [];
    int i = bytes.length - 1;
    while (bytes[i] == 0x00) {
      i--;
      if (i < 0) {
        return [];
      }
    }
    return bytes.sublist(0, i + 1);
  }

  /// Remove a series of 0x00 in the header and footer
  /// 
  /// ```dart
  /// final List<int> bytes = [0x00, 0x00, 0xFE, 0x00]
  /// final resultBytes = ByteUtil.trim(bytes);
  /// // resultBytes is [0xFE]
  /// ```
  static List<int> trim(List<int> bytes) {
    final ret = trimEnd(trimStart(bytes));
    return ret;
  }
}
