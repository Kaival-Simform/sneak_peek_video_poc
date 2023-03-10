import Flutter
import UIKit

public class SwiftDualCameraPlugin: NSObject, FlutterPlugin {
    var factory: FLNativeViewFactory?

    init(registrar: FlutterPluginRegistrar, flutterChannel: FlutterMethodChannel) {
            super.init()
        }

    public static func register(with registrar: FlutterPluginRegistrar) {
        factory = FLNativeViewFactory(messenger: registrar.messenger())
        print("INIT FACTORY")

        registrar.register(
            factory,
            withId: "dual_camera_view")
        print("FACTORY DONE")
        let channel = FlutterMethodChannel(name: "dual_camera", binaryMessenger: registrar.messenger())
        let instance = SwiftDualCameraPlugin(registrar: registrar, flutterChannel: channel)
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method{
        case "startRecording":
            factory.viewController.toggleMovieRecording();
            if(factory.viewController.movieRecorder?.isRecording ?? false){
                result(1);
            }
            else{
                result(0);
            }
            break
        case "stopRecording":
            factory.viewController.movieRecorder?.stopRecording{ movieURL in
                self.returnMovieToFlutter(movieURL)
                
            }
            break
        case "pauseRecording":
            factory.viewController.movieRecorder?.stopRecording{ movieURL in
                self.returnMovieToFlutter(movieURL)
                
            }
            break
        default:
            result(FlutterMethodNotImplemented)
            break
        }
    }
}
func returnMovieToFlutter(_ movieURL: URL){

}
