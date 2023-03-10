// import 'dart:async';
// import 'package:flutter_cache_manager/flutter_cache_manager.dart';
// import 'package:video_editor/video_editor.dart';
// import 'package:camera/camera.dart';
// import 'package:flutter/material.dart';
// import 'package:video_editor_sdk/video_editor_sdk.dart';
// import 'package:video_recording_sp/editor_video.dart';
// import 'package:video_recording_sp/main.dart';
//
// class FFMPEGDemo extends StatelessWidget {
//   const FFMPEGDemo({Key? key}) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return const FFmpegVideoRecordingScreen();
//   }
// }
//
// class FFmpegVideoRecordingScreen extends StatefulWidget {
//   const FFmpegVideoRecordingScreen({Key? key}) : super(key: key);
//
//   @override
//   State<FFmpegVideoRecordingScreen> createState() =>
//       _FFmpegVideoRecordingScreenState();
// }
//
// class _FFmpegVideoRecordingScreenState
//     extends State<FFmpegVideoRecordingScreen> {
//   late CameraController cameraController;
//   bool _isLoadingCamera = true;
//   bool isRecording = false;
//   Timer? _timer;
//   int totalRecordingDurationInSecs = 0;
//   int lastDurationInSecs = 0;
//   int maxPeekRecordingSecs = 20;
//   List<FFMPEGClip> clips = [];
//   late List<CameraDescription> cams;
//   bool isLoading = false;
//
//   @override
//   void initState() {
//     // TODO: implement initState
//     super.initState();
//     // _getCameraDescription();
//   }
//
//   _getCameraDescription() async {
//     cams = await availableCameras();
//     if (cams.isNotEmpty) {
//       _initCamera(cams.first);
//     }
//   }
//
//   _initCamera(CameraDescription description) async {
//     try {
//       print(cams.length);
//       cameraController = CameraController(
//         description,
//         ResolutionPreset.max,
//         enableAudio: true,
//         imageFormatGroup: ImageFormatGroup.jpeg,
//       );
//       await cameraController.initialize();
//       cameraController.addListener(() {
//         setState(() {
//           isRecording = cameraController.value.isRecordingVideo;
//         });
//       });
//       setState(() {
//         _isLoadingCamera = false;
//       });
//       print("Done");
//     } catch (e) {
//       print(e);
//     }
//   }
//
//   undoClip() async {
//     totalRecordingDurationInSecs -= clips.last.durationInSecs;
//     clips.removeLast();
//     debugPrint(totalRecordingDurationInSecs.toString());
//     setState(() {});
//   }
//
//   bool get isUndoAvailable => clips.isNotEmpty && !isRecording;
//
//   _switchCam() async {
//     final lensDirection = cameraController.description.lensDirection;
//     CameraDescription newDescription;
//     if (lensDirection == CameraLensDirection.front) {
//       newDescription = cams.firstWhere((description) =>
//           description.lensDirection == CameraLensDirection.back);
//     } else {
//       newDescription = cams.firstWhere((description) =>
//           description.lensDirection == CameraLensDirection.front);
//     }
//     _initCamera(newDescription);
//   }
//
//   startRecording() async {
//     try {
//       await cameraController.startVideoRecording(
//         onAvailable: (image) {
//           debugPrint("Video Stream Available");
//         },
//       );
//       lastDurationInSecs = 0;
//       startTimer();
//     } catch (e) {
//       print(e);
//     }
//   }
//
//   stopRecording() async {
//     try {
//       final recordRes = await cameraController.stopVideoRecording();
//       clips.add(FFMPEGClip(
//           mediaPath: recordRes.path, durationInSecs: lastDurationInSecs));
//       stopTimer();
//       setState(() {});
//       print("TOTAL STEPS => ${clips.length}");
//     } catch (e) {
//       print("ERROR ---------- > $e");
//       stopTimer();
//       lastDurationInSecs = 0;
//       totalRecordingDurationInSecs = 0;
//       setState(() {
//         isRecording = false;
//       });
//       _getCameraDescription();
//     }
//   }
//
//   startTimer() {
//     if (_timer != null) _timer?.cancel();
//     _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
//       totalRecordingDurationInSecs++;
//       lastDurationInSecs++;
//       if (totalRecordingDurationInSecs == maxPeekRecordingSecs) {
//         stopRecording();
//       }
//       setState(() {});
//     });
//   }
//
//   stopTimer() {
//     if (_timer != null && _timer!.isActive) _timer?.cancel();
//     setState(() {});
//   }
//
//   downloadVideo() async {
//     isLoading = true;
//     setState(() {});
//     print("loading");
//     final cachedVideo = await DefaultCacheManager().getSingleFile(
//         "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerFun.mp4");
//     print("Done");
//     final cachedVideo1 = await DefaultCacheManager().getSingleFile(
//         "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/WeAreGoingOnBullrun.mp4");
//     print("Done");
//     setState(() {
//       isLoading = false;
//     });
//     Navigator.push(context, MaterialPageRoute(builder: (_)=>SPVideoEditor(videoPath: [
//       FFMPEGClip(mediaPath: cachedVideo.path, durationInSecs: 60),
//       FFMPEGClip(mediaPath: cachedVideo1.path, durationInSecs: 47),
//     ])));
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Center(
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             TextButton(
//                 onPressed: () async {
//                   await downloadVideo();
//                 },
//                 child: Text(isLoading ? "Loading..." : "Video 1")),
//             // SizedBox(
//             //   height: 10,
//             // ),
//             // ElevatedButton(onPressed: () {}, child: Text("Video 2")),
//           ],
//         ),
//       ),
//     );
//     // final size = MediaQuery
//     //     .of(context)
//     //     .size;
//     // final deviceRatio = size.width / size.height;
//     // return Scaffold(
//     //   backgroundColor: Colors.black26,
//     //   floatingActionButton: GestureDetector(
//     //     onTap: () {
//     //       if (totalRecordingDurationInSecs < maxPeekRecordingSecs) {
//     //         if (isRecording) {
//     //           stopRecording();
//     //         } else {
//     //           startRecording();
//     //         }
//     //       }
//     //     },
//     //     child: Row(
//     //       children: [
//     //         if (isUndoAvailable) ...[
//     //           const SizedBox(
//     //             width: 10,
//     //           ),
//     //           IconButton(
//     //               onPressed: () {
//     //                 undoClip();
//     //               },
//     //               icon: Icon(Icons.refresh)),
//     //         ],
//     //         const Spacer(),
//     //         FFmpegShutterButton(
//     //             isRecording: isRecording,
//     //             alreadyDonePercent: ((maxPeekRecordingSecs -
//     //                 (clips.fold(
//     //                     0,
//     //                         (value, element) =>
//     //                     value + element.durationInSecs))) *
//     //                 100),
//     //             percent:
//     //             totalRecordingDurationInSecs / maxPeekRecordingSecs * 100),
//     //         const Spacer(),
//     //         if (!isRecording) ...[
//     //           CircleAvatar(
//     //             child: IconButton(
//     //                 onPressed: () {
//     //                   _switchCam();
//     //                 },
//     //                 icon: const Icon(Icons.switch_camera)),
//     //           ),
//     //           const SizedBox(
//     //             width: 10,
//     //           ),
//     //         ],
//     //       ],
//     //     ),
//     //   ),
//     //   floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
//     //   body: SafeArea(
//     //     child: Stack(
//     //       children: [
//     //         if (_isLoadingCamera) ...[
//     //           const Center(
//     //             child: Text("Loading Cams"),
//     //           ),
//     //         ] else
//     //           ...[
//     //             Transform.scale(
//     //               scale: cameraController.value.aspectRatio / deviceRatio,
//     //               child: FFmpegCamPreviewWidget(
//     //                 cameraController: cameraController,
//     //               ),
//     //             ),
//     //           ],
//     //         if (isUndoAvailable) ...[
//     //           Align(
//     //             alignment: Alignment.topRight,
//     //             child: Padding(
//     //               padding:
//     //               const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
//     //               child: ElevatedButton(
//     //                   onPressed: sendClipsToVideoEditorSDK,
//     //                   child: const Text("Next")),
//     //             ),
//     //           ),
//     //         ]
//     //       ],
//     //     ),
//     //   ),
//     // );
//   }
//
//   sendClipsToVideoEditorSDK() async {
//     Navigator.of(context).push(
//         MaterialPageRoute(builder: (_) => SPVideoEditor(videoPath: clips)));
//   }
// }
//
// class FFmpegCamPreviewWidget extends StatelessWidget {
//   CameraController cameraController;
//
//   FFmpegCamPreviewWidget({required this.cameraController, Key? key})
//       : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return CameraPreview(
//       cameraController,
//     );
//   }
// }
//
// class FFmpegShutterButton extends StatelessWidget {
//   double percent;
//   bool isRecording;
//   double alreadyDonePercent;
//
//   FFmpegShutterButton(
//       {required this.percent,
//       required this.alreadyDonePercent,
//       required this.isRecording,
//       Key? key})
//       : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return SizedBox(
//       height: 70,
//       width: 70,
//       child: Stack(
//         children: [
//           Center(
//             child: Container(
//               height: 60,
//               width: 60,
//               child: isRecording
//                   ? Icon(
//                       Icons.square_rounded,
//                       size: 25,
//                       color: Theme.of(context).errorColor,
//                     )
//                   : const Icon(
//                       Icons.circle,
//                       size: 60,
//                       color: Colors.white,
//                     ),
//             ),
//           ),
//           Center(
//             child: SizedBox(
//               height: 70,
//               width: 70,
//               child: TweenAnimationBuilder<double>(
//                 builder: (context, value, child) => CircularProgressIndicator(
//                   value: value,
//                   backgroundColor: Colors.grey[100],
//                   valueColor: AlwaysStoppedAnimation<Color>(
//                       Theme.of(context).errorColor),
//                 ),
//                 duration: const Duration(milliseconds: 100),
//                 tween: Tween<double>(
//                     begin: alreadyDonePercent / 100, end: percent / 100),
//               ),
//             ),
//           )
//         ],
//       ),
//     );
//   }
// }
//
// class FFMPEGClip {
//   String mediaPath;
//   int durationInSecs;
//
//   FFMPEGClip({required this.mediaPath, required this.durationInSecs});
// }
