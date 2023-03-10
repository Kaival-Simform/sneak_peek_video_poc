import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:ffmpeg_kit_flutter_min_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_min_gpl/ffmpeg_kit_config.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_sound_lite/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:video_editor/video_editor.dart';
import 'package:video_editor_sdk/video_editor_sdk.dart';
import 'package:video_player/video_player.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

const platform = MethodChannel('sneakpeak-camera');

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Video Recording',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      themeMode: ThemeMode.dark,
      home: const VideoRecordingScreen(),
    );
  }
}

class UIKITVIEW extends StatelessWidget {
  const UIKITVIEW({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const String viewType = '<platform-view-type>';
    // Pass parameters to the platform side.
    final Map<String, dynamic> creationParams = <String, dynamic>{};

    return Scaffold(
      floatingActionButton: GestureDetector(
        onTap: () {
          if (isRecording) {
            stopDualCamRecording();
          } else {
            startDualCamRecording();
          }
        },
        child: ShutterButton(
            isRecording: isRecording, alreadyDonePercent: 0, percent: 0),
      ),
      body: Stack(
        children: [
          UiKitView(
            viewType: viewType,
            layoutDirection: TextDirection.ltr,
            creationParams: creationParams,
            creationParamsCodec: const StandardMessageCodec(),
          ),
        ],
      ),
    );
  }
}

bool isRecording = false;

startDualCamRecording() async {
  final int result = await platform.invokeMethod('startRecording');
  print(result);
}

stopDualCamRecording() async {
  final int result = await platform.invokeMethod('stopRecording');
}

class VideoRecordingScreen extends StatefulWidget {
  const VideoRecordingScreen({Key? key}) : super(key: key);

  @override
  State<VideoRecordingScreen> createState() => _VideoRecordingScreenState();
}

class _VideoRecordingScreenState extends State<VideoRecordingScreen> {
  late CameraController cameraController;
  bool _isLoadingCamera = true;
  bool isRecording = false;
  Timer? _timer;
  int totalRecordingDurationInSecs = 0;
  int lastDurationInSecs = 0;
  int maxPeekRecordingSecs = 10;
  List<SPClip> clips = [];
  late List<CameraDescription> cams;
  List<AssetEntity> selectedAssets = [];
  List<AssetEntity> assets = [];
  bool isLoading = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _getCameraDescription();
    _getAssets();
  }

  _getCameraDescription() async {
    cams = await availableCameras();
    if (cams.isNotEmpty) {
      print("CAMS => ${cams.length}");
      _initCamera(cams.first);
    }
  }

  _getAssets() async {
    final PermissionState _ps = await PhotoManager.requestPermissionExtend();
    if (_ps.isAuth) {
      final assetPaths = await PhotoManager.getAssetPathList(onlyAll: true);
      if (assetPaths.isNotEmpty) {
        final totalAssetInsidePath = await assetPaths.first.assetCountAsync;
        if (totalAssetInsidePath > 0) {
          final assetPageResult = await assetPaths.first.getAssetListPaged(
            page: 0,
            size: 1,
          );
          assets.add(assetPageResult.first);
        }
      }
    } else {
      // Limited(iOS) or Rejected, use `==` for more precise judgements.
      // You can call `PhotoManager.openSetting()` to open settings for further steps.

      await PhotoManager.openSetting();
    }
    setState(() {
      print("ASSET COUNT LEN => ${assets.length}");
    });
  }

  _initCamera(CameraDescription description) async {
    try {
      cameraController = CameraController(
        description,
        ResolutionPreset.max,
        enableAudio: true,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await cameraController.initialize();
      cameraController.addListener(() {
        setState(() {
          isRecording = cameraController.value.isRecordingVideo;
        });
      });
      setState(() {
        _isLoadingCamera = false;
      });
      print("Done");
    } catch (e) {
      print(e);
    }
  }

  undoClip() async {
    totalRecordingDurationInSecs -= clips.last.durationInSecs;
    clips.removeLast();
    debugPrint(totalRecordingDurationInSecs.toString());
    setState(() {});
  }

  bool get isUndoAvailable => clips.isNotEmpty && !isRecording;

  _switchCam() async {
    final lensDirection = cameraController.description.lensDirection;
    CameraDescription newDescription;
    if (lensDirection == CameraLensDirection.front) {
      newDescription = cams.firstWhere((description) =>
          description.lensDirection == CameraLensDirection.back);
    } else {
      newDescription = cams.firstWhere((description) =>
          description.lensDirection == CameraLensDirection.front);
    }
    _initCamera(newDescription);
  }

  startRecording() async {
    try {
      await cameraController.startVideoRecording(
        onAvailable: (image) {
          debugPrint("Video Stream Available");
        },
      );
      lastDurationInSecs = 0;
      startTimer();
    } catch (e) {
      print(e);
    }
  }

  stopRecording() async {
    try {
      final recordRes = await cameraController.stopVideoRecording();
      clips.add(SPClip(
          mediaPath: recordRes.path, durationInSecs: lastDurationInSecs));
      stopTimer();
      setState(() {});
      print("TOTAL STEPS => ${clips.length}");
    } catch (e) {
      print(e);
      setState(() {
        isRecording = false;
      });
    }
  }

  startTimer() {
    if (_timer != null) _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      totalRecordingDurationInSecs++;
      lastDurationInSecs++;
      if (totalRecordingDurationInSecs == maxPeekRecordingSecs) {
        stopRecording();
      }
      setState(() {});
    });
  }

  stopTimer() {
    if (_timer != null && _timer!.isActive) _timer?.cancel();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
          backgroundColor: Colors.white,
          body: Center(
            child: PictureToVideoLoaderScreen(),
          ));
    }
    return Scaffold(
      backgroundColor: Colors.black26,
      floatingActionButton: GestureDetector(
        onTap: () {
          if (totalRecordingDurationInSecs < maxPeekRecordingSecs) {
            if (isRecording) {
              stopRecording();
            } else {
              startRecording();
            }
          }
        },
        child: ShutterButton(
            isRecording: isRecording,
            alreadyDonePercent: ((maxPeekRecordingSecs -
                    (clips.fold(0,
                        (value, element) => value + element.durationInSecs))) *
                100),
            percent: totalRecordingDurationInSecs / maxPeekRecordingSecs * 100),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      body: SafeArea(
        child: Stack(
          children: [
            if (_isLoadingCamera) ...[
              const Center(
                child: Text("Loading Cams"),
              ),
            ] else ...[
              // const Center(
              //   child: Text(
              //     "No Cam No fun",
              //     style: TextStyle(color: Colors.white),
              //   ),
              // ),
              CamPreviewWidget(
                cameraController: cameraController,
              ),
            ],
            if (isUndoAvailable) ...[
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                  child: ElevatedButton(
                      onPressed: sendClipsToVideoEditorSDK,
                      // onPressed: _sendClipToTapiocaBall,
                      child: const Text("Next")),
                ),
              ),
            ],
            if (assets.isNotEmpty) ...[
              Align(
                alignment: Alignment.bottomLeft,
                child: FutureBuilder<File?>(
                  future: assets.first.loadFile(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData && !snapshot.hasError) {
                      return snapshot.data != null
                          ? Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: GestureDetector(
                                onTap: () async {
                                  final pickedAssets =
                                      await AssetPicker.pickAssets(
                                    context,
                                    pickerConfig: AssetPickerConfig(
                                      maxAssets: 5,
                                      selectedAssets: selectedAssets,
                                    ),
                                  );
                                  if (pickedAssets is List<AssetEntity>) {
                                    selectedAssets = pickedAssets;
                                    _convertPictureToVideo();
                                    setState(() {});
                                  }
                                },
                                child: ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.file(
                                      File(snapshot.data!.path),
                                      fit: BoxFit.cover,
                                      height: 60,
                                      width: 60,
                                    )),
                              ),
                            )
                          : IconButton(
                              icon: Icon(Icons.photo),
                              onPressed: () async {
                                final pickedAssets =
                                    await AssetPicker.pickAssets(
                                  context,
                                  pickerConfig: AssetPickerConfig(
                                    maxAssets: 5,
                                    selectedAssets: selectedAssets,
                                  ),
                                );
                                if (pickedAssets is List<AssetEntity>) {
                                  selectedAssets = pickedAssets;
                                  _convertPictureToVideo();
                                  setState(() {});
                                }
                              },
                            );
                    }
                    return CircleAvatar(
                      backgroundColor: Colors.blue,
                      child: IconButton(
                        icon: Icon(Icons.photo),
                        onPressed: () async {
                          final pickedAssets = await AssetPicker.pickAssets(
                            context,
                            pickerConfig: AssetPickerConfig(
                              maxAssets: 5,
                              selectedAssets: selectedAssets,
                            ),
                          );
                          if (pickedAssets is List<AssetEntity>) {
                            selectedAssets = pickedAssets;
                            _convertPictureToVideo();
                            setState(() {});
                          }
                        },
                      ),
                    );
                  },
                ),
              )
            ] else ...[
              IconButton(
                icon: Icon(Icons.photo),
                onPressed: () async {
                  final pickedAssets = await AssetPicker.pickAssets(
                    context,
                    pickerConfig: AssetPickerConfig(
                      maxAssets: 5,
                      selectedAssets: selectedAssets,
                    ),
                  );
                  if (pickedAssets is List<AssetEntity>) {
                    selectedAssets = pickedAssets;
                    _convertPictureToVideo();
                    setState(() {});
                  }
                },
              ),
            ],
            if (!isRecording) ...[
              Align(
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: CircleAvatar(
                    child: IconButton(
                        onPressed: () {
                          _switchCam();
                        },
                        icon: const Icon(Icons.switch_camera)),
                  ),
                ),
              ),
              const SizedBox(
                width: 10,
              ),
            ],
          ],
        ),
      ),
    );
  }

  _convertPictureToVideo() async {
    setState(() {
      isLoading = true;
    });
    clips.clear();
    for (var i = 0; i < selectedAssets.length; i++) {
      if (selectedAssets[i].type == AssetType.image) {
        final path = await selectedAssets[i].file;
        if (path != null) {
          var outputPath =
              await _executeFFMPEGPhotoToVideo(inputPath: path.path);
          print("OP PATH => $outputPath");
          if (outputPath != null) {
            clips.add(SPClip(mediaPath: outputPath, durationInSecs: 5));
          }
        }
      }
    }
    setState(() {
      isLoading = false;
    });
    if (clips.isNotEmpty) {
      sendClipsToVideoEditorSDK();
      // Navigator.of(context).push(MaterialPageRoute(
      //     builder: (_) => VideoScreen(clips.first.mediaPath)));
    }
  }

  Future<String> _executeFFMPEGPhotoToVideo({required String inputPath}) async {
    return await createFolder('Converted').then((value) async {
      String outputPath =
          value + "/output_${DateTime.now().millisecondsSinceEpoch}.mp4";
      try {
        print(outputPath);
        // final cmd = '-i $inputPath -c:v libx264 -t 15 -pix_fmt yuv420p $outputPath';
        //WORKING
        // final cmd =
        //     '-i $inputPath -c:v libx264 -t 15 -pix_fmt yuv420p -vf scale=320:240 $outputPath';
        final cmd =
            '-loop 1 -i $inputPath -c:v libx264 -t 5 -pix_fmt yuv420p -vf scale=420:746 $outputPath';
        // final cmd = '-framerate 1 -pattern_type glob
        // -i $inputPath -c:v libx264 -c:a copy -shortest -r 30 -t 15 -pix_fmt yuv420p $outputPath';
        final session = await FFmpegKit.execute(cmd);
        final state =
            FFmpegKitConfig.sessionStateToString(await session.getState());
        final returnCode = await session.getReturnCode();
        final failStackTrace = await session.getFailStackTrace();
        final duration = await session.getDuration();
        final output = await session.getOutput();
        final logs = await session.getAllLogsAsString();
        if (returnCode?.isValueSuccess() ?? false) {
          // SUCCESS
          print("-----> FFMPEG SUCCESS : ${outputPath}");
          return outputPath;
        } else if (returnCode?.isValueCancel() ?? false) {
          // CANCEL
          print("-----> FFMPEG CANCELLED");
          return outputPath;
        } else {
          // ERROR
          print("-----> FFMPEG ERROR : ${logs} , =====> ${duration}");
          return outputPath;
        }
      } catch (e) {
        print("ERROR ---------> $e");
      }
      return outputPath;
    });
  }

  // _sendClipToTapiocaBall() async {
  //   try {
  //     final tapiocaBalls = [
  //       TapiocaBall.filter(Filters.pink, 0.2),
  //       TapiocaBall.textOverlay("text", 100, 10, 100, Color(0xffffc0cb)),
  //     ];
  //     var tempDir = await getTemporaryDirectory();
  //     final path = '${tempDir.path}/result.mp4';
  //     print("CUPPING $path");
  //     final cup = Cup(Content(clips.first.mediaPath), tapiocaBalls);
  //     print("CUPPED.....");
  //     cup.suckUp(path).then((value) {
  //       MaterialPageRoute(builder: (context) => VideoScreen(path));
  //     }).catchError((e) {
  //       print("CUPP ERROR -----> $e");
  //     });
  //   } catch (err) {
  //     print("ERROR ------> $err");
  //   }
  // }

  sendClipsToVideoEditorSDK() async {
    try {
      // await cameraController.pausePreview();
      // await Navigator.push(
      //     context,
      //     MaterialPageRoute(
      //         builder: (_) => VideoClipsEditor(
      //               clips: clips,
      //             )));
      // ScaffoldMessenger.of(context)
      //     .showSnackBar(const SnackBar(content: Text("Please wait")));
      // final downloadedAudioFile = await _download(
      //     "https://file-examples.com/storage/fe863385e163e3b0f92dc53/2017/11/file_example_MP3_1MG.mp3",
      //     "Sneekpeak_anthem.mp3");
      // final audioOptions = im.AudioOptions(
      //   categories: [
      //     im.AudioClipCategory("Anthem", "SneekPeek Anthem",
      //         items: [im.AudioClip('S Anthem', downloadedAudioFile)]),
      //   ],
      // );
      final video = Video.composition(
          videos: clips
              .map(
                (e) => e.mediaPath,
              )
              .toList());
      final result = await VESDK.openEditor(
        video,
      );
      if (result != null) {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => VideoPreviewScreen(editorResult: result)));
      } else {
        return;
      }
      //
      // await cameraController.resumePreview();
    } catch (e) {
      print(e);
    }
  }

  Future<String> _download(String url, String filename) async {
    final client = HttpClient();
    final request = await client.getUrl(Uri.parse(url));
    final response = await request.close();
    final bytes = await consolidateHttpClientResponseBytes(response);
    final outputDirectory = await getTemporaryDirectory();
    final outputFile = File("${outputDirectory.path}/$filename");
    await outputFile.writeAsBytes(bytes);
    return outputFile.path;
  }
}

class CamPreviewWidget extends StatelessWidget {
  CameraController cameraController;

  CamPreviewWidget({required this.cameraController, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final scale = 1 /
        (cameraController.value.aspectRatio *
            MediaQuery.of(context).size.aspectRatio);
    return Transform.scale(
      scale: scale,
      alignment: Alignment.topCenter,
      child: CameraPreview(cameraController),
    );
  }
}

class ShutterButton extends StatelessWidget {
  double percent;
  bool isRecording;
  double alreadyDonePercent;

  ShutterButton(
      {required this.percent,
      required this.alreadyDonePercent,
      required this.isRecording,
      Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 70,
      width: 70,
      child: Stack(
        children: [
          Center(
            child: Container(
              height: 60,
              width: 60,
              child: isRecording
                  ? Icon(
                      Icons.square_rounded,
                      size: 25,
                      color: Theme.of(context).errorColor,
                    )
                  : const Icon(
                      Icons.circle,
                      size: 60,
                      color: Colors.white,
                    ),
            ),
          ),
          Center(
            child: SizedBox(
              height: 70,
              width: 70,
              child: TweenAnimationBuilder<double>(
                builder: (context, value, child) => CircularProgressIndicator(
                  value: value,
                  backgroundColor: Colors.grey[100],
                  valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).primaryColor),
                ),
                duration: Duration(milliseconds: alreadyDonePercent.toInt()),
                tween: Tween<double>(
                    begin: alreadyDonePercent / 100, end: percent / 100),
              ),
            ),
          )
        ],
      ),
    );
  }
}

class VideoPreviewScreen extends StatefulWidget {
  VideoEditorResult editorResult;

  VideoPreviewScreen({required this.editorResult, Key? key}) : super(key: key);

  @override
  State<VideoPreviewScreen> createState() => _VideoPreviewScreenState();
}

class _VideoPreviewScreenState extends State<VideoPreviewScreen> {
  late VideoPlayerController videoPlayerController;
  late Future videoInitialisation;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    initVideoPlayer();
  }

  initVideoPlayer() async {
    print("VIDEO PATH ----> ${widget.editorResult.video.substring(7)}");
    videoPlayerController = VideoPlayerController.file(
        File(widget.editorResult.video.substring(7)));
    videoInitialisation = videoPlayerController.initialize().then((value) {
      if (mounted) {
        setState(() {});
      }
    });
    videoPlayerController.setLooping(true);
    videoPlayerController.play();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Video Preview"),
      ),
      body: Stack(
        children: [
          SizedBox.expand(
            child: FutureBuilder<dynamic>(
                future: videoInitialisation,
                builder: (context, snapshot) {
                  return FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: videoPlayerController.value.size.width ?? 0,
                      height: videoPlayerController.value.size.height ?? 0,
                      child: VideoPlayer(videoPlayerController),
                    ),
                  );
                }),
          ),
          Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.all(30),
              child: GestureDetector(
                onTap: () {},
                child: const CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Icon(Icons.mic),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}

class SPClip {
  String mediaPath;
  int durationInSecs;
  String? recordedPath;

  SPClip(
      {required this.mediaPath,
      this.recordedPath,
      required this.durationInSecs});
}

class VideoScreen extends StatefulWidget {
  final String path;

  VideoScreen(this.path);

  @override
  _VideoAppState createState() => _VideoAppState(path);
}

class _VideoAppState extends State<VideoScreen> {
  final String path;

  _VideoAppState(this.path);

  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(File(path))
      ..initialize().then((_) {
        // Ensure the first frame is shown after the video is initialized, even before the play button has been pressed.
        setState(() {});
      });
    _controller.addListener(() {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Video Duration in Seconds : ${_controller.value.duration.inSeconds}"),
      ),
      body: Center(
        child: _controller.value.isInitialized
            ? AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              )
            : Container(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            if (!_controller.value.isPlaying &&
                _controller.value.isInitialized &&
                (_controller.value.duration == _controller.value.position)) {
              _controller.initialize();
              _controller.play();
            } else {
              _controller.value.isPlaying
                  ? _controller.pause()
                  : _controller.play();
            }
          });
        },
        child: Icon(
          _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.removeListener(() {});
    _controller.dispose();
    super.dispose();
  }
}

class PictureToVideoLoaderScreen extends StatelessWidget {
  const PictureToVideoLoaderScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Center(
            child: Text("Converting the images into video"),
          ),
          SizedBox(
            height: 10,
          ),
          SizedBox(
            width: 100,
            child: LinearProgressIndicator(),
          )
        ],
      ),
    );
  }
}

class VideoClipsEditor extends StatefulWidget {
  List<SPClip> clips;

  VideoClipsEditor({required this.clips, Key? key}) : super(key: key);

  @override
  State<VideoClipsEditor> createState() => _VideoClipsEditorState();
}

class _VideoClipsEditorState extends State<VideoClipsEditor> {
  List<VideoEditorController> _controllers = [];
  VideoEditorController? _currentController;
  FlutterSoundRecorder fSoundRecorder = FlutterSoundRecorder();
  StreamSubscription? dispositionStream;
  SPClip? currentRecordingClip;
  bool isRecording = false;
  int audioRecordingSecs = 0;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _initEditor();
    _initRecorder();
  }

  _initEditor() async {
    for (var value in widget.clips) {
      print("PATH ---> ${value.mediaPath}");
      final c = VideoEditorController.file(File(value.mediaPath),
          maxDuration: Duration(seconds: value.durationInSecs));
      _controllers.add(c);
      await c.initialize();
      c.addListener(() {
        if (c.isTrimming) {
          _currentController = c;
          currentRecordingClip = widget.clips
              .where((element) =>
                  element.mediaPath == _currentController!.file.path)
              .first;
          setState(() {});
        }
      });
    }
    if (_controllers.isNotEmpty) {
      _currentController = _controllers.first;
    }
    setState(() {});
  }

  _initRecorder() async {
    try {
      fSoundRecorder =
          await fSoundRecorder.openAudioSession() ?? fSoundRecorder;
    } catch (e) {
      print("Error initialising the recorder");
    }
  }

  _addVideosToEditorSDK() async {
    try {
      // ScaffoldMessenger.of(context)
      //     .showSnackBar(const SnackBar(content: Text("Please wait")));
      // final downloadedAudioFile = await _download(
      //     "https://file-examples.com/storage/fe863385e163e3b0f92dc53/2017/11/file_example_MP3_1MG.mp3",
      //     "Sneekpeak_anthem.mp3");
      // final audioOptions = im.AudioOptions(
      //   categories: [
      //     im.AudioClipCategory("Anthem", "SneekPeek Anthem",
      //         items: [im.AudioClip('S Anthem', downloadedAudioFile)]),
      //   ],
      // );
      // final video = Video.composition(
      //     videos: widget.clips
      //         .map(
      //           (e) => e.mediaPath,
      //         )
      //         .toList());
      // final result = await VESDK.openEditor(video,
      //     configuration: im.Configuration(
      //       // audio: audioOptions,
      //       composition: im.CompositionOptions(
      //         personalVideoClips: false,
      //       ),
      //     ));
      // if (result != null) {
      //   Navigator.push(
      //       context,
      //       MaterialPageRoute(
      //           builder: (_) => VideoPreviewScreen(editorResult: result)));
      // } else {
      //   return;
      // }
    } catch (e) {
      print(e);
    }
  }

  startRecordingVoiceOver() async {
    try {
      audioRecordingSecs = 0;
      var recordingPath = await createFolder('Voiceovers SneakPeek');
      recordingPath +=
          "/local_voiceover_${DateTime.now().millisecondsSinceEpoch}.aac";
      await fSoundRecorder.startRecorder(
          codec: Codec.aacADTS, toFile: recordingPath);
      isRecording = true;
      setState(() {});
      fSoundRecorder.onProgress?.listen((event) {
        print("RECORDING :: ${event.duration.inSeconds}");
        audioRecordingSecs += event.duration.inSeconds;
        if (currentRecordingClip != null) {
          if (event.duration.inSeconds >=
              currentRecordingClip!.durationInSecs) {
            stopRecordingVoiceOver();
          }
        }
      });
    } catch (e) {
      print("Error starting recorder : $e");
    }
  }

  stopRecordingVoiceOver() async {
    dispositionStream?.cancel();
    try {
      final recordingPath = await fSoundRecorder.stopRecorder();
      currentRecordingClip?.recordedPath = recordingPath;
      if (widget.clips
          .where(
              (element) => element.mediaPath == currentRecordingClip?.mediaPath)
          .isNotEmpty) {
        widget.clips
            .where((element) =>
                element.mediaPath == currentRecordingClip?.mediaPath)
            .first
            .recordedPath = currentRecordingClip?.recordedPath;
      }
    } catch (e) {
      print("Error saving recorder : $e");
    }
    isRecording = false;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text("Video Editor")),
        body: _currentController == null
            ? const Center(
                child: CupertinoActivityIndicator(),
              )
            : Column(
                children: [
                  Expanded(
                    child: Stack(
                      children: [
                        SizedBox.expand(
                          child: FittedBox(
                            fit: BoxFit.cover,
                            child: SizedBox(
                              width:
                                  _currentController?.video.value.size.width ??
                                      0,
                              height:
                                  _currentController?.video.value.size.height ??
                                      0,
                              child: VideoPlayer(_currentController!.video),
                            ),
                          ),
                        ),
                        Center(
                          child: AnimatedBuilder(
                            animation: _currentController!.video,
                            builder: (_, __) => AnimatedOpacity(
                              opacity: !_currentController!.isPlaying ? 1 : 0,
                              duration: Duration(milliseconds: 200),
                              child: GestureDetector(
                                onTap: _currentController!.video.play,
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.play_arrow,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                      height: 100,
                      child: Row(
                        children: [
                          for (var i = 0; i < _controllers.length; i++)
                            Expanded(
                                child: TrimSlider(controller: _controllers[i])),
                          const SizedBox(
                            width: 10,
                          )
                        ],
                      )),
                  if (currentRecordingClip != null) ...[
                    GestureDetector(
                      onTap: () {
                        if (isRecording) {
                          stopRecordingVoiceOver();
                        } else {
                          startRecordingVoiceOver();
                        }
                      },
                      child: ShutterButton(
                        alreadyDonePercent:
                            ((currentRecordingClip!.durationInSecs) -
                                audioRecordingSecs * 100),
                        percent: audioRecordingSecs /
                            currentRecordingClip!.durationInSecs *
                            100,
                        isRecording: isRecording,
                      ),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                  ]
                ],
              ));
  }
}

// class CustomGalleryView extends StatefulWidget {
//   List<AssetEntity> assets;
//
//   CustomGalleryView({required this.assets, Key? key}) : super(key: key);
//
//   @override
//   State<CustomGalleryView> createState() => _CustomGalleryViewState();
// }
//
// class _CustomGalleryViewState extends State<CustomGalleryView> {
//   List<AssetEntity> selectedAssets = [];
//
//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         Expanded(
//           child: widget.assets.isNotEmpty
//               ? GridView.builder(
//                   gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//                       crossAxisCount: 3,
//                       crossAxisSpacing: 10,
//                       mainAxisSpacing: 10),
//                   itemCount: widget.assets.length + 1,
//                   itemBuilder: (context, index) => Container(
//                     decoration: BoxDecoration(
//                         borderRadius: BorderRadius.circular(10),
//                         color: Colors.grey),
//                     child: index == 0
//                         ? const Center(
//                             child: Icon(Icons.camera_alt),
//                           )
//                         : ClipRRect(
//                             borderRadius: BorderRadius.circular(10),
//                             child: AssetWidget(
//                               assetEntity: widget.assets[index - 1],
//                               onChanged: (v) {
//                                 setState(() {
//                                   if (selectedAssets
//                                       .where((element) =>
//                                           element.id ==
//                                           widget.assets[index - 1].id)
//                                       .isEmpty) {
//                                     selectedAssets
//                                         .add(widget.assets[index - 1]);
//                                   } else {
//                                     selectedAssets
//                                         .remove(widget.assets[index - 1]);
//                                   }
//                                 });
//                               },
//                               isSelected: selectedAssets
//                                   .contains(widget.assets[index - 1]),
//                             ),
//                           ),
//                   ),
//                 )
//               : const Center(
//                   child: Text("No Assets found"),
//                 ),
//         ),
//         Center(
//           child: ElevatedButton(
//             child: Text("Choose ${selectedAssets.length} clips"),
//             onPressed: () {
//               Navigator.pop(context, selectedAssets);
//             },
//           ),
//         )
//       ],
//     );
//   }
// }
//
// class AssetWidget extends StatelessWidget {
//   AssetEntity assetEntity;
//   void Function(bool?)? onChanged;
//   bool isSelected;
//
//   AssetWidget(
//       {required this.assetEntity,
//       required this.onChanged,
//       this.isSelected = false,
//       Key? key})
//       : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return Stack(
//       children: [
//         FutureBuilder(
//           builder: (context, snapshot) {
//             if (snapshot.connectionState == ConnectionState.waiting) {
//               return const Center(
//                 child: CupertinoActivityIndicator(),
//               );
//             } else if (snapshot.connectionState == ConnectionState.done &&
//                 snapshot.data != null) {
//               return Image.memory(
//                 snapshot.data!,
//                 height: double.infinity,
//                 width: double.infinity,
//                 fit: BoxFit.cover,
//               );
//             } else {
//               return const Center(
//                 child: Icon(Icons.error_outline),
//               );
//             }
//           },
//           future: assetEntity.thumbnailData,
//         ),
//         Align(
//           alignment: Alignment.bottomRight,
//           child: Padding(
//             padding: const EdgeInsets.all(5.0),
//             child: Checkbox(
//               onChanged: onChanged,
//               value: isSelected,
//             ),
//           ),
//         )
//       ],
//     );
//   }
// }

Future<String> createFolder(String folder) async {
  final folderName = folder;
  final dirpath = await getApplicationDocumentsDirectory();
  final path = Directory(dirpath.path + "/$folderName");
  print("WATCHING THE FOLDER AT :${path.path}");
  var status = await Permission.storage.status;
  if (!status.isGranted) {
    await Permission.storage.request();
  }
  if ((!await path.exists())) {
    print("CREATING THE FOLDER AT :${path.path}");
    path.create(recursive: true);
    print("CREATED THE FOLDER AT :${path.path}");
    return path.path;
  }
  print("RETURNING THE FOLDER AT :${path.path}");
  return path.path;
}
