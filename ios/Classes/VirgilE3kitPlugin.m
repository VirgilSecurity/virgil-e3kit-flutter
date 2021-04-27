#import "VirgilE3kitPlugin.h"
#if __has_include(<virgil_e3kit/virgil_e3kit-Swift.h>)
#import <virgil_e3kit/virgil_e3kit-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "virgil_e3kit-Swift.h"
#endif

@implementation VirgilE3kitPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftVirgilE3kitPlugin registerWithRegistrar:registrar];
}
@end
