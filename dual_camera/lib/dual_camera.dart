
import 'dual_camera_platform_interface.dart';

class DualCamera {
  Future<String?> getPlatformVersion() {
    return DualCameraPlatform.instance.getPlatformVersion();
  }
  Future<bool?> startRecording(){
    return DualCameraPlatform.instance.startRecording();
  }

  Future<String?> stopRecording() {
    return DualCameraPlatform.instance.stopRecording();
  }

  Future<void> pauseRecording(){
    return DualCameraPlatform.instance.pauseRecording();
  }
}
