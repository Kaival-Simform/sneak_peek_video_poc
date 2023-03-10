import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dual_camera/dual_camera_method_channel.dart';

void main() {
  MethodChannelDualCamera platform = MethodChannelDualCamera();
  const MethodChannel channel = MethodChannel('dual_camera');

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '42';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('getPlatformVersion', () async {
    expect(await platform.getPlatformVersion(), '42');
  });
}
