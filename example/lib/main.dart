import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:id3/id3.dart';
import 'package:id3_codec/id3_decoder.dart';
import 'package:id3_codec/id3_encoder.dart';
import 'package:id3_codec/encode_metadata.dart';
import 'package:path_provider/path_provider.dart';

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
    rootBundle.load("assets/dafang.mp3").then((value) {
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
                      debugPrint(metadata.toString());
                    }
                  });
                },
                child: const Text('[id3_codec] 解码')),
            TextButton(
                onPressed: () async {
                  final instance = MP3Instance(bytes);
                  final ret = instance.parseTagsSync();
                  if (ret) {
                    debugPrint(instance.getMetaTags().toString());
                  }
                },
                child: const Text('三方库[id3] 解码')),
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
                child: const Text('编码 ID3v1')),
            TextButton(
                onPressed: () async {
                  final header = await rootBundle.load("assets/wx_header.png");
                  final headerBytes = header.buffer.asUint8List();

                  final encoder = ID3Encoder(bytes);
// ignore: prefer_const_constructors
                  bytes = encoder.encodeSync(MetadataV2_3Body(
                    title: '听我说谢谢你！',
                    imageBytes: headerBytes,
                    artist: '歌手ijinfeng',
                    userDefines: {"时长": '2:48', "userId": "ijinfeng"},
                    album: 'ijinfeng出产的专辑',
                  ));
                  debugPrint("---2.3编码成功");
                },
                child: const Text('编码 ID3v2.3')),
            TextButton(
                onPressed: () async {
                  final header = await rootBundle.load("assets/wx_header.png");
                  final headerBytes = header.buffer.asUint8List();

                  final encoder = ID3Encoder(bytes);
// ignore: prefer_const_constructors
                  bytes = encoder.encodeSync(MetadataV2_4Body(
                    title: '拔萝卜',
                    imageBytes: headerBytes,
                    artist: '歌手小兔子',
                    userDefines: {"种族": '兔八哥'},
                    album: '向着光明的太阳 GO~',
                  ));
                  debugPrint("---2.4编码成功");
                },
                child: const Text('编码 ID3v2.4')),
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
                  debugPrint("写入文件成功: ${file.path}");
                },
                child: const Text('写入文件')),
          ],
        ),
      ),
    );
  }
}
