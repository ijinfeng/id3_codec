abstract class MetadataEditable {
  const MetadataEditable();
}

class MetadataV1Body extends MetadataEditable {
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

abstract class MetadataV2Body extends MetadataEditable {
  const MetadataV2Body();
}

class MetadataV2_3Body extends MetadataV2Body {
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
  /// Support PNG, JPEG, TIFF, GIF, BMP
  final List<int>? imageBytes;

  /// TSSE[Software/Hardware and settings used for encoding]
  final String? encoding;

  /// TXXX[User defined text information frame]
  final Map<String, String>? userDefines;
}

class MetadataV2_4Body extends MetadataV2_3Body {}

class MetadataProperty<T> {
  MetadataProperty(this.value);

  final T value;

  bool attached = false;
}

abstract class MetadataEditableWrapper {
  MetadataEditableWrapper(this.body);
  final MetadataV2Body body;
  bool hasUnAttachedProperty();
}

class MetadataV2_3Wrapper extends MetadataEditableWrapper {
  MetadataV2_3Wrapper(super.body)
      : assert(body is MetadataV2_3Body),
        title = MetadataProperty((body as MetadataV2_3Body).title),
        artist = MetadataProperty(body.artist),
        album = MetadataProperty(body.album),
        encoding = MetadataProperty(body.encoding),
        imageBytes = MetadataProperty(body.imageBytes),
        userDefines = MetadataProperty(
            body.userDefines?.entries.map((e) => MetadataProperty(e)).toList());

  MetadataProperty<String?> title;
  MetadataProperty<String?> artist;
  MetadataProperty<String?> album;
  MetadataProperty<String?> encoding;
  MetadataProperty<List<int>?> imageBytes;
  MetadataProperty<List<MetadataProperty<MapEntry<String, String>>>?>
      userDefines;

  @override
  bool hasUnAttachedProperty() {
    return !title.attached ||
        !artist.attached ||
        !album.attached ||
        !encoding.attached ||
        !imageBytes.attached ||
        !userDefines.attached;
  }
}

class MetadataV2_4Wrapper extends MetadataV2_3Wrapper {
  MetadataV2_4Wrapper(super.body, {this.tagRestrictions});

  final TagRestrictions? tagRestrictions;
}

// Use in ID3v2.4, read from Extended flags
// %ppqrrstt
class TagRestrictions {
  const TagRestrictions({required this.flags})
      : tagSizeR = (flags & 0xC0) >>> 6,
        textEncodingR = (flags & 0x20) >>> 5,
        textFieldsSizeR = (flags & 0x18) >>> 3,
        imageEncodingR = (flags & 0x4) >>> 2,
        imageSizeR = (flags & 0x3);

  final int flags;

  // Tag size restrictions
  final int tagSizeR;

  // Text encoding restrictions
  final int textEncodingR;

  // Text fields size restrictions
  final int textFieldsSizeR;

  // Image encoding restrictions
  final int imageEncodingR;

  // Image size restrictions
  final int imageSizeR;
}
