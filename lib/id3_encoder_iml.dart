import 'package:id3_codec/byte_codec.dart';
import 'package:id3_codec/content_encoder.dart';
import 'package:id3_codec/id3_encoder.dart';

abstract class _ID3Encoder {
  const _ID3Encoder(this.bytes);
  final List<int> bytes;
}

class ID3V1Encoder extends _ID3Encoder {
  const ID3V1Encoder(super.bytes);

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


class ID3V2_3Encoder extends _ID3Encoder {
  ID3V2_3Encoder(super.bytes);

  /// Record the starting position of size calculation,
  /// and calculate the total size after all frames are filled
  int _calSizeStart = 0;

  List<int> encode(MetadataV2_3Body data) {
    int start = 0;
    final codec = ByteCodec();
    List<int> output = List.from(bytes);

    final idBytes = output.sublist(start, start + 3);
    if (codec.decode(idBytes) == 'ID3') {

    } else {
      List<int> insetBytes = [];
      // Create Header
      final header = List.filled(10, 0x00);
      final id3TagBytes = codec.encode('ID3', limitByteLength: 3);
      header.replaceRange(start, start + 3, id3TagBytes);
      start += 3;

      // version + revision
      header.replaceRange(start, start + 1, [3]);
      start += 2;

      // Flags
      final flagsByte = 0x00;
      header.replaceRange(start, start + 1, [flagsByte]);
      start += 1;

      // Size
      // The ID3v2 tag size is the size of the complete tag after
      // unsychronisation, including padding, excluding the header but not
      // excluding the extended header (total tag size - 10)
      // 
      // `size = extended header + frames + padding`
      _calSizeStart = start;
      start += 4;

      // No Extended Header

      // Frames
      final contentEncoder = ContentEncoder(body: data);
      final framesBytes = contentEncoder.encode();

      // Padding
      final padding = List.filled(100, 0x00);

      // Calculate the size of size and store it in 4 bytes
      final size = framesBytes.length + padding.length;
      List<int> sizeBytes = List.filled(4, 0x00);
      sizeBytes[0] = (size << 4) >>> 25;
      sizeBytes[1] = (size << 11) >>> 25;
      sizeBytes[2] = (size << 18) >>> 25;
      sizeBytes[3] = (size << 25) >>> 25;
      header.replaceRange(_calSizeStart, _calSizeStart + 4, sizeBytes);

      // package  all bytes
      insetBytes.addAll(
        header
      );
      insetBytes.addAll(
        framesBytes
      );
      insetBytes.addAll(padding);

      output.insertAll(0, insetBytes);
    }
    return output;
  } 
}
