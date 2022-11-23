# id3_codec

An ID3 tag information parsing library based on dart, which supports the operation of `Flutter` on all platforms.


## ID3 version that supports decoding

- [x] v1
- [x] v1.1
- [x] v2.2
- [x] v2.3
- [x] v2.4


## ID3 version that supports encoding

NOW, START SUPPORTED ID3 **ENCODE**!🎉

- [x] v1
- [x] v1.1
- [ ] v2.2
- [ ] v2.3
- [ ] v2.4

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
  id3_codec: ^0.0.1
```

Alternatively, your editor might support flutter pub get. Check the docs for your editor to learn more.

## How to use

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

* encode to v1 and v1.1
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
