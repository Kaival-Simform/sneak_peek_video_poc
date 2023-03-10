// import 'dart:io';
// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:video_editor/video_editor.dart';
// import 'package:video_player/video_player.dart';
// import 'package:video_recording_sp/ffmpeg_demo.dart';
// import 'package:video_recording_sp/main.dart';
//
// class SPVideoEditor extends StatefulWidget {
//   List<FFMPEGClip> videoPath;
//
//   SPVideoEditor({required this.videoPath, Key? key}) : super(key: key);
//
//   @override
//   State<SPVideoEditor> createState() => _SPVideoEditorState();
// }
//
// class _SPVideoEditorState extends State<SPVideoEditor> {
//   List<VideoEditorController> _controllers = [];
//   VideoEditorController? _currentController;
//
//   @override
//   void initState() {
//     // TODO: implement initState
//     super.initState();
//     _initEditor();
//   }
//
//   _initEditor() async {
//     for (var value in widget.videoPath) {
//       print("DURATION ---> ${value.durationInSecs}");
//       final c = VideoEditorController.file(File(value.mediaPath),
//           maxDuration: Duration(seconds: value.durationInSecs));
//       _controllers.add(c);
//       await c.initialize();
//       c.addListener(() {
//         if(c.isTrimming){
//           _currentController=c;
//           setState(() {
//
//           });
//         }
//       });
//     }
//     if (_controllers.isNotEmpty) {
//       _currentController = _controllers.first;
//     }
//     setState(() {});
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//         appBar: AppBar(title: Text("Video Editor")),
//         body:_currentController==null? Center(
//           child: CupertinoActivityIndicator(),
//         ): Column(
//           children: [
//             Expanded(
//               child: Stack(
//                 children: [
//                   SizedBox.expand(
//                     child: FittedBox(
//                       fit: BoxFit.cover,
//                       child: SizedBox(
//                         width: _currentController?.video.value.size.width ?? 0,
//                         height: _currentController?.video.value.size.height ?? 0,
//                         child: VideoPlayer(_currentController!.video),
//                       ),
//                     ),
//                   ),
//                   Center(
//                     child: AnimatedBuilder(
//                       animation: _currentController!.video,
//                       builder: (_, __) => AnimatedOpacity(
//                         opacity: !_currentController!.isPlaying ? 1 : 0,
//                         duration: Duration(milliseconds: 200),
//                         child: GestureDetector(
//                           onTap: _currentController!.video.play,
//                           child: Container(
//                             width: 40,
//                             height: 40,
//                             decoration: const BoxDecoration(
//                               color: Colors.white,
//                               shape: BoxShape.circle,
//                             ),
//                             child: const Icon(
//                               Icons.play_arrow,
//                               color: Colors.black,
//                             ),
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             Container(
//                 height: 100,
//                 child: Row(
//                   children: [
//                     for (var i = 0; i < _controllers.length; i++)
//                       Expanded(child: TrimSlider(controller: _controllers[i])),
//                     const SizedBox(
//                       width: 10,
//                     )
//                   ],
//                 ))
//           ],
//         ));
//   }
// }
