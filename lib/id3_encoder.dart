import 'package:id3_codec/encode_metadata.dart';
import 'package:id3_codec/id3_encoder_impl.dart';

class ID3Encoder {
  const ID3Encoder(List<int> bytes) : _bytes = bytes;

  final List<int> _bytes;

  List<int> encodeSync(MetadataEditable data) {
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

