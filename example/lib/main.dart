import 'dart:convert';

import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:id3/id3.dart';
// import 'package:id3_codec/byte_codec.dart';
// import 'package:id3_codec/byte_util.dart';
// import 'package:id3_codec/id3_decoder.dart';
// import 'package:id3_codec/id3_encoder.dart';
// import 'package:id3_codec/encode_metadata.dart';
import 'package:path_provider/path_provider.dart';
import 'package:id3_codec/id3_codec.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<int> bytes = [];

  @override
  void initState() {
    super.initState();
    // assets/song1.mp3 ID3v2.3
    // assets/song2.mp3
    // assets/dafang.mp3
    rootBundle.load("assets/song2.mp3").then((value) {
      bytes = value.buffer.asUint8List();
    });
    // bytes = [0x11, 0x22, 0x33];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            TextButton(
                onPressed: () async {
                  // final data = await rootBundle.load("assets/song1.mp3");
                  // final bytes = data.buffer.asUint8List();
                  final decoder = ID3Decoder(bytes);
                  decoder.decodeAsync().then((metadatas) {
                    for (var metadata in metadatas) {
                      debugPrint(metadata.toTagMap().toString());
                    }
                  });
                },
                child: const Text('[id3_codec] ??????')),
            TextButton(
                onPressed: () async {
                  final data = await rootBundle.load("assets/Track08.mp3");
                  final bytes = data.buffer.asUint8List();
                  final decoder = ID3Decoder(bytes);
                  decoder.decodeAsync().then((metadatas) {
                    for (var metadata in metadatas) {
                      debugPrint(metadata.toTagMap().toString());
                    }
                  });
                },
                child: const Text('encode NO ID3 file')),
            TextButton(
                onPressed: () async {
                  final instance = MP3Instance(bytes);
                  final ret = instance.parseTagsSync();
                  if (ret) {
                    debugPrint(instance.getMetaTags().toString());
                  }
                },
                child: const Text('?????????[id3] ??????')),
            const Divider(),
            TextButton(
                onPressed: () async {
                  final encoder = ID3Encoder(bytes);
                  // ignore: prefer_const_constructors
                  bytes = encoder.encodeSync(MetadataV1Body(
                      title: 'Ting wo shuo,xiexie ni',
                      artist: 'Wu ming',
                      album: 'Gan en you ni',
                      year: '2021',
                      comment: 'I am very happy!',
                      track: 1,
                      genre: 2));
                },
                child: const Text('?????? ID3v1')),
            TextButton(
                onPressed: () async {
                  final header = await rootBundle.load("assets/wx_header.png");
                  final headerBytes = header.buffer.asUint8List();
                  // 
                  final al = {"picUrl":"http://p3.music.126.net/GpnLproqUUyc4xmYKpRFcQ==/109951166516282895.jpg"};
                  final encoder = ID3Encoder(bytes);
// ignore: prefer_const_constructors
                  bytes = encoder.encodeSync(MetadataV2_3Body(
                    title: '?????????????????????',
                    imageBytes: headerBytes,
                    artist: '??????ijinfeng',
                    userDefines: {
                      "al": al.toString()
                    },
                    album: 'ijinfeng???????????????',
                  ));
                  debugPrint("---2.3????????????");
                },
                child: const Text('?????? ID3v2.3')),
            TextButton(
                onPressed: () async {
                  final header = await rootBundle.load("assets/wx_header.png");
                  final headerBytes = header.buffer.asUint8List();

                  final encoder = ID3Encoder(bytes);
// ignore: prefer_const_constructors
                  bytes = encoder.encodeSync(MetadataV2_4Body(
                    title: '?????????',
                    imageBytes: headerBytes,
                    artist: '???????????????',
                    userDefines: {"??????": '?????????'},
                    album: '????????????????????? GO~',
                  ));
                  debugPrint("---2.4????????????");
                },
                child: const Text('?????? ID3v2.4')),
            const Divider(),
            TextButton(
                onPressed: () async {
                  final downloadDir = await getDownloadsDirectory();
                  var file = File('${downloadDir?.path}/rewrite_song.mp3');
                  final exist = await file.exists();
                  if (!exist) {
                    await file.create(recursive: true);
                  }
                  await file.writeAsBytes(bytes);
                  debugPrint("??????????????????: ${file.path}");
                },
                child: const Text('????????????')),

                TextButton(
                onPressed: () {
                  List<int> bytes = [0x00, 0x00, 0x00, 0x00, 0x00];

  print(HexOutput(ByteUtil.trimStart(bytes)));
print(HexOutput(ByteUtil.trimEnd(bytes)));
                  final ret = iso_8859_1_codec.decode(bytes);
                  debugPrint("$ret, ok");
                },
                child: const Text('?????????????????????')),
          ],
        ),
      ),
    );
  }
}
