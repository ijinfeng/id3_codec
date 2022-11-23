class ID3Encoder {
  const ID3Encoder(List<int> bytes) : _bytes = bytes;

  final List<int> _bytes;

  void encode(EncodeMetadata data) {
    if (data is MetadataV1) {
      final encoder = _ID3V1Encoder(_bytes);
      encoder.encode(data);
    }
  }
}

abstract class _ID3Encoder {
  const _ID3Encoder(this.bytes);
  final List<int> bytes;
}

class _ID3V1Encoder extends _ID3Encoder {
  const _ID3V1Encoder(super.bytes);

  void encode(MetadataV1 data) {
    
  }
}

abstract class EncodeMetadata {
  const EncodeMetadata();
}

class MetadataV1 extends EncodeMetadata {
  const MetadataV1({
    this.title,
    this.artist,
    this.album,
    this.year,
    this.comment,
    this.genre
  }); 

  final String? title;
  final String? artist;
  final String? album;
  final String? year;
  final String? comment;
  final int? genre;
}