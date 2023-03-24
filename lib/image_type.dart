class ImageCodec {
  /// Decode the first 2 bytes of the picture stream
  /// - JPEG: 0xFF 0xD8
  /// - PNG: 0x89 0x50
  /// - GIF: 0x47 0x49
  /// - BMP: 0x42 0x4D
  /// - TIFF: 0x4D 0x4D or 0x49 0x49
  static String getImageMimeType(List<int> bytes) {
    final typeBytes = bytes.sublist(0, 2);
    bool equal(List<int> a, List<int> b) {
      if (a.length != b.length) return false;
      for (int i = 0; i < a.length; i++) {
        if (a[i] != b[i]) {
          return false;
        }
      }
      return true;
    }

    if (equal(typeBytes, [0xFF, 0xD8])) {
      return "image/jpeg";
    } else if (equal(typeBytes, [0x89, 0x50])) {
      return "image/png";
    } else if (equal(typeBytes, [0x47, 0x49])) {
      return "image/gif";
    } else if (equal(typeBytes, [0x42, 0x4D])) {
      return "image/bmp";
    } else if (equal(typeBytes, [0x4D, 0x4D]) ||
        equal(typeBytes, [0x49, 0x49])) {
      return "image/tiff";
    } else {
      return "";
    }
  }
}
