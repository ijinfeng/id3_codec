import 'package:id3_codec/encode_metadata.dart';
import 'package:id3_codec/id3_encoder_impl.dart';

class ID3Encoder {
  const ID3Encoder(List<int> bytes) : _bytes = bytes;

  /// audio file byte array
  final List<int> _bytes;

  /// synchronous encoding id3
  /// - data: ID3 tag metadata information, you can set ID3v1/v1.1 or ID3v2.3 or ID3v2.4 metadataBody, 
  /// but not support ID3v2.2
  /// 
  /// ```dart
  /// final encoder = ID3Encoder(bytes);
  /// final resultBytes = encoder.encodeSync(MetadataV2p3Body(
  ///             title: '听我说谢谢你！',
  ///             artist: '歌手ijinfeng',
  ///             userDefines: {"时长": '2:48', "userId": "ijinfeng"},
  ///             album: 'ijinfeng出产的专辑',
  ///         ));
  /// ```
  List<int> encodeSync(MetadataEditable data) {
    if (data is MetadataV1Body) {
      final encoder = ID3V1Encoder(_bytes);
      return encoder.encode(data);
    } else if (data is MetadataV2p3Body)  {
      final encoder = ID3V2_3Encoder(_bytes);
      return encoder.encode(data);
    } else if (data is MetadataV2p4Body) {
      final encoder = ID3V2_4Encoder(_bytes);
      return encoder.encode(data);
    }
    return _bytes;
  }

  /// asynchronous encoding id3
  /// - data: ID3 tag metadata information, you can set ID3v1/v1.1 or ID3v2.3 or ID3v2.4 metadataBody, 
  /// but not support ID3v2.2
  /// 
  /// ```dart
  /// final encoder = ID3Encoder(bytes);
  /// final resultBytes = await encoder.encodeAsync(MetadataV2p3Body(
  ///             title: '听我说谢谢你！',
  ///             artist: '歌手ijinfeng',
  ///             userDefines: {"时长": '2:48', "userId": "ijinfeng"},
  ///             album: 'ijinfeng出产的专辑',
  ///         ));
  /// ```
  Future<List<int>> encodeAsync(MetadataEditable data) {
    return Future(() {
      return encodeSync(data);
    });
  }
}

