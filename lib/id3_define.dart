import 'dart:convert';
import 'package:id3_codec/byte_codec.dart';
import 'package:id3_codec/content_decoder.dart';
import 'package:id3_codec/id3_constant.dart';
import 'package:id3_codec/id3_metainfo.dart';

/// Support ID3V1, V1.1, V2.2, V2.3, V2.4
abstract class ID3Define {
  String get version;
  List<int> bytes;

  ID3Define(this.bytes);

  bool convert();

  bool showDetail = false;

  final ID3MetataInfo metadata = ID3MetataInfo();

  int get totalLength;

  dynamic readValue(ID3Fragment fragment, int start, {List<int>? bytes}) {
    final sub = (bytes ?? this.bytes).sublist(start, fragment.length + start);
    if (fragment.needDecode) {
      return latin1.decode(sub).trim();
    } else if (fragment.length == 1) {
      return sub.first;
    }
    return sub;
  }
}

class ID3V1 extends ID3Define {
  ID3V1(super.bytes);

  @override
  String get version => "V1";

  /// total 128 bytes
  List<ID3Fragment> get fragments => [
        ID3Fragment(name: 'Header', length: 3),
        ID3Fragment(name: 'Title', length: 30),
        ID3Fragment(name: 'Artist', length: 30),
        ID3Fragment(name: 'Album', length: 30),
        ID3Fragment(name: 'Year', length: 4),
        ID3Fragment(name: 'Comment', length: 30),
        ID3Fragment(name: 'Genre', length: 1, needDecode: false),
      ];

  @override
  bool convert() {
    int start = bytes.length - ID3V1.inherentTotalLength;
    if (start < 0 || readValue(fragments[0], start) != 'TAG') {
      return false;
    }
    // Range
    metadata.setRangeStart(start);
    metadata.setRangeLength(totalLength);

    final codec = ByteCodec();

    metadata.set(value: version, key: "Version");
    start += fragments[0].length;

    // Title
    final titleBytes = bytes.sublist(start, start + 30);
    metadata.set(value: codec.decode(titleBytes), key: 'Title');
    start += 30;

    // Artist
    final artistBytes = bytes.sublist(start, start + 30);
    metadata.set(value: codec.decode(artistBytes), key: 'Artist');
    start += 30;

    // Album
    final albumBytes = bytes.sublist(start, start + 30);
    metadata.set(value: codec.decode(albumBytes), key: 'Album');
    start += 30;

    // Year
    final yearBytes = bytes.sublist(start, start + 4);
    metadata.set(value: codec.decode(yearBytes), key: 'Year');
    start += 4;

    // Comment (30 or 28)
    final hasReserve = bytes.sublist(start + 28, start + 29).first != 0x00;
    if (hasReserve) {
      // ID3V1.1
      metadata.set(value: 'V1.1', key: "Version");

      final commentBytes = bytes.sublist(start, start + 28);
      metadata.set(value: codec.decode(commentBytes), key: 'Comment');
      start += 28;

      // Reserve
      final reserveBytes = bytes.sublist(start, start + 1).first;
      metadata.set(value: reserveBytes, key: 'Reserve');
      start += 1;

      // Track
      final trackBytes = bytes.sublist(start, start + 1).first;
      metadata.set(value: trackBytes, key: 'Track');
      start += 1;
    } else {
      final commentBytes = bytes.sublist(start, start + 30);
      metadata.set(value: codec.decode(commentBytes), key: 'Comment');
      start += 30;
    }

    // Genre
    final genre = bytes.sublist(start, start + 1).first;
    metadata.set(value: genreList[genre], key: 'Genre');
    start += 1;

    return true;
  }

  @override
  int get totalLength => ID3V1.inherentTotalLength;

  static int get inherentTotalLength => 128;
}

/// https://id3.org/id3v2.4.0-structure
/// https://id3.org/d3v2.3.0
/// https://id3.org/id3v2-00
class ID3V2 extends ID3Define {
  ID3V2(super.bytes);

  String _major = 'x';
  String _revision = 'x';

  List<ID3Fragment> get header => [
        ID3Fragment(name: 'FileID', length: 3),
        ID3Fragment(name: 'Major', length: 1, needDecode: false),
        ID3Fragment(name: 'Revision', length: 1, needDecode: false),
        ID3Fragment(name: 'Flags', length: 1, needDecode: false),
        ID3Fragment(name: 'Size', length: 4, needDecode: false),
      ];

  List<ID3Fragment> get extendedV2_3Header => [
        ID3Fragment(name: 'Extended Header Size', length: 4, needDecode: false),
        ID3Fragment(name: 'Extended Flags', length: 2, needDecode: false),
        ID3Fragment(name: 'Size of Padding', length: 4, needDecode: false),
        ID3Fragment(name: 'Total Frame CRC', length: 4, needDecode: false),
      ];

  List<ID3Fragment> get extendedV2_4Header => [
        ID3Fragment(name: 'Extended Header Size', length: 4, needDecode: false),
        ID3Fragment(name: 'Number of flag bytes', length: 1, needDecode: false),
        ID3Fragment(name: 'Extended Flags', length: 1, needDecode: false),
      ];

  List<ID3Fragment> get frameV2_3 => [
        ID3Fragment(name: 'Frame ID', length: 4),
        ID3Fragment(name: 'Frame Size', length: 4, needDecode: false),
        ID3Fragment(name: 'Frame Flags', length: 2, needDecode: false)
        // Content
      ];

  List<ID3Fragment> get frameV2_4 => frameV2_3;

  List<ID3Fragment> get frameV2_2 => [
        ID3Fragment(name: 'Frame ID', length: 3),
        ID3Fragment(name: 'Frame Size', length: 3, needDecode: false)
        // Content
      ];

  /// All field sizes except Header
  int _size = 0;

  /// All frame sizes
  int _totalFrameSize = 0;

  /// The Extended Header Size field holds the Size of the Extended Header, excluding the 4 bytes of the Extended Header Size field itself
  int _extendedSize = 0;

  int _paddingSize = 0;

  bool _hasExtendedHeader = false;

  /// It takes effect only in ID3v2.4, indicates that a footer is present at the very end of the tag
  bool _hasFooter = false;

  @override
  bool convert() {
    /*
      The ID3v2 tag header, which should be the first information in the
   file, is 10 bytes as follows:

     ID3v2/file identifier      "ID3"
     ID3v2 version              $03 00
     ID3v2 flags                %abc00000(or %ab000000 in v2.2)
     ID3v2 size             4 * %0xxxxxxx
    */
    int start = 0;
    if (readValue(header[0], start) != 'ID3') {
      // Search from end of file.
      start = _searchFooterReturnFixStart(bytes.length - 10);
      if (start == 0) {
        return false;
      } else {
        // ID3v2.4
        _hasFooter = true;
      }
    }
    // Range
    metadata.setRangeStart(start);

    start += header[0].length;

    // [ Header ]
    start = _parseHeader(start);

    // [ Extended Header ]
    start = _parseExtendedHeader(start);

    // [ Frames ]
    start = _parseFrames(start);

    // [ Padding(OPTIONAL) ]
    start = _parsePadding(start);

    // [ Footer(Exists only in ID3v2.4) ]
    if (_hasFooter) {
      metadata.set(value: '<Has Footer>', key: 'Footer');
    }

    metadata.setRangeLength(totalLength);

    return true;
  }

  int _parseHeader(int start) {
    metadata.enterMapContainer('Header');
    metadata.set(value: "ID3", key: header[0].name);
    // Parse Version Tag
    _major = readValue(header[1], start).toString();
    start += header[1].length;
    _revision = readValue(header[2], start).toString();
    start += header[2].length;
    metadata.set(value: version, key: "Version");

    // Parse Flags Tag
    final flags = readValue(header[3], start);
    start += header[3].length;
    _hasExtendedHeader = false;
    _hasFooter = false;

    // ID3v2.2  flags  %ab000000
    if (_major == '2') {
      /*
        The first bit (bit 7) in the 'ID3 flags' is indicating whether or not
   unsynchronisation is used (see section 5 for details); a set bit
   indicates usage.
      */
      bool unsynchronisation = (flags & 0x80) != 0;

      /*
        The second bit (bit 6) is indicating whether or not compression is
   used; a set bit indicates usage. Since no compression scheme has been
   decided yet, the ID3 decoder (for now) should just ignore the entire
   tag if the compression bit is set.
      */
      bool compression = (flags & 0x40) != 0;

      if (unsynchronisation) {
        metadata.set(value: unsynchronisation, key: 'Unsynchronisation');
      }
      if (compression) {
        metadata.set(value: compression, key: 'Compression');
      }
    }
    // ID3v2.3  flags  %abc00000
    else if (_major == '3') {
      /*
    a - Unsynchronisation

     Bit 7 in the 'ID3v2 flags' indicates whether or not
     unsynchronisation is used (see section 5 for details); a set bit
     indicates usage.
    */
      bool unsynchronisation = (flags & 0x80) != 0;
      /*
    b - Extended header

     The second bit (bit 6) indicates whether or not the header is
     followed by an extended header. The extended header is described in
     section 3.2.
    */
      _hasExtendedHeader = (flags & 0x40) != 0;
      /*
    c - Experimental indicator

     The third bit (bit 5) should be used as an 'experimental
     indicator'. This flag should always be set when the tag is in an
     experimental stage.
    */
      bool experimentalIndicator = (flags & 0x20) != 0;
      if (unsynchronisation) {
        metadata.set(
            value: unsynchronisation,
            key: header[3].name,
            desc: 'Unsynchronisation');
      }
      if (_hasExtendedHeader) {
        metadata.set(
            value: _hasExtendedHeader,
            key: header[3].name,
            desc: 'Extended header');
      }
      if (experimentalIndicator) {
        metadata.set(
            value: experimentalIndicator,
            key: header[3].name,
            desc: 'Experimental indicator');
      }
    }
    // ID3v2.4  flags  %abcd0000
    else if (_major == '4') {
      bool unsynchronisation = (flags & 0x80) != 0;
      _hasExtendedHeader = (flags & 0x40) != 0;
      bool experimentalIndicator = (flags & 0x20) != 0;
      /*
        d - Footer present

     Bit 4 indicates that a footer (section 3.4) is present at the very
     end of the tag. A set bit indicates the presence of a footer.
      */
      _hasFooter = (flags & 0x10) != 0;
      if (unsynchronisation) {
        metadata.set(
            value: unsynchronisation,
            key: header[3].name,
            desc: 'Unsynchronisation');
      }
      if (_hasExtendedHeader) {
        metadata.set(
            value: _hasExtendedHeader,
            key: header[3].name,
            desc: 'Extended header');
      }
      if (experimentalIndicator) {
        metadata.set(
            value: experimentalIndicator,
            key: header[3].name,
            desc: 'Experimental indicator');
      }
      if (_hasFooter) {
        metadata.set(
            value: _hasFooter, key: header[3].name, desc: 'Footer present');
      }
    }

    // Parse Size Tag
    List<int> sizeBytes = readValue(header[4], start);
    start += header[4].length;
    /*
      The ID3v2 tag size is encoded with four bytes where the most
    significant bit (bit 7) is set to zero in every byte, making a total
    of 28 bits. The zeroed bits are ignored, so a 257 bytes long tag is
    represented as $00 00 02 01.

    [ID3v2.4]The ID3v2 tag size is the sum of the byte length of the extended
   header, the padding and the frames after unsynchronisation. If a
   footer is present this equals to ('total size' - 20) bytes, otherwise
   ('total size' - 10) bytes.
    */
    int size = (sizeBytes[3] & 0x7F) +
        ((sizeBytes[2] & 0x7F) << 7) +
        ((sizeBytes[1] & 0x7F) << 14) +
        ((sizeBytes[0] & 0x7F) << 21);
    _size = size;
    metadata.set(value: "$size", key: header[4].name);
    metadata.leaveContainer();
    return start;
  }

  int _parseV2_3ExtendedHeader(int start) {
    // Extended Header Size
    final extendedSizeBytes = readValue(extendedV2_3Header[0], start);
    start += extendedV2_3Header[0].length;
    _extendedSize = extendedSizeBytes[3] +
        (extendedSizeBytes[2] << 8) +
        (extendedSizeBytes[1] << 16) +
        (extendedSizeBytes[0] << 24);
    metadata.set(value: _extendedSize, key: extendedV2_3Header[0].name);

    // Extended Flags
    final extendedFlags = readValue(extendedV2_3Header[1], start);
    start += extendedV2_3Header[1].length;
    bool crc = (extendedFlags.first & 0x80) != 0;
    metadata.set(value: "CRC-32[$crc]", key: extendedV2_3Header[1].name);

    // Size of Padding
    final paddingBytes = readValue(extendedV2_3Header[2], start);
    start += extendedV2_3Header[2].length;
    _paddingSize = paddingBytes[3] +
        (paddingBytes[2] << 8) +
        (paddingBytes[1] << 16) +
        (paddingBytes[0] << 24);
    metadata.set(value: _paddingSize, key: extendedV2_3Header[2].name);

    // Total Frame CRC
    if (crc) {
      final totalFrameCRC = readValue(extendedV2_3Header[3], start);
      start += extendedV2_3Header[3].length;
      metadata.set(
          value: '$totalFrameCRC[Not Support]',
          key: extendedV2_3Header[3].name);
    }
    return start;
  }

  int _parseV2_4ExtendedHeader(int start) {
    // Extended header size   4 * %0xxxxxxx
    // Where the 'Extended header size' is the size of the whole extended
    // header, stored as a 32 bit synchsafe integer.
    final extendedSizeBytes = readValue(extendedV2_4Header[0], start);
    start += extendedV2_4Header[0].length;
    _extendedSize = (extendedSizeBytes[3] & 0x7F) +
        ((extendedSizeBytes[2] & 0x7F) << 7) +
        ((extendedSizeBytes[1] & 0x7F) << 14) +
        ((extendedSizeBytes[0] & 0x7F) << 21);
    metadata.set(value: _extendedSize, key: extendedV2_4Header[0].name);

    // Number of flag bytes       $01
    final numberOfFlagBytes = readValue(extendedV2_4Header[1], start);
    start += extendedV2_4Header[1].length;
    metadata.set(value: numberOfFlagBytes, key: extendedV2_4Header[1].name);

    // Extended Flags             $xx = %0bcd0000
    // There is only one set of extended flags in v2.4
    // Each flag that is set in the extended header has data attached
    // Attach structure:
    // -----------------------------
    // | Flag data length | 1byte  |
    // -----------------------------
    // | Flag content     | xbytes |
    // -----------------------------
    final extendedFlag = readValue(extendedV2_4Header[2], start);
    start += extendedV2_4Header[2].length;

    /*
      b - Tag is an update

      If this flag is set, the present tag is an update of a tag found
     earlier in the present file or stream. If frames defined as unique
     are found in the present tag, they are to override any
     corresponding ones found in the earlier tag. This flag has no
     corresponding data.

         Flag data length      $00
    */
    final b = (extendedFlag & 0x40) != 0;
    if (b) {
      // If this flag is set, Flag data length is one byte, no content.
      start += 1;
      metadata.set(
          value: b,
          key: extendedV2_4Header[2].name,
          desc: 'b - Tag is an update');
    }

    /*
      c - CRC data present

     If this flag is set, a CRC-32 [ISO-3309] data is included in the
     extended header. The CRC is calculated on all the data between the
     header and footer as indicated by the header's tag length field,
     minus the extended header. Note that this includes the padding (if
     there is any), but excludes the footer. The CRC-32 is stored as an
     35 bit synchsafe integer, leaving the upper four bits always
     zeroed.

        Flag data length       $05
        Total frame CRC    5 * %0xxxxxxx
    */
    final c = (extendedFlag & 0x20) != 0;
    if (c) {
      start += 6;
      metadata.set(
          value: c,
          key: extendedV2_4Header[2].name,
          desc: 'c - CRC data present');
    }
    /*
      d - Tag restrictions

      For some applications it might be desired to restrict a tag in more
     ways than imposed by the ID3v2 specification. Note that the
     presence of these restrictions does not affect how the tag is
     decoded, merely how it was restricted before encoding. If this flag
     is set the tag is restricted as follows:

        Flag data length       $01
        Restrictions           %ppqrrstt
    */
    final d = (extendedFlag & 0x10) != 0;
    if (d) {
      metadata.set(
          value: d,
          key: extendedV2_4Header[2].name,
          desc: 'd - Tag restrictions');
      start += 1;

      final flagContent = bytes.sublist(start, 1).first;
      start += 1;
      /*
       p - Tag size restrictions

      00   No more than 128 frames and 1 MB total tag size.
       01   No more than 64 frames and 128 KB total tag size.
       10   No more than 32 frames and 40 KB total tag size.
       11   No more than 32 frames and 4 KB total tag size.
      */
      final p = (flagContent & 0xC0) >>> 6;
      String key = "d - Tag restrictions[pp]";
      if (p == 0) {
        metadata.set(
            value: p,
            key: key,
            desc: 'No more than 128 frames and 1 MB total tag size');
      } else if (p == 1) {
        metadata.set(
            value: p,
            key: key,
            desc: 'No more than 64 frames and 128 KB total tag size');
      } else if (p == 2) {
        metadata.set(
            value: p,
            key: key,
            desc: 'No more than 32 frames and 40 KB total tag size');
      } else {
        metadata.set(
            value: p,
            key: key,
            desc: 'No more than 32 frames and 4 KB total tag size');
      }

      /*
      q - Text encoding restrictions

       0    No restrictions
       1    Strings are only encoded with ISO-8859-1 [ISO-8859-1] or
            UTF-8 [UTF-8].
      */
      final q = (flagContent & 0x20) >> 5;
      key = "d - Tag restrictions[q]";
      if (q == 0) {
        metadata.set(value: q, key: key, desc: 'No restrictions');
      } else {
        metadata.set(
            value: q,
            key: key,
            desc:
                "Strings are only encoded with ISO-8859-1 [ISO-8859-1] or UTF-8 [UTF-8]");
      }

      /*
        r - Text fields size restrictions

       00   No restrictions
       01   No string is longer than 1024 characters.
       10   No string is longer than 128 characters.
       11   No string is longer than 30 characters.
      */
      final r = (flagContent & 0x18) >> 3;
      key = "d - Tag restrictions[rr]";
      if (r == 0) {
        metadata.set(value: r, key: key, desc: 'No restrictions');
      } else if (r == 1) {
        metadata.set(
            value: r,
            key: key,
            desc: 'No string is longer than 1024 characters');
      } else if (r == 2) {
        metadata.set(
            value: r,
            key: key,
            desc: 'No string is longer than 128 characters');
      } else {
        metadata.set(
            value: r, key: key, desc: 'No string is longer than 30 characters');
      }

      /*
      s - Image encoding restrictions

       0   No restrictions
       1   Images are encoded only with PNG [PNG] or JPEG [JFIF].
      */
      final s = (flagContent & 0x4) >> 2;
      key = "d - Tag restrictions[s]";
      if (s == 0) {
        metadata.set(value: s, key: key, desc: 'No restrictions');
      } else {
        metadata.set(
            value: s,
            key: key,
            desc: 'Images are encoded only with PNG [PNG] or JPEG [JFIF]');
      }

      /*
      t - Image size restrictions

       00  No restrictions
       01  All images are 256x256 pixels or smaller.
       10  All images are 64x64 pixels or smaller.
       11  All images are exactly 64x64 pixels, unless required
           otherwise.
      */
      final t = flagContent & 0x3;
      key = "d - Tag restrictions[tt]";
      if (t == 0) {
        metadata.set(value: t, key: key, desc: 'No restrictions');
      } else if (t == 1) {
        metadata.set(
            value: t,
            key: key,
            desc: 'All images are 256x256 pixels or smaller');
      } else if (t == 2) {
        metadata.set(
            value: t, key: key, desc: 'All images are 64x64 pixels or smaller');
      } else {
        metadata.set(
            value: t,
            key: key,
            desc:
                'All images are exactly 64x64 pixels, unless required otherwise');
      }
    }
    return start;
  }

  int _parseExtendedHeader(int start) {
    if (!_hasExtendedHeader) return start;
    metadata.enterMapContainer('Extended Header');
    if (_major == '3') {
      return _parseV2_3ExtendedHeader(start);
    } else if (_major == '4') {
      return _parseV2_4ExtendedHeader(start);
    }
    metadata.leaveContainer();
    return start;
  }

  int _parseFrames(int start) {
    _totalFrameSize = 0;
    metadata.enterListContainer('Frames');
    int retstart = start;
    if (_major == '2') {
      retstart = _parseV2_2Frames(start);
    } else if (_major == '3') {
      retstart = _parseV2_3Frames(start);
    } else if (_major == '4') {
      retstart = _parseV2_4Frames(start);
    }
    metadata.leaveContainer();
    return retstart;
  }

  int _parseV2_2Frames(int start) {
    int frameSizes = _size;
    while (frameSizes > 0) {
      // Frame ID
      final frameID = readValue(frameV2_2[0], start);
      if (frameID == latin1.decode([0, 0, 0])) {
        break;
      }
      start += frameV2_2[0].length;
      metadata.enterMapContainer('Frame[$frameID]');
      metadata.set(
          value: "$frameID",
          key: frameV2_2[0].name,
          desc: frameV2_2Map[frameID]);

      // Frame Size
      final frameSizeBytes = readValue(frameV2_2[1], start);
      start += frameV2_2[1].length;
      int frameSize = frameSizeBytes[2] +
          (frameSizeBytes[1] << 8) +
          (frameSizeBytes[0] << 16);
      metadata.set(value: frameSize, key: frameV2_2[1].name);

      // Content
      final contentBytes = bytes.sublist(start, start + frameSize);
      start += frameSize;
      final decoder = ContentDecoder(frameID: frameID, bytes: contentBytes);
      final content = decoder.decode();
      metadata.set(value: content, key: 'Content');
      // calculate left frame sizes
      int rframeSize = frameSize + frameV2_2[0].length + frameV2_2[1].length;
      frameSizes -= rframeSize;
      _totalFrameSize += rframeSize;

      metadata.leaveContainer();
    }
    return start;
  }

  int _parseV2_3Frames(int start) {
    int frameSizes = _size;
    while (frameSizes > 0) {
      // Frame ID
      final frameID = readValue(frameV2_3[0], start);
      if (frameID == latin1.decode([0, 0, 0, 0])) {
        break;
      }
      start += frameV2_3[0].length;
      metadata.enterMapContainer('Frame[$frameID]');
      metadata.set(
          value: "$frameID",
          key: frameV2_3[0].name,
          desc: frameV2_3Map[frameID]);

      // Frame Size
      final frameSizeBytes = readValue(frameV2_3[1], start);
      start += frameV2_3[1].length;
      int frameSize = frameSizeBytes[3] +
          (frameSizeBytes[2] << 8) +
          (frameSizeBytes[1] << 16) +
          (frameSizeBytes[0] << 24);
      metadata.set(value: frameSize, key: frameV2_3[1].name);

      // Frame Flags
      // %abc00000 %ijk00000
      final frameFlags = readValue(frameV2_3[2], start);
      start += frameV2_3[2].length;
      String frameFlagsValue = '';
      // a - Tag alter preservation
      final a = frameFlags[0] & 0x80;
      frameFlagsValue = "a: $a";
      // b - File alter preservation
      final b = frameFlags[0] & 0x40;
      frameFlagsValue = "$frameFlagsValue, b: $b";
      // c - Read only
      final c = frameFlags[0] & 0x20;
      frameFlagsValue = "$frameFlagsValue, c: $c";
      // i - Compression
      final i = frameFlags[1] & 0x80;
      frameFlagsValue = "$frameFlagsValue, i: $i";
      // j - Encryption
      final j = frameFlags[1] & 0x40;
      frameFlagsValue = "$frameFlagsValue, j: $j";
      // k - Grouping identity
      final k = frameFlags[1] & 0x20;
      frameFlagsValue = "$frameFlagsValue, k: $k";
      metadata.set(
          value: frameFlagsValue,
          key: frameV2_3[2].name,
          desc: '%abc00000 %ijk00000');

      // Content
      final contentBytes = bytes.sublist(start, start + frameSize);
      start += frameSize;
      final decoder = ContentDecoder(frameID: frameID, bytes: contentBytes);
      final content = decoder.decode();
      metadata.set(value: content, key: 'Content');
      // calculate left frame sizes
      int rframeSize = frameSize +
          frameV2_3[0].length +
          frameV2_3[1].length +
          frameV2_3[2].length;
      frameSizes -= rframeSize;
      _totalFrameSize += rframeSize;

      metadata.leaveContainer();
    }
    return start;
  }

  int _parseV2_4Frames(int start) {
    int frameSizes = _size;
    while (frameSizes > 0) {
      // Frame ID
      final frameID = readValue(frameV2_4[0], start);
      if (frameID == latin1.decode([0, 0, 0, 0])) {
        break;
      }
      start += frameV2_4[0].length;
      metadata.enterMapContainer('Frame[$frameID]');
      metadata.set(
          value: "$frameID",
          key: frameV2_4[0].name,
          desc: frameV2_4Map[frameID]);

      // Frame Size
      final frameSizeBytes = readValue(frameV2_4[1], start);
      start += frameV2_4[1].length;
      int frameSize = (frameSizeBytes[3] & 0x7F) +
          ((frameSizeBytes[2] & 0x7F) << 7) +
          ((frameSizeBytes[1] & 0x7F) << 14) +
          ((frameSizeBytes[0] & 0x7F) << 21);
      metadata.set(value: frameSize, key: frameV2_4[1].name);

      // Frame Flags
      // %0abc0000 %0h00kmnp
      List<int> flagsBytes = readValue(frameV2_4[2], start);
      start += frameV2_4[2].length;

      // Frame status flags
      final statusFlags = flagsBytes.first;
      /*
        a - Tag alter preservation

     This flag tells the tag parser what to do with this frame if it is
     unknown and the tag is altered in any way. This applies to all
     kinds of alterations, including adding more padding and reordering
     the frames.

     0     Frame should be preserved.
     1     Frame should be discarded.
      */
      final a = (statusFlags & 0x40);

      /*
        b - File alter preservation

     This flag tells the tag parser what to do with this frame if it is
     unknown and the file, excluding the tag, is altered. This does not
     apply when the audio is completely replaced with other audio data.

     0     Frame should be preserved.
     1     Frame should be discarded.
      */
      final b = (statusFlags & 0x20);

      /*
      c - Read only

      This flag, if set, tells the software that the contents of this
      frame are intended to be read only. Changing the contents might
      break something, e.g. a signature. If the contents are changed,
      without knowledge of why the frame was flagged read only and
      without taking the proper means to compensate, e.g. recalculating
      the signature, the bit MUST be cleared.
      */
      final c = (statusFlags & 0x10);

      // Frame format flags
      final formatFlags = flagsBytes.last;
      /*
      h - Grouping identity

      This flag indicates whether or not this frame belongs in a group
      with other frames. If set, a group identifier byte is added to the
      frame. Every frame with the same group identifier belongs to the
      same group.

      0     Frame does not contain group information
      1     Frame contains group information
      */
      final h = (formatFlags & 0x40);

      /*
        k - Compression

      This flag indicates whether or not the frame is compressed.
      A 'Data Length Indicator' byte MUST be included in the frame.

      0     Frame is not compressed.
      1     Frame is compressed using zlib [zlib] deflate method.
            If set, this requires the 'Data Length Indicator' bit
            to be set as well.
      */
      final k = (formatFlags & 0x8);

      /*
      m - Encryption
   
      This flag indicates whether or not the frame is encrypted. If set,
      one byte indicating with which method it was encrypted will be
      added to the frame. See description of the ENCR frame for more
      information about encryption method registration. Encryption
      should be done after compression. Whether or not setting this flag
      requires the presence of a 'Data Length Indicator' depends on the
      specific algorithm used.

      0     Frame is not encrypted.
      1     Frame is encrypted.
      */
      final m = (formatFlags & 0x4);

      /*
        n - Unsynchronisation

      This flag indicates whether or not unsynchronisation was applied
      to this frame. See section 6 for details on unsynchronisation.
      If this flag is set all data from the end of this header to the
      end of this frame has been unsynchronised. Although desirable, the
      presence of a 'Data Length Indicator' is not made mandatory by
      unsynchronisation.

      0     Frame has not been unsynchronised.
      1     Frame has been unsyrchronised.
      */
      final n = (formatFlags & 0x2);

      /*
        p - Data length indicator

      This flag indicates that a data length indicator has been added to
      the frame. The data length indicator is the value one would write
      as the 'Frame length' if all of the frame format flags were
      zeroed, represented as a 32 bit synchsafe integer.

      0      There is no Data Length Indicator.
      1      A data length Indicator has been added to the frame.
      */
      final p = (formatFlags & 0x1);

      String key = frameV2_4[2].name;
      if (showDetail) {
        metadata.set(
            value: a,
            key: "$key: a - Tag alter preservation",
            desc: a == 0
                ? 'Frame should be preserved'
                : 'Frame should be discarded');
        metadata.set(
            value: b,
            key: "$key: b - File alter preservation",
            desc: b == 0
                ? 'Frame should be preserved'
                : 'Frame should be discarded');
        metadata.set(
            value: c,
            key: "$key: c - Read only",
            desc: c == 0 ? 'Read only' : 'Read write');
        metadata.set(
            value: h,
            key: "$key: h - Grouping identity",
            desc: h == 0
                ? 'Frame does not contain group information'
                : 'Frame contains group information');
        metadata.set(
            value: k,
            key: "$key: k - Compression",
            desc: k == 0
                ? 'Frame is not compressed'
                : "Frame is compressed using zlib [zlib] deflate method.If set, this requires the 'Data Length Indicator' bit to be set as well.");
        metadata.set(
            value: m,
            key: "$key: m - Encryption",
            desc: m == 0 ? 'Frame is not encrypted' : 'Frame is encrypted');
        metadata.set(
            value: n,
            key: "$key: n - Unsynchronisation",
            desc: n == 0
                ? 'Frame has not been unsynchronised'
                : 'Frame has been unsyrchronised');
        metadata.set(
            value: p,
            key: "$key: p - Data length indicator",
            desc: p == 0
                ? 'There is no Data Length Indicator'
                : 'A data length Indicator has been added to the frame');
      } else {
        metadata.set(
            value: "%0$a$b${c}0000 %0${h}00$k$m$n$p",
            key: key,
            desc: '%0abc0000 %0h00kmnp');
      }

      // Content
      final contentBytes = bytes.sublist(start, start + frameSize);
      start += frameSize;
      final decoder = ContentDecoder(frameID: frameID, bytes: contentBytes);
      final content = decoder.decode();
      metadata.set(value: content, key: 'Content');
      // calculate left frame sizes
      int rframeSize = frameSize +
          frameV2_4[0].length +
          frameV2_4[1].length +
          frameV2_4[2].length;
      frameSizes -= rframeSize;
      _totalFrameSize += rframeSize;

      metadata.leaveContainer();
    }
    return start;
  }

  int _parsePadding(int start) {
    // Furthermore it MUST NOT have any padding when a tag footer is added to the tag.
    if (_hasFooter) {
      return start;
    }
    metadata.enterMapContainer('Padding');
    final paddingSize = _size - _totalFrameSize;
    metadata.set(value: paddingSize, key: 'Padding Size');
    start += paddingSize;
    metadata.leaveContainer();
    return start;
  }

  /*
    To speed up the process of locating an ID3v2 tag when searching from
   the end of a file, a footer can be added to the tag. It is REQUIRED
   to add a footer to an appended tag, i.e. a tag located after all
   audio data. The footer is a copy of the header, but with a different
   identifier.

     ID3v2 identifier           "3DI"
     ID3v2 version              $04 00
     ID3v2 flags                %abcd0000
     ID3v2 size             4 * %0xxxxxxx
  */
  int _searchFooterReturnFixStart(int start) {
    if (start < 0) return 0;
    // ID
    final idBytes = bytes.sublist(start, start + 3);
    final id = latin1.decode(idBytes);
    if (id != '3DI') {
      return 0;
    }
    start += 3;

    // add version and flags byte sizes
    start += 3;

    // size
    final sizeBytes = bytes.sublist(start, start + 4);
    start += 4;
    int size = (sizeBytes[3] & 0x7F) +
        ((sizeBytes[2] & 0x7F) << 7) +
        ((sizeBytes[1] & 0x7F) << 14) +
        ((sizeBytes[0] & 0x7F) << 21);

    // fix start
    start -= (10 /*footer size*/
        +
        size /*the sum of the byte length of the extended header, the padding and the frames after unsynchronisation*/
        +
        10 /*header size*/);
    return start;
  }

  @override
  String get version => "V2.$_major.$_revision";

  @override
  int get totalLength => 10 + _size + (_hasFooter ? 10 : 0);
}

class ID3Fragment {
  final int length;
  final String name;
  final bool needDecode;

  ID3Fragment({
    required this.name,
    required this.length,
    this.needDecode = true,
  });
}
