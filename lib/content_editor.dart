import 'dart:io';

import 'package:id3_codec/content_encoder.dart';
import 'package:id3_codec/id3_encoder.dart';

class ContentEditor {
  const ContentEditor({required this.bytes});

  final List<int> bytes;

  EditorResult editFrameWithData(
      {required int start,
       required String frameID, 
       required int frameSize, 
       bool compression = false,
       required EncodeMetadataV2Body data}) {
    if (data is MetadataV2_3Body) {
      return _editFrameWithV2_3Data(start, frameID, frameSize, compression, data);
    }
    return EditorResult.noEdit(frameID: frameID, start: start, frameSize: frameSize);
  }

  EditorResult _editFrameWithV2_3Data(
      int start, String frameID, int frameSize, bool compression, MetadataV2_3Body data) {
    if (frameID == 'TIT2' && data.title != null) {
      return _editFrameWithProperty(start, frameID, frameSize, compression, data.title);
    } else if (frameID == 'TXXX' && data.userDefines != null) {
      return _editFrameWithProperty(start, frameID, frameSize, compression, data.userDefines);
    } else if (frameID == 'TPE1' && data.artist != null) {
      return _editFrameWithProperty(start, frameID, frameSize, compression, data.artist);
    } else if (frameID == 'TALB' && data.album != null) {
      return _editFrameWithProperty(start, frameID, frameSize, compression, data.album);
    } else if (frameID == 'TSSE' && data.encoding != null) {
      return _editFrameWithProperty(start, frameID, frameSize, compression, data.encoding);
    } else if (frameID == 'APIC' && data.imageBytes != null) {
      return _editFrameWithProperty(start, frameID, frameSize, compression, data.imageBytes);
    }
    return EditorResult.noEdit(frameID: frameID, start: start, frameSize: frameSize);
  }

  EditorResult _editFrameWithProperty(int start, String frameID, int frameSize, bool compression, dynamic content) {
    final contentEncoder = ContentEncoder();
    List<int> contentBytes =
        contentEncoder.encodeProperty(frameID: frameID, content: content);
    if (compression) {
      // store 'decompressed size' in 4 bytes
      List<int> decompressedSizeBytes = List.filled(4, 0x00);
      final contentSize = contentBytes.length;
      decompressedSizeBytes[0] = (contentSize >>> 24);
      decompressedSizeBytes[1] = (contentSize << 8) >>> 24;
      decompressedSizeBytes[2] = (contentSize << 16) >>> 24;
      decompressedSizeBytes[3] = (contentSize << 24) >>> 24;
      contentBytes = decompressedSizeBytes + zlib.encode(contentBytes);
    }
    // adjust the size of frame content
    if (contentBytes.length <= frameSize) {
      // shrink size
      int shrinkStart = start + contentBytes.length;
      final shrinkSize = frameSize - contentBytes.length;
      bytes.removeRange(shrinkStart, shrinkSize);
    } else {
      // expansion
      final expansionSize = contentBytes.length - frameSize;
      int expansionStart = start + frameSize;
      bytes.insertAll(expansionStart, List.filled(expansionSize, 0x00));
    }
    bytes.replaceRange(start, start + contentBytes.length, contentBytes);

    // recalculate content size
    List<int> sizeBytes = List.filled(4, 0x00);
    frameSize = contentBytes.length;
    sizeBytes[0] = (frameSize << 4) >>> 25;
    sizeBytes[1] = (frameSize << 11) >>> 25;
    sizeBytes[2] = (frameSize << 18) >>> 25;
    sizeBytes[3] = (frameSize << 25) >>> 25;
    // 6 = size(4 bytes) + flags(2 bytes)
    int frameSizeStart = start - 6;
    bytes.replaceRange(frameSizeStart, frameSizeStart + 4, sizeBytes);

    start += frameSize;

    return EditorResult(frameID: frameID, start: start, modify: true, frameSize: frameSize);
  }
}

class EditorResult {
  const EditorResult({
    required this.frameID,
    required this.start,
    required this.modify,
    required this.frameSize
  });

  const EditorResult.noEdit({
    required this.frameID,
    required this.start,
    required this.frameSize
  }) : modify = false;

  final String frameID;
  final int start;
  final bool modify;
  final int frameSize;
}
