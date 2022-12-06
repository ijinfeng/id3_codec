import 'package:flutter/material.dart';
import 'package:id3_codec/byte_codec.dart';
import 'package:id3_codec/byte_util.dart';
import 'package:id3_codec/encode_metadata.dart';
import 'package:id3_codec/image_type.dart';

// https://id3.org/d3v2.3.0
class ContentEncoder {
  const ContentEncoder({this.body});

  final MetadataEditableWrapper? body;

  /// encode `MetadataV2Body` to bytes
  List<int> encode() {
    assert(body != null, 'Error: the body cant be empty.');    
    if (body is MetadataV2_3Wrapper) {
      return _encodeMetadataV2_3(body as MetadataV2_3Wrapper);
    } else if (body is MetadataV2_4Wrapper) {
      return _encodeMetadataV2_4(body as MetadataV2_4Wrapper);
    }
    return [];
  }

  List<int> _encodeMetadataV2_3(MetadataV2_3Wrapper wrapper) {
    List<int> output = [];
    if (wrapper.title.value != null) {
        output
            .addAll(encodeProperty(frameID: 'TIT2', property: wrapper.title, fillHeader: true, sizeH0: false));
      }
      if (wrapper.artist.value != null) {
        output
            .addAll(encodeProperty(frameID: 'TPE1', property: wrapper.artist, fillHeader: true, sizeH0: false));
      }
      if (wrapper.album.value != null) {
        output
            .addAll(encodeProperty(frameID: 'TALB', property: wrapper.album, fillHeader: true, sizeH0: false));
      }
      if (wrapper.encoding.value != null) {
        output.addAll(
            encodeProperty(frameID: 'TSSE', property: wrapper.encoding, fillHeader: true, sizeH0: false));
      }
      if (wrapper.userDefines.value != null) {
        for (final entry in wrapper.userDefines.value!) {
          output.addAll(encodeProperty(frameID: 'TXXX', property: entry, fillHeader: true, sizeH0: false));
        }
      }
      if (wrapper.imageBytes.value != null &&
          ImageCodec.getImageMimeType(wrapper.imageBytes.value!).isNotEmpty) {
        output.addAll(
            encodeProperty(frameID: 'APIC', property: wrapper.imageBytes, fillHeader: true, sizeH0: false));
      }
      return output;
  }

  List<int> _encodeMetadataV2_4(MetadataV2_4Wrapper wrapper) {
    List<int> output = [];
    if (wrapper.title.value != null) {
        output
            .addAll(encodeProperty(frameID: 'TIT2', property: wrapper.title, fillHeader: true, sizeH0: true));
      }
      if (wrapper.artist.value != null) {
        output
            .addAll(encodeProperty(frameID: 'TPE1', property: wrapper.artist, fillHeader: true, sizeH0: true));
      }
      if (wrapper.album.value != null) {
        output
            .addAll(encodeProperty(frameID: 'TALB', property: wrapper.album, fillHeader: true, sizeH0: true));
      }
      if (wrapper.encoding.value != null) {
        output.addAll(
            encodeProperty(frameID: 'TSSE', property: wrapper.encoding, fillHeader: true, sizeH0: true));
      }
      if (wrapper.userDefines.value != null) {
        for (final entry in wrapper.userDefines.value!) {
          output.addAll(encodeProperty(frameID: 'TXXX', property: entry, fillHeader: true, sizeH0: true));
        }
      }
      if (wrapper.imageBytes.value != null &&
          ImageCodec.getImageMimeType(wrapper.imageBytes.value!).isNotEmpty) {
        output.addAll(
            encodeProperty(frameID: 'APIC', property: wrapper.imageBytes, fillHeader: true, sizeH0: true));
      }
      return output;
  }

  /// Encode the content corresponding to frameID. If you set `fillHeader: true`, the result is all frame [frame Header + content] bytes.
  /// - frameID: frame identifier
  /// - property: encode content, read from EncodeMetadataV2Body's properties
  /// - fillHeader: whether or not insert frame header in start of the output
  /// - tagRestrictions: use in v2.4, limit tag size, encoding, etc.
  /// - sizeH0: It only takes effect when fillHeader is true, indicating whether the high bit of the byte is 0, used to set the calculation method of size
  ///
  /// Unless you know what you're encoding the property, don't actively call it
  List<int> encodeProperty(
      {required String frameID,
      required MetadataProperty property,
      TagRestrictions? tagRestrictions,
      bool fillHeader = false,
      bool sizeH0 = true}) {
    if (property.value == null || property.attached) return [];
    _ContentEncoder? encoder;
    if (frameID == 'TXXX') {
      encoder = _TXXXEncoder(frameID);
    } else if (frameID.startsWith('T')) {
      encoder = _TextInfomationEncoder(frameID);
    } else if (frameID == 'APIC') {
      encoder = _APICEncoder(frameID);
    }
    if (encoder != null) {
      property.attached = true;
      final contentBytes = encoder.encode(property.value, tagRestrictions);
      if (fillHeader) {
        List<int> output = [];
        // wrap frame header(10 bytes)
        final codec = ByteCodec();
        output.addAll(codec.encode(frameID, limitByteLength: 4));
        if (sizeH0) {
          output.addAll(ByteUtil.toH0Bytes(contentBytes.length));
        } else {
          output.addAll(ByteUtil.toH1Bytes(contentBytes.length));
        }
        output.addAll([0x00, 0x00]);
        return output + contentBytes;
      } else {
        return contentBytes;
      }
    }
    return [];
  }
}

abstract class _ContentEncoder {
  const _ContentEncoder(this.frameID);

  final String frameID;

  List<int> encode(dynamic content, TagRestrictions? tagRestrictions);
}

/*
  <Header for 'Text information frame', ID: "T000" - "TZZZ",
     excluding "TXXX" described in 4.2.2.>
     Text encoding                $xx
     Information                  <text string according to encoding>
*/
class _TextInfomationEncoder extends _ContentEncoder {
  _TextInfomationEncoder(super.frameID);

  @override
  List<int> encode(content, TagRestrictions? tagRestrictions) {
    List<int> output = [];

    // set text encoding 'UTF16'
    final defaultTextEncoding = (tagRestrictions != null && tagRestrictions.textEncodingR == 0x01) ? 0x03 : 0x01;
    final codec = ByteCodec(textEncodingByte: defaultTextEncoding);

    // text encoding
    output.add(defaultTextEncoding);

    // information
    if (tagRestrictions != null 
    && tagRestrictions.textFieldsSizeR != 0x00
    && content.length > tagRestrictions.textFieldsSize) {
      debugPrint("Encode error: Tag restrictions for textFieldsSize is ${tagRestrictions.textFieldsSize}, but the length of 'content' in [_TextInfomationEncoder] is ${content.length}");
      return [];
    } 
    final infoBytes = codec.encode(content);
    output.addAll(infoBytes);

    return output;
  }
}

/*
  <Header for 'User defined text information frame', ID: "TXXX">
     Text encoding     $xx
     Description       <text string according to encoding> $00 (00)
     Value             <text string according to encoding>
*/
class _TXXXEncoder extends _ContentEncoder {
  _TXXXEncoder(super.frameID);

  @override
  List<int> encode(content, TagRestrictions? tagRestrictions) {
    if (content is MapEntry == false) return [];
    List<int> output = [];

    // set text encoding 'UTF16'
    final defaultTextEncoding = (tagRestrictions != null && tagRestrictions.textEncodingR == 0x01) ? 0x03 : 0x01;
    final codec = ByteCodec(textEncodingByte: defaultTextEncoding);

    // text encoding
    output.add(defaultTextEncoding);

    // Description
    if (tagRestrictions != null 
    && tagRestrictions.textFieldsSizeR != 0x00
    && content.key.length > tagRestrictions.textFieldsSize) {
      debugPrint("Encode error: Tag restrictions for textFieldsSize is ${tagRestrictions.textFieldsSize}, but the length of 'content.key' in [_TXXXEncoder] is ${content.key.length}");
      return [];
    } 
    final decBytes = codec.encode(content.key);
    output.addAll(decBytes);
    output.addAll([0x00, 0x00]);

    // Value
    if (tagRestrictions != null 
    && tagRestrictions.textFieldsSizeR != 0x00
    && content.value.length > tagRestrictions.textFieldsSize) {
      debugPrint("Encode error: Tag restrictions for textFieldsSize is ${tagRestrictions.textFieldsSize}, but the length of 'content.value' in [_TXXXEncoder] is ${content.value.length}");
      return [];
    }
    final valueBytes = codec.encode(content.value);
    output.addAll(valueBytes);

    return output;
  }
}

/*
       <Header for 'Attached picture', ID: "APIC">
     Text encoding      $xx
     MIME type          <text string> $00
     Picture type       $xx
     Description        <text string according to encoding> $00 (00)
     Picture data       <binary data>
*/
class _APICEncoder extends _ContentEncoder {
  _APICEncoder(super.frameID);

  @override
  List<int> encode(content, TagRestrictions? tagRestrictions) {
    List<int> output = [];

    // set text encoding 'ISO_8859_1'
    final defaultTextEncoding = (tagRestrictions != null && tagRestrictions.textEncodingR == 0x01) ? 0x03 : 0x00;

    // text encoding
    output.add(defaultTextEncoding);

    // MIME type
    String mimeType = ImageCodec.getImageMimeType(content);
    if (tagRestrictions != null 
    && tagRestrictions.imageEncodingR != 0 
    && (mimeType != 'image/png' && mimeType != 'image/jpeg')) {
      debugPrint("Encode error: Tag restrictions for 'image encoding' is png or jpeg, but the mimetype of image is $mimeType}");
      return [];
    }
    final mimeBytes =
        iso_8859_1_codec.encode(mimeType);
    output.addAll(mimeBytes);
    output.add(0x00);

    // Picture type, default set to 'Other'
    final pictypeBytes = 0x00;
    output.add(pictypeBytes);

    // Description
    output.addAll([0x00]);

    // Picture data 
    // TODO:Image size restrictions
    output.addAll(content);

    return output;
  }
}
