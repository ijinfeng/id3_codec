# id3_codec

An ID3 tag information codec library based on dart, which supports the operation of `Flutter` on all platforms. You can easily read the tag information of the audio in detail, or edit the tag information.

![v1](https://img.shields.io/badge/ID3-v1-green)
![v1.1](https://img.shields.io/badge/ID3-v1.1-green)
![v2.2](https://img.shields.io/badge/ID3-v2.2-green)
![v2.3](https://img.shields.io/badge/ID3-v2.3-green)
![v2.4](https://img.shields.io/badge/ID3-v2.4-green)

![decode](https://img.shields.io/badge/ID3-decode-red)
![encode](https://img.shields.io/badge/ID3-encode-yellow)

## ID3 version that supports decode to readable tags

- [x] v1
- [x] v1.1
- [x] v2.2
- [x] v2.3
- [x] v2.4


## ID3 version that supports edit or encoding

- [x] v1
- [x] v1.1
- [ ] v2.2（Not support）
- [x] v2.3
- [x] v2.4

## Install

Depend on it
Run this command:

With Flutter:
```dart
  flutter pub add id3_codec
```

This will add a line like this to your package's pubspec.yaml (and run an implicit flutter pub get):

```dart
dependencies:
  id3_codec: ^0.0.3
```

Alternatively, your editor might support flutter pub get. Check the docs for your editor to learn more.

## How to use

### Decode

You can read all ID3 tag information from a given byte sequence. And display with `ID3MetataInfo` or a Map.

Of course, you can also refer to the [example](https://github.com/ijinfeng/id3_codec/tree/main/example) I provided to familiarize yourself with the detailed usage.

* read by async.
```dart
final data = await rootBundle.load("assets/song1.mp3");
final decoder = ID3Decoder(data.buffer.asUint8List());
decoder.decodeAsync().then((metadata) {
    debugPrint(metadata.toString());
});
```

* read by sync.
```dart
final data = await rootBundle.load("assets/song1.mp3");
final decoder = ID3Decoder(data.buffer.asUint8List());
final metadata = decoder.decodeSync();
debugPrint(metadata.toString());
```

### Encode

You can edit existing id3 tags, or add new tag information into it.

* edit or encode v1 and v1.1
```dart
final data = await rootBundle.load("assets/song2.mp3");
final bytes = data.buffer.asUint8List();
final encoder = ID3Encoder(bytes);
final resultBytes = encoder.encode(MetadataV1Body(
                title: 'Ting wo shuo,xiexie ni',
                artist: 'Wu ming',
                album: 'Gan en you ni',
                year: '2021',
                comment: 'I am very happy!',
                track: 1,
                genre: 2
               ));

// you can read [resultBytes] by ID3Decoder or other ID3 tag pubs;
```
* edit or encode v2.3/v2.4

```dart
final data = await rootBundle.load("assets/song1.mp3");
final bytes = data.buffer.asUint8List();

final header = await rootBundle.load("assets/wx_header.png");
final headerBytes = header.buffer.asUint8List();

final encoder = ID3Encoder(bytes);
// if you need encode or edit v2.4, just use `MetadataV2_4Body` instead of `MetadataV2_3Body`
// ignore: prefer_const_constructors
final resultBytes = encoder.encodeSync(MetadataV2_3Body(
    title: '听我说谢谢你！',
    imageBytes: headerBytes,
    artist: '歌手ijinfeng',
    userDefines: {
      "时长": '2:48',
      "userId": "ijinfeng"
    },
    album: 'ijinfeng的专辑',
    )); 

// you can read [resultBytes] by `ID3Decoder` or other ID3 tag pubs;
```

## Related articles

- [Flutter ID3解码实现- v1、v1.1、v2.2、v2.3](https://juejin.cn/post/7166063262541283336)

- [Flutter ID3解码实现-v2.4](https://juejin.cn/post/7168678355020021796)

- [Flutter下 ID3 编码实现-超详细](https://juejin.cn/post/7171373297639112734)