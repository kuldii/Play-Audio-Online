import 'dart:io';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("HOME"),
      ),
      body: ListView(
        children: [
          ItemSurah(
            name: "Al-Fatihah",
            ayat: 7,
            url: "https://archive.org/download/001-al-fatihah_202012/001-Al-Fatihah.mp3",
          ),
          ItemSurah(
            name: "An-nas",
            ayat: 6,
            url: "https://archive.org/download/114-surat-an-nas/114%20-%20Surat%20An-Nas.mp3",
          ),
        ],
      ),
    );
  }
}

class ItemSurah extends StatefulWidget {
  const ItemSurah({
    Key? key,
    required this.name,
    required this.url,
    required this.ayat,
  }) : super(key: key);

  final String name;
  final String url;
  final int ayat;

  @override
  State<ItemSurah> createState() => _ItemSurahState();
}

class _ItemSurahState extends State<ItemSurah> {
  Dio dio = Dio();
  AudioPlayer audioPlayer = AudioPlayer();
  AudioCache audioCache = AudioCache();
  final Connectivity connectivity = Connectivity();
  ConnectivityResult result = ConnectivityResult.none;

  bool pause = false;
  bool playing = false;
  bool loading = false;
  bool downloaded = false;
  double progress = 0.0;

  Future<void> resumeAudio() async {
    await audioPlayer.resume();
    setState(() {
      pause = false;
    });
  }

  Future<void> pauseAudio() async {
    await audioPlayer.pause();
    setState(() {
      pause = true;
    });
  }

  Future<void> stopAudio() async {
    await audioPlayer.stop();
    setState(() {
      playing = false;
    });
  }

  Future<void> playAudio() async {
    String fileName = "${widget.name}.mp3";
    String path = await _getFilePath(fileName);
    final File file = File(path);

    Uint8List bytes = await file.readAsBytes();

    setState(() {
      playing = true;
    });
    await audioPlayer.play(BytesSource(bytes));
  }

  void checkFile() async {
    String fileName = "${widget.name}.mp3";
    String path = await _getFilePath(fileName);

    final File file = File(path);
    bool check = await file.exists();
    if (check == true) {
      setState(() {
        downloaded = true;
      });
    }
  }

  void startDownloading() async {
    setState(() {
      loading = true;
      progress = 0.0;
    });
    String url = widget.url;
    String fileName = "${widget.name}.mp3";
    String path = await _getFilePath(fileName);

    await dio.download(
      url,
      path,
      onReceiveProgress: (recivedBytes, totalBytes) {
        setState(() {
          progress = recivedBytes / totalBytes;
        });

        print(progress);
      },
      deleteOnError: true,
    ).then((_) {
      print("SELESAI DOWNLOAD");
      setState(() {
        loading = false;
        downloaded = true;
      });
    });
  }

  Future<String> _getFilePath(String filename) async {
    final dir = await getApplicationDocumentsDirectory();
    return "${dir.path}/$filename";
  }

  Future<void> checkConnection() async {
    result = await connectivity.checkConnectivity();
  }

  @override
  void initState() {
    super.initState();
    checkFile();
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(widget.name),
      subtitle: Text("${widget.ayat} ayat"),
      trailing: loading == true
          ? Container(
              width: 50,
              color: Colors.amber,
              padding: EdgeInsets.all(10),
              child: Center(
                child: Text("${(progress * 100).floor()}%"),
              ),
            )
          : downloaded == false
              ? IconButton(
                  onPressed: () async {
                    // check dulu internetnya
                    await checkConnection();
                    if (result != ConnectivityResult.none) {
                      startDownloading();
                    }
                  },
                  icon: Icon(Icons.download),
                )
              : playing == false
                  ? IconButton(
                      onPressed: () async {
                        // PLAY AUDIO
                        await playAudio();
                      },
                      icon: Icon(Icons.play_arrow),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // PAUSE (BLM DIPAUSE & SEDANG DIPAUSE)
                        pause == false
                            ? IconButton(
                                onPressed: () async {
                                  // PAUSE AUDIO
                                  await pauseAudio();
                                },
                                icon: Icon(Icons.pause),
                              )
                            : IconButton(
                                onPressed: () async {
                                  // RESUME AUDIO
                                  await resumeAudio();
                                },
                                icon: Icon(Icons.play_arrow),
                              ),
                        // STOP
                        IconButton(
                          onPressed: () async {
                            // STOP AUDIO
                            await stopAudio();
                          },
                          icon: Icon(Icons.stop),
                        ),
                      ],
                    ),
    );
  }
}
