# id3_codec

An ID3 tag information parsing library based on dart, which supports the operation of `Flutter` on all platforms.

## Support ID3 version

- [x] v1
- [x] v1.1
- [x] v2.2
- [x] v2.3
- [x] v2.4

## How to use

read by async.
```dart
final data = await rootBundle.load("assets/song1.mp3");
final decoder = ID3Decoder(data.buffer.asUint8List());
decoder.decodeAsync().then((metadata) {
    debugPrint(metadata.toString());
});
```

read by sync.
```dart
final data = await rootBundle.load("assets/song1.mp3");
final decoder = ID3Decoder(data.buffer.asUint8List());
final metadata = decoder.decodeSync();
debugPrint(metadata.toString());
```

