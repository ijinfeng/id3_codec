import 'dart:io';

import 'package:id3_codec/byte_util.dart';
import 'package:id3_codec/content_encoder.dart';
import 'package:id3_codec/encode_metadata.dart';
import 'package:id3_codec/image_type.dart';

class ContentEditor {
  const ContentEditor({required this.bytes});

  final List<int> bytes;

  EditorResult editFrameWithData(
      {required int start,
      required String frameID,
      required int frameSize,
      bool compression = false,
      required MetadataEditableWrapper data}) {
    if (data is MetadataV2_3Wrapper) {
      return _editFrameWithV2_3Data(
          start, frameID, frameSize, compression, data);
    } else if (data is MetadataV2_4Wrapper) {
      return _editFrameWithV2_4Data(
          start, frameID, frameSize, compression, data);
    }
    return EditorResult.noEdit(
        frameID: frameID, start: start, frameSize: frameSize);
  }

  EditorResult _editFrameWithV2_3Data(int start, String frameID, int frameSize,
      bool compression, MetadataV2_3Wrapper data) {
    if (frameID == 'TIT2' && data.title.value != null) {
      return _editFrameWithProperty(
          start, frameID, frameSize, compression, data.title);
    } else if (frameID == 'TXXX' && data.userDefines.value != null) {
      return _editFrameWithProperty(
          start, frameID, frameSize, compression, data.userDefines);
    } else if (frameID == 'TPE1' && data.artist.value != null) {
      return _editFrameWithProperty(
          start, frameID, frameSize, compression, data.artist);
    } else if (frameID == 'TALB' && data.album.value != null) {
      return _editFrameWithProperty(
          start, frameID, frameSize, compression, data.album);
    } else if (frameID == 'TSSE' && data.encoding.value != null) {
      return _editFrameWithProperty(
          start, frameID, frameSize, compression, data.encoding);
    } else if (frameID == 'APIC' &&
        data.imageBytes.value != null &&
        ImageCodec.getImageMimeType(data.imageBytes.value!).isNotEmpty) {
      return _editFrameWithProperty(
          start, frameID, frameSize, compression, data.imageBytes);
    }
    return EditorResult.noEdit(
        frameID: frameID, start: start, frameSize: frameSize);
  }

  EditorResult _editFrameWithV2_4Data(int start, String frameID, int frameSize,
      bool compression, MetadataV2_4Wrapper data) {
    if (frameID == 'TIT2' && data.title.value != null) {
      return _editFrameWithProperty(
          start, frameID, frameSize, compression, data.title, tagRestrictions: data.tagRestrictions);
    } else if (frameID == 'TXXX' && data.userDefines.value != null) {
      return _editFrameWithProperty(
          start, frameID, frameSize, compression, data.userDefines, tagRestrictions: data.tagRestrictions);
    } else if (frameID == 'TPE1' && data.artist.value != null) {
      return _editFrameWithProperty(
          start, frameID, frameSize, compression, data.artist, tagRestrictions: data.tagRestrictions);
    } else if (frameID == 'TALB' && data.album.value != null) {
      return _editFrameWithProperty(
          start, frameID, frameSize, compression, data.album, tagRestrictions: data.tagRestrictions);
    } else if (frameID == 'TSSE' && data.encoding.value != null) {
      return _editFrameWithProperty(
          start, frameID, frameSize, compression, data.encoding, tagRestrictions: data.tagRestrictions);
    } else if (frameID == 'APIC' &&
        data.imageBytes.value != null &&
        ImageCodec.getImageMimeType(data.imageBytes.value!).isNotEmpty) {
      return _editFrameWithProperty(
          start, frameID, frameSize, compression, data.imageBytes, tagRestrictions: data.tagRestrictions);
    }
    return EditorResult.noEdit(
        frameID: frameID, start: start, frameSize: frameSize);
  }

  EditorResult _editFrameWithProperty(int start, String frameID, int frameSize,
      bool compression, MetadataProperty property, {TagRestrictions? tagRestrictions}) {
    final contentEncoder = ContentEncoder();
    List<int> contentBytes =
        contentEncoder.encodeProperty(frameID: frameID, property: property, fillHeader: false, tagRestrictions: tagRestrictions);
    if (contentBytes.isEmpty) {
      return EditorResult.noEdit(frameID: frameID, start: start, frameSize: frameSize);
    }
    if (compression) {
      // store 'decompressed size' in 4 bytes
      final contentSize = contentBytes.length;
      List<int> decompressedSizeBytes = ByteUtil.toH1Bytes(contentSize);
      contentBytes = decompressedSizeBytes + zlib.encode(contentBytes);
    }
    final int contentLength = contentBytes.length;
    // adjust the size of frame content
    if (contentLength <= frameSize) {
      // shrink size
      int shrinkStart = start + contentLength;
      final shrinkSize = frameSize - contentLength;
      bytes.removeRange(shrinkStart, shrinkStart + shrinkSize);
    } else {
      // expansion
      final expansionSize = contentLength - frameSize;
      int expansionStart = start + frameSize;
      bytes.insertAll(expansionStart, List.filled(expansionSize, 0x00));
    }
    bytes.replaceRange(start, start + contentLength, contentBytes);

    // recalculate content size
    frameSize = contentLength;
    List<int> sizeBytes = ByteUtil.toH1Bytes(frameSize);
    
    // 6 = size(4 bytes) + flags(2 bytes)
    int frameSizeStart = start - 6;
    bytes.replaceRange(frameSizeStart, frameSizeStart + 4, sizeBytes);

    start += frameSize;

    return EditorResult(
        frameID: frameID, start: start, modify: true, frameSize: frameSize);
  }
}

class EditorResult {
  const EditorResult(
      {required this.frameID,
      required this.start,
      required this.modify,
      required this.frameSize});

  const EditorResult.noEdit(
      {required this.frameID, required this.start, required this.frameSize})
      : modify = false;

  final String frameID;
  final int start;
  final bool modify;
  final int frameSize;
}
