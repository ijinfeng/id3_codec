import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:id3/id3.dart';
import 'package:id3_codec/byte_codec.dart';
import 'package:id3_codec/id3_decoder.dart';
import 'package:id3_codec/id3_encoder.dart';

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
    rootBundle.load("assets/song2.mp3").then((value) {
      bytes = value.buffer.asUint8List();
    });
    // bytes = [0x11, 0x22, 0x33];
    debugPrint({"hah":12}.toString());
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
            child: const Text('ID3 解码')),

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
              bytes = encoder.encode(MetadataV1Body(
                title: 'Ting wo shuo,xiexie ni',
                artist: 'Wu ming',
                album: 'Gan en you ni',
                year: '2021',
                comment: 'I am very happy!',
                track: 1,
                genre: 2
               ));
            },
            child: const Text('编码 ID3v1')),

            TextButton(
            onPressed: () async {
              
              final encoder = ID3Encoder(bytes);
              // ignore: prefer_const_constructors
              bytes = encoder.encode(MetadataV1Body(
                title: 'Ting wo shuo,xiexie ni',
                artist: 'Wu ming',
                album: 'Gan en you ni',
                year: '2021',
                comment: 'I am very happy!',
                track: 1,
                genre: 2
               ));
            },
            child: const Text('编码 ID3v2.3')),

const Divider(),

            TextButton(
            onPressed: () {
              final codec = ByteCodec(textEncodingByte: 0x01);
              final bytes = codec.encode('我是移植小蜜蜂');
              final hex = HexOutput(bytes);
              debugPrint(hex.toString());
              final ret = codec.decode(bytes);
              debugPrint("ret==$ret");
            },
            child: const Text('codec 编码UTF16')),
          ],
        ),
      ),
    );
  }
}
