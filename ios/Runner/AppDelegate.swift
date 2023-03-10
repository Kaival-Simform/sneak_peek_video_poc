import UIKit
import Flutter

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]?
    ) -> Bool {
        GeneratedPluginRegistrant.register(with: self)
        
        weak var registrar = self.registrar(forPlugin: "plugin-name")

        let factory = FLNativeViewFactory(messenger: registrar!.messenger())



        self.registrar(forPlugin: "<plugin-name>")!.register(
            factory,
            withId: "<platform-view-type>")
        let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
        let cameraChannel = FlutterMethodChannel(name: "sneakpeek-camera",
                                                  binaryMessenger: controller.binaryMessenger);
        cameraChannel.setMethodCallHandler({
           (call: FlutterMethodCall, result: FlutterResult) -> Void in
          // This method is invoked on the UI thread.
            let methodCaller = call.method;
            if(methodCaller=="startRecording"){
                print("START RECORDING");
                factory.viewController.toggleMovieRecording();
                if(factory.viewController.movieRecorder?.isRecording ?? false){
                    result(1);
                }
                else{
                    result(0);
                }
          }
            else if(methodCaller=="stopRecording"){
                factory.viewController.movieRecorder?.stopRecording{ movieURL in
                    self.returnMovietoFlutter(movieURL)

                }
            }
            else{
                result(FlutterMethodNotImplemented)
                return;
            }
        })

       
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
        
        //         GeneratedPluginRegistrant.register(with: self)
        //
        //         weak var registrar = self.registrar(forPlugin: "plugin-name")
        //
        //         let factory = FLNativeViewFactory(messenger: registrar!.messenger())
        //
        //         DispatchQueue.main.asyncAfter(deadline: .now()+1, execute:{
        //             factory.viewController.toggleMovieRecording();
        //             print("STARTING QUEUE")
        //         });
        //
        //         DispatchQueue.main.asyncAfter(deadline: .now()+7, execute:{
        //             factory.viewController.toggleMovieRecording();
        //             print("DONE QUEUE")
        //         });
        //
        //         self.registrar(forPlugin: "<plugin-name>")!.register(
        //             factory,
        //             withId: "<platform-view-type>")
        //         return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    func returnMovietoFlutter(_ movieURL: URL){
        
    }
}

