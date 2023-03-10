import 'package:flutter_test/flutter_test.dart';
import 'package:dual_camera/dual_camera.dart';
import 'package:dual_camera/dual_camera_platform_interface.dart';
import 'package:dual_camera/dual_camera_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockDualCameraPlatform
    with MockPlatformInterfaceMixin
    implements DualCameraPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');

  @override
  Future<bool?> pauseRecording() {
    // TODO: implement pauseRecording
    throw UnimplementedError();
  }

  @override
  Future<bool?> startRecording() {
    // TODO: implement startRecording
    throw UnimplementedError();
  }

  @override
  Future<String?> stopRecording() {
    // TODO: implement stopRecording
    throw UnimplementedError();
  }
}

void main() {
  final DualCameraPlatform initialPlatform = DualCameraPlatform.instance;

  test('$MethodChannelDualCamera is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelDualCamera>());
  });

  test('getPlatformVersion', () async {
    DualCamera dualCameraPlugin = DualCamera();
    MockDualCameraPlatform fakePlatform = MockDualCameraPlatform();
    DualCameraPlatform.instance = fakePlatform;

    expect(await dualCameraPlugin.getPlatformVersion(), '42');
  });
}
