import 'package:id3_codec/byte_codec.dart';

class ID3Encoder {
  const ID3Encoder(List<int> bytes) : _bytes = bytes;

  final List<int> _bytes;

  List<int> encode(EncodeMetadata data) {
    if (data is MetadataV1Body) {
      final encoder = _ID3V1Encoder(_bytes);
      return encoder.encode(data);
    } else {
      // TODO:implementation
    }
    return _bytes;
  }
}

abstract class _ID3Encoder {
  const _ID3Encoder(this.bytes);
  final List<int> bytes;
}

class _ID3V1Encoder extends _ID3Encoder {
  const _ID3V1Encoder(super.bytes);

  List<int> encode(MetadataV1Body data) {
    int start = bytes.length - 128;

    final codec = ByteCodec();
    List<int> output = List.from(bytes);

    // exist ID3v1 tags
    if (start >= 0 && codec.decode(output.sublist(start, start + 3)) == 'TAG') {
      start += 3;
    } else {
      start = bytes.length;
      final append = List.filled(128, 0x00);
      output.addAll(append);
      final idBytes = codec.encode('TAG', limitByteLength: 3);
      output.replaceRange(start, start + 3, idBytes);
      start += 3;
    }

    // Title
    if (data.title != null) {
      List<int> titleBytes = codec.encode(data.title!, limitByteLength: 30);
      output.replaceRange(start, start + 30, titleBytes);
    }
    start += 30;

    // Artist
    if (data.artist != null) {
      List<int> artistBytes = codec.encode(data.artist!, limitByteLength: 30);
      output.replaceRange(start, start + 30, artistBytes);
    }
    start += 30;

    // Album
    if (data.album != null) {
      List<int> albumBytes = codec.encode(data.album!, limitByteLength: 30);
      output.replaceRange(start, start + 30, albumBytes);
    }
    start += 30;

    // Year
    if (data.year != null) {
      List<int> yearBytes = codec.encode(data.year!, limitByteLength: 4);
      output.replaceRange(start, start + 4, yearBytes);
    }
    start += 4;

    // Track
    if (data.track != null) {
      assert(data.track! <= 255 && data.track! >= 0);

      if (data.comment != null) {
        List<int> commentBytes =
            codec.encode(data.comment!, limitByteLength: 28);
        output.replaceRange(start, start + 28, commentBytes);
      }
      start += 28;

      // Reverse
      output.replaceRange(start, start + 1, [0x01]);
      start += 1;

      List<int> trackBytes = [data.track!];
      output.replaceRange(start, start + 1, trackBytes);
      start += 1;
    } else {
      // Comment
      if (data.comment != null) {
        List<int> commentBytes =
            codec.encode(data.comment!, limitByteLength: 30);
        output.replaceRange(start, start + 30, commentBytes);
      }
      start += 30;
    }

    // Genre
    if (data.genre != null) {
      assert(data.genre! <= 125 && data.genre! >= 0);
      List<int> genreBytes = [data.genre!];
      output.replaceRange(start, start + 1, genreBytes);
    }
    start += 1;
    return output;
  }
}

abstract class EncodeMetadata {
  const EncodeMetadata();
}

class MetadataV1Body extends EncodeMetadata {
  const MetadataV1Body(
      {this.title,
      this.artist,
      this.album,
      this.year,
      this.comment,
      this.track,
      this.genre});

  final String? title;
  final String? artist;
  final String? album;
  // '2', '0', '2', '2'
  final String? year;
  final String? comment;
  final int? genre;
  final int? track;
}
