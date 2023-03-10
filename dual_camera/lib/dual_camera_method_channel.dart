import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'dual_camera_platform_interface.dart';

/// An implementation of [DualCameraPlatform] that uses method channels.
class MethodChannelDualCamera extends DualCameraPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('dual_camera');

  @override
  Future<String?> getPlatformVersion() async {
    final version =
        await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }

  @override
  Future<bool> startRecording() async {
    final result = await methodChannel.invokeMethod<int>('startRecording');
    return result is int && result == 1;
  }

  @override
  Future<String?> stopRecording() async {
    final result = await methodChannel.invokeMethod<String>('stopRecording');
    return result;
  }

  @override
  Future<bool> pauseRecording() async {
    final result = await methodChannel.invokeMethod<int>('pauseRecording');
    return result is int && result == 1;
  }
}
