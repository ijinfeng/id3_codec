import 'package:id3_codec/id3_decoder_impl.dart';
import 'package:id3_codec/id3_metainfo.dart';

class ID3Decoder {
  const ID3Decoder(List<int> bytes) : _bytes = bytes;

  final List<int> _bytes;
  bool get isEmpty => _bytes.isEmpty;

  /// synchronous decoding.
  /// Read the ID3 in the audio file and return ID3MetataInfo object information.
  ///
  /// ```dart
  /// final decoder = ID3Decoder(bytes);
  /// final metadatas = decoder.decodeSync();
  /// for (var metadata in metadatas) {
  ///     debugPrint(metadata.toTagMap().toString());
  /// }
  /// ```
  List<ID3MetataInfo> decodeSync() {
    assert(!isEmpty, 'id3 data is empty');
    if (isEmpty) return [];

    final List<ID3MetataInfo> metadatas = [];
    // parse ID3v1
    final id3v1 = ID3V1Decoder(_bytes);
    final retv1 = id3v1.convert();
    if (retv1) {
      metadatas.add(id3v1.metadata);
    }

    // parse ID3v2
    final id3v2 = ID3V2Decoder(
        retv1 ? _bytes.sublist(0, _bytes.length - id3v1.totalLength) : _bytes);
    final retv2 = id3v2.convert();
    if (retv2) {
      metadatas.add(id3v2.metadata);
    }
    return metadatas;
  }

  /// asynchronous decoding.
  /// Read the ID3 in the audio file and return ID3MetataInfo object information.
  ///
  /// ```dart
  /// final decoder = ID3Decoder(bytes);
  /// final metadatas = await decoder.decodeAsync();
  /// for (var metadata in metadatas) {
  ///     debugPrint(metadata.toTagMap().toString());
  /// }
  /// ```
  Future<List<ID3MetataInfo>> decodeAsync() {
    return Future(() {
      return decodeSync();
    });
  }
}
