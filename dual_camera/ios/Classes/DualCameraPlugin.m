#import "DualCameraPlugin.h"
#if __has_include(<dual_camera/dual_camera-Swift.h>)
#import <dual_camera/dual_camera-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "dual_camera-Swift.h"
#endif

@implementation DualCameraPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftDualCameraPlugin registerWithRegistrar:registrar];
}
@end
