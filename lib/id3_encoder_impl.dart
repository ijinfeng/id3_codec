import 'dart:convert';
import 'dart:io';

import 'package:id3_codec/byte_codec.dart';
import 'package:id3_codec/content_editor.dart';
import 'package:id3_codec/content_encoder.dart';
import 'package:id3_codec/id3_encoder.dart';

abstract class _ID3Encoder {
  const _ID3Encoder(this.bytes);
  final List<int> bytes;

  List<int> get _defaultPadding => List.filled(100, 0x00);
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
  ID3V2_3Encoder(super.bytes) : _output = List.from(bytes);

  final List<int> _output;

  /// Record the starting position of size calculation,
  /// and calculate the total size after all frames are filled
  int _calSizeStart = 0;

  /// The ID3v2 tag size, excluding the header
  int _size = 0;

  /// The whole extended header size
  int _extendedSize = 0;

  List<int> encode(MetadataV2_3Body data) {
    int start = 0;
    final idBytes = _output.sublist(start, start + 3);
    if (latin1.decode(idBytes) == 'ID3') {
      start += 3;
      _decodeDeep(start, data);
    } else {
      final insetBytes = _createNewID3Body(data);
      _output.insertAll(0, insetBytes);
    }
    return _output;
  }

  void _decodeDeep(int start, MetadataV2_3Body data) {
    // version
    final major = _output.sublist(start, start + 1).first;
    start += 2;

    // flags - %abc00000
    final flags = _output.sublist(start, start + 1).first;
    start += 1;
    // We only need to pay attention to whether there is an Extended Header
    final hasExtendedHeader = (flags & 0x40) != 0;

    // size - 4 * %0xxxxxxx
    List<int> sizeBytes = _output.sublist(start, start + 4);
    _calSizeStart = start;
    start += 4;

    // The ID3v2 tag size is the size of the complete tag after
    // unsychronisation, including padding, excluding the header but not
    // excluding the extended header (total tag size - 10).
    final size = (sizeBytes[3] & 0x7F) +
        ((sizeBytes[2] & 0x7F) << 7) +
        ((sizeBytes[1] & 0x7F) << 14) +
        ((sizeBytes[0] & 0x7F) << 21);
    _size = size;

    // If it is not v2.3 version, tag data will be erased
    if (major != 3) {
      // Frames
      final contentEncoder = ContentEncoder(body: data);
      final framesBytes = contentEncoder.encode();
      if (framesBytes.length <= size) {
        final filledLength = size - framesBytes.length;
        final insertBytes = framesBytes + List.filled(filledLength, 0x00);
        _output.replaceRange(start, start + insertBytes.length, insertBytes);
      } else {
        // The `size` was become larger
        final insertBytes = framesBytes + _defaultPadding;
        final moveLength = insertBytes.length - size;
        _output.insertAll(start + size, List.filled(moveLength, 0x00));
        _output.replaceRange(start, start + insertBytes.length, insertBytes);

        // new size
        _size = insertBytes.length;

        List<int> sizeBytes = List.filled(4, 0x00);
        sizeBytes[0] = (_size << 4) >>> 25;
        sizeBytes[1] = (_size << 11) >>> 25;
        sizeBytes[2] = (_size << 18) >>> 25;
        sizeBytes[3] = (_size << 25) >>> 25;
        _output.replaceRange(_calSizeStart, _calSizeStart + 4, sizeBytes);
      }
    } else {
      // Extended Header
      if (hasExtendedHeader) {
        final extSizeBytes = _output.sublist(start, start + 4);
        start += 4;
        final extSize = extSizeBytes[3] +
            (extSizeBytes[2] << 8) +
            (extSizeBytes[1] << 16) +
            (extSizeBytes[0] << 24);
        start += extSize;
        _extendedSize = extSize + 4;
      }

      // Frames
      _decodeFrames(start, data);
    }
  }

  void _decodeFrames(int start, MetadataV2_3Body data) {
    // remaining size = frames + padding
    int remainingSize = _size - _extendedSize;
    final editor = ContentEditor(bytes: _output);

    while (remainingSize > 0) {
      final frameID = latin1.decode(_output.sublist(start, start + 4));
      if (frameID == latin1.decode([0, 0, 0, 0])) {
        break;
      }
      start += 4;

      // frame size
      final frameSizeBytes = _output.sublist(start, start + 4);
      start += 4;
      int frameSize = frameSizeBytes[3] +
          (frameSizeBytes[2] << 8) +
          (frameSizeBytes[1] << 16) +
          (frameSizeBytes[0] << 24);

      // Flags - %abc00000 %ijk00000
      final flags = _output.sublist(start, start + 2);
      start += 2;

      // c - Read only
      bool readOnly = (flags[0] & 0x20) != 0;

      // i - Compression
      bool compression = (flags[1] & 0x80) != 0;

      if (!readOnly) {
        final editResult = editor.editFrameWithData(
            start: start,
            frameID: frameID,
            frameSize: frameSize,
            compression: compression,
            data: data);
        // Can't edit this frame
        if (editResult.modify) {
          start = editResult.start;
          frameSize = editResult.frameSize;
        } else {
          start += frameSize;
        }
      } else {
        start += frameSize;
      }

      remainingSize -= frameSize;
    }
  }

  List<int> _createNewID3Body(MetadataV2_3Body data) {
    int start = 0;
    final codec = ByteCodec();

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
    final padding = _defaultPadding;

    // Calculate the size of `size` and store it in 4 bytes
    final size = framesBytes.length + padding.length;
    List<int> sizeBytes = List.filled(4, 0x00);
    sizeBytes[0] = (size << 4) >>> 25;
    sizeBytes[1] = (size << 11) >>> 25;
    sizeBytes[2] = (size << 18) >>> 25;
    sizeBytes[3] = (size << 25) >>> 25;
    header.replaceRange(_calSizeStart, _calSizeStart + 4, sizeBytes);

    // package  all bytes
    insetBytes.addAll(header);
    insetBytes.addAll(framesBytes);
    insetBytes.addAll(padding);
    return insetBytes;
  }
}
