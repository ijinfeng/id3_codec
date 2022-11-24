import 'package:id3_codec/id3_encoder_impl.dart';

class ID3Encoder {
  const ID3Encoder(List<int> bytes) : _bytes = bytes;

  final List<int> _bytes;

  List<int> encode(EncodeMetadata data) {
    if (data is MetadataV1Body) {
      final encoder = ID3V1Encoder(_bytes);
      return encoder.encode(data);
    } else if (data is MetadataV2_3Body)  {
      final encoder = ID3V2_3Encoder(_bytes);
      return encoder.encode(data);
    }
    else {
      // TODO:implementation
    }
    return _bytes;
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
  // ‘2022’
  final String? year;
  final String? comment;
  final int? genre;
  final int? track;
}

abstract class EncodeMetadataV2Body extends EncodeMetadata {
  const EncodeMetadataV2Body();
}

class MetadataV2_3Body extends EncodeMetadataV2Body {
  const MetadataV2_3Body({
    this.title,
    this.artist,
    this.album,
    this.encoding,
    this.imageBytes,
    this.userDefines,
  });

  /// TIT2[Title/songname/content description]
  final String? title;
  /// TPE1[Lead performer(s)/Soloist(s)]
  final String? artist;
  /// TALB[Album/Movie/Show title]
  final String? album;
  /// APIC[Attached picture]
  final List<int>? imageBytes;
  /// TSSE[Software/Hardware and settings used for encoding]
  final String? encoding;
  /// TXXX[User defined text information frame]
  final Map<String, String>? userDefines;
}
