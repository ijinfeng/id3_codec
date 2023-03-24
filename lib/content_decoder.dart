import 'dart:convert';

import 'package:id3_codec/byte_codec.dart';
import 'package:id3_codec/id3_constant.dart';

// https://id3.org/d3v2.3.0
// https://id3.org/id3v2-00
class ContentDecoder {
  ContentDecoder({
    required this.frameID,
    required this.bytes,
  }) {
    if (frameID == 'TXXX' || frameID == 'TXX') {
      _decoder = _TXXXDecoder(frameID);
    } else if (frameID.startsWith('T')) {
      _decoder = _TextInfomationDecoder(frameID);
    } else if (frameID == 'WXXX' || frameID == 'WXX') {
      _decoder = _WXXXDecoder(frameID);
    } else if (frameID.startsWith('W')) {
      _decoder = _URLLinkDecoder(frameID);
    } else if (frameID == 'IPLS' || frameID == 'IPL') {
      _decoder = _IPLSDecoder(frameID);
    } else if (frameID == 'COMM' || frameID == 'COM') {
      _decoder = _COMMDecoder(frameID);
    } else if (frameID == 'APIC') {
      _decoder = _APICDecoder(frameID);
    } else if (frameID == 'PIC') {
      _decoder = _PICDecoder(frameID);
    } else if (frameID == 'USLT' || frameID == 'ULT') {
      _decoder = _USLTDecoder(frameID);
    } else if (frameID == 'SYLT' || frameID == 'SLT') {
      _decoder = _SYLTDecoder(frameID);
    } else if (frameID == 'GEOB' || frameID == 'GEO') {
      _decoder = _GEOBDecoder(frameID);
    } else {
      _decoder = _UnsupportedDecoder(frameID);
    }
  }

  late final _ContentDecoder _decoder;

  final List<int> bytes;
  final String frameID;

  FrameContent decode() {
    final value = _decoder.decode(bytes);
    return value;
  }
}

class FrameContent {
  final Map<String, dynamic> _contentMap = {};

  Map<String, dynamic> get content => _contentMap;

  void set(String key, dynamic value) {
    _contentMap[key] = value;
  }

  @override
  String toString() {
    return content.toString();
  }
}

abstract class _ContentDecoder {
  final String frameID;
  _ContentDecoder(this.frameID);

  FrameContent decode(List<int> bytes);
}

/*
  <Header for 'Text information frame', ID: "T000" - "TZZZ",
     excluding "TXXX" described in 4.2.2.>
  Text encoding                $xx
  Information                  <text string according to encoding>
*/
class _TextInfomationDecoder extends _ContentDecoder {
  _TextInfomationDecoder(super.frameID);

  @override
  FrameContent decode(List<int> bytes) {
    final encoding = bytes.sublist(0, 1).first;
    final codec = ByteCodec(textEncodingByte: encoding);
    return FrameContent()..set('Information', codec.decode(bytes.sublist(1)));
  }
}

/*
  <Header for 'User defined text information frame', ID: "TXXX">
     Text encoding     $xx
     Description       <text string according to encoding> $00 (00)
     Value             <text string according to encoding>
*/
class _TXXXDecoder extends _ContentDecoder {
  _TXXXDecoder(super.frameID);

  @override
  FrameContent decode(List<int> bytes) {
    final content = FrameContent();
    int start = 0;

    final encoding = bytes.sublist(0, 1).first;
    final codec = ByteCodec(textEncodingByte: encoding);
    start += 1;

    // Description
    final descBytes = codec.readBytesUtilTerminator(bytes.sublist(start));
    content.set('Description', codec.decode(descBytes.bytes));
    start += descBytes.length;

    // Value
    final value = codec.decode(bytes.sublist(start));
    content.set('Value', value);
    return content;
  }
}

/*
  <Header for 'User defined URL link frame', ID: "WXXX">
     Text encoding     $xx
     Description       <text string according to encoding> $00 (00)
     URL               <text string>
*/
class _WXXXDecoder extends _ContentDecoder {
  _WXXXDecoder(super.frameID);

  @override
  FrameContent decode(List<int> bytes) {
    final content = FrameContent();
    int start = 0;

    final encoding = bytes.sublist(0, 1).first;
    final codec = ByteCodec(textEncodingByte: encoding);
    start += 1;

    // Description
    final descBytes = codec.readBytesUtilTerminator(bytes.sublist(start));
    content.set('Description', codec.decode(descBytes.bytes));
    start += descBytes.length;

    // URL
    final value = codec.decode(bytes.sublist(start));
    content.set('Value', value);
    return content;
  }
}

/*
  <Header for 'URL link frame', ID: "W000" - "WZZZ", excluding "WXXX"
     described in 4.3.2.>
     URL              <text string>
*/
class _URLLinkDecoder extends _ContentDecoder {
  _URLLinkDecoder(super.frameID);

  @override
  FrameContent decode(List<int> bytes) {
    return FrameContent()..set('URL', ByteCodec().decode(bytes));
  }
}

/*
  <Header for 'Involved people list', ID: "IPLS">
     Text encoding          $xx
     People list strings    <text strings according to encoding>
*/
class _IPLSDecoder extends _ContentDecoder {
  _IPLSDecoder(super.frameID);

  @override
  FrameContent decode(List<int> bytes) {
    final content = FrameContent();
    int start = 0;

    final encoding = bytes.sublist(0, 1).first;
    final codec = ByteCodec(textEncodingByte: encoding);
    start += 1;

    // People list strings
    content.set('People list strings', codec.decode(bytes.sublist(start)));

    return content;
  }
}

/*
  <Header for 'Comment', ID: "COMM">
     Text encoding          $xx
     Language               $xx xx xx
     Short content descrip. <text string according to encoding> $00 (00)
     The actual text        <full text string according to encoding>
*/
class _COMMDecoder extends _ContentDecoder {
  _COMMDecoder(super.frameID);

  @override
  FrameContent decode(List<int> bytes) {
    final content = FrameContent();
    int start = 0;
    // Text encoding
    final encoding = bytes.sublist(0, 1).first;
    final codec = ByteCodec(textEncodingByte: encoding);
    start += 1;

    // Language
    final langBytes = bytes.sublist(start, start + 3);
    start += 3;
    content.set('Language', codec.decode(langBytes));

    // Short content descrip
    final shortContentBytes =
        codec.readBytesUtilTerminator(bytes.sublist(start));
    start += shortContentBytes.length;
    content.set('Short content descrip', codec.decode(shortContentBytes.bytes));

    // The actual text
    content.set('The actual text', codec.decode(bytes.sublist(start)));
    return content;
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
class _APICDecoder extends _ContentDecoder {
  _APICDecoder(super.frameID);

  @override
  FrameContent decode(List<int> bytes) {
    final content = FrameContent();
    int start = 0;
    // Text encoding
    final encoding = bytes.sublist(0, 1).first;
    final codec = ByteCodec(textEncodingByte: encoding);
    start += 1;

    // MIME type
    final mimeBytes =
        codec.readBytesUtilTerminator(bytes.sublist(start), terminator: [0x00]);
    start += mimeBytes.length;
    content.set('MIME',
        codec.decode(mimeBytes.bytes, forceType: ByteCodecType.ISO_8859_1));

    // Picture type
    final pictype = bytes.sublist(start, start + 1).first;
    start += 1;
    content.set('PictureType', kPictureType[pictype]);

    // Description
    final descBytes = codec.readBytesUtilTerminator(bytes.sublist(start));
    start += descBytes.length;
    content.set('Description', codec.decode(descBytes.bytes));

    // Picture data
    content.set(
        'Base64',
        base64.encode(bytes.sublist(start)).isNotEmpty
            ? '<Has Picture Data>'
            : '<Empty>');

    return content;
  }
}

/*
  <Header for 'Attached picture', ID: "PIC">
     Text encoding      $xx
     Image format       $xx xx xx
     Picture type       $xx
     Description        <text string according to encoding> $00 (00)
     Picture data       <binary data>
*/
class _PICDecoder extends _ContentDecoder {
  _PICDecoder(super.frameID);

  @override
  FrameContent decode(List<int> bytes) {
    final content = FrameContent();
    int start = 0;
    // Text encoding
    final encoding = bytes.sublist(0, 1).first;
    final codec = ByteCodec(textEncodingByte: encoding);
    start += 1;

    // Image format
    final mimeBytes = bytes.sublist(start, start + 3);
    start += 3;
    content.set('Image format',
        codec.decode(mimeBytes, forceType: ByteCodecType.ISO_8859_1));

    // Picture type
    final pictype = bytes.sublist(start, start + 1).first;
    start += 1;
    content.set('PictureType', kPictureType[pictype]);

    // Description
    final descBytes = codec.readBytesUtilTerminator(bytes.sublist(start));
    start += descBytes.length;
    content.set('Description', codec.decode(descBytes.bytes));

    // Picture data
    content.set(
        'Base64',
        base64.encode(bytes.sublist(start)).isNotEmpty
            ? '<Has Picture Data>'
            : '<Empty>');

    return content;
  }
}

/*
  <Header for 'Unsynchronised lyrics/text transcription', ID: "USLT">
     Text encoding        $xx
     Language             $xx xx xx
     Content descriptor   <text string according to encoding> $00 (00)
     Lyrics/text          <full text string according to encoding>
*/
class _USLTDecoder extends _ContentDecoder {
  _USLTDecoder(super.frameID);

  @override
  FrameContent decode(List<int> bytes) {
    final content = FrameContent();
    int start = 0;
    // Text encoding
    final encoding = bytes.sublist(0, 1).first;
    final codec = ByteCodec(textEncodingByte: encoding);
    start += 1;

    // Language
    final langBytes = bytes.sublist(start, start + 3);
    start += 3;
    content.set('Language',
        codec.decode(langBytes, forceType: ByteCodecType.ISO_8859_1));

    // Content descriptor
    final contentDescBytes =
        codec.readBytesUtilTerminator(bytes.sublist(start));
    content.set('Content descriptor', codec.decode(contentDescBytes.bytes));
    start += contentDescBytes.length;

    // Lyrics/text
    content.set('Lyrics/text', codec.decode(bytes.sublist(start)));

    return content;
  }
}

/*
  <Header for 'Synchronised lyrics/text', ID: "SYLT">
     Text encoding        $xx
     Language             $xx xx xx
     Time stamp format    $xx
     Content type         $xx
     Content descriptor   <text string according to encoding> $00 (00)
*/
class _SYLTDecoder extends _ContentDecoder {
  _SYLTDecoder(super.frameID);

  @override
  FrameContent decode(List<int> bytes) {
    final content = FrameContent();
    int start = 0;
    // Text encoding
    final encoding = bytes.sublist(0, 1).first;
    final codec = ByteCodec(textEncodingByte: encoding);
    start += 1;

    // Language
    final langBytes = bytes.sublist(start, start + 3);
    start += 3;
    content.set('Language',
        codec.decode(langBytes, forceType: ByteCodecType.ISO_8859_1));

    // Time stamp format
    final tsfByte = bytes.sublist(start, start + 1).first;
    start += 1;
    content.set('Time stamp format', tsfByte);

    // Content type
    final contentTypeByte = bytes.sublist(start, start + 1).first;
    start += 1;
    content.set('Content type', contentType[contentTypeByte]);

    // Content descriptor
    final contentDescBytes =
        codec.readBytesUtilTerminator(bytes.sublist(start));
    content.set('Content descriptor', codec.decode(contentDescBytes.bytes));
    start += contentDescBytes.length;

    return content;
  }

  List<String> get contentType => [
        'other',
        'lyrics',
        'text transcription',
        'movement/part name (e.g. "Adagio")',
        'events (e.g. "Don Quijote enters the stage")',
        'chord (e.g. "Bb F Fsus")',
        "trivia/'pop up' information"
      ];
}

/*
  <Header for 'General encapsulated object', ID: "GEOB">
     Text encoding          $xx
     MIME type              <text string> $00
     Filename               <text string according to encoding> $00 (00)
     Content description    <text string according to enc�ding> $00 (00)
     Encapsulated object    <binary data>
*/
class _GEOBDecoder extends _ContentDecoder {
  _GEOBDecoder(super.frameID);

  @override
  FrameContent decode(List<int> bytes) {
    final content = FrameContent();
    int start = 0;

    // Text encoding
    final encoding = bytes.sublist(0, 1).first;
    final codec = ByteCodec(textEncodingByte: encoding);
    start += 1;

    // MIME type
    final mimeBytes =
        codec.readBytesUtilTerminator(bytes.sublist(start), terminator: [0x00]);
    start += mimeBytes.length;
    content.set('MIME type',
        codec.decode(mimeBytes.bytes, forceType: ByteCodecType.ISO_8859_1));

    // Filename
    final fileBytes = codec.readBytesUtilTerminator(bytes.sublist(start));
    start += fileBytes.length;
    content.set('Filename', codec.decode(fileBytes.bytes));

    // Content description
    final descBytes = codec.readBytesUtilTerminator(bytes.sublist(start));
    start += descBytes.length;
    content.set('Content description', codec.decode(descBytes.bytes));

    // Encapsulated object
    content.set(
        'Encapsulated object',
        bytes.sublist(start).isNotEmpty
            ? '<Has Encapsulated Data>'
            : '<Empty>');
    return content;
  }
}

class _UnsupportedDecoder extends _ContentDecoder {
  _UnsupportedDecoder(super.frameID);

  @override
  FrameContent decode(List<int> bytes) {
    return FrameContent()..set('', "<Unsupported FrameID: $frameID>");
  }
}
