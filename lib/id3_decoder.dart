import 'package:id3_codec/id3_define.dart';
import 'package:id3_codec/id3_metainfo.dart';

class ID3Decoder {
  const ID3Decoder(List<int> bytes) : _bytes = bytes;

  final List<int> _bytes;
  bool get isEmpty => _bytes.isEmpty;

  List<ID3MetataInfo> decodeSync() {
    assert(!isEmpty, 'id3 data is empty');
    if (isEmpty) return [];

    final List<ID3MetataInfo> metadatas = [];
    // parse ID3v1
    final id3v1 = ID3V1(_bytes);
    final retv1 = id3v1.convert();
    if (retv1) {
      metadatas.add(id3v1.metadata);
    }

    // parse ID3v2
    final id3v2 = ID3V2(retv1 ? _bytes.sublist(0, _bytes.length - id3v1.totalLength) : _bytes);
    final retv2 = id3v2.convert();
    if (retv2) {
      metadatas.add(id3v2.metadata);
    }
    return metadatas;
  }

  Future<List<ID3MetataInfo>> decodeAsync() {
    return Future(() {
      return decodeSync();
    });
  }
}