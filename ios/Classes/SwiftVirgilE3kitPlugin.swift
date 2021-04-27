import Flutter
import UIKit

public class SwiftVirgilE3kitPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "com.virgilsecurity/ethree", binaryMessenger: registrar.messenger())
        let instance = SwiftVirgilE3kitPlugin(channel: channel, messenger: registrar.messenger())
        registrar.addMethodCallDelegate(instance, channel: channel)
  }
    
    let channel: FlutterMethodChannel
    let messenger: FlutterBinaryMessenger
    var ethreeWrappers: [String: EThreeWrapper] = [:]
    
    init(channel: FlutterMethodChannel, messenger: FlutterBinaryMessenger) {
        self.channel = channel
        self.messenger = messenger
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "init":
            guard
                let arguments = call.arguments as? [String: Any],
                let channelID: String = arguments["channelID"] as? String,
                let identity: String = arguments["identity"] as? String
            else {
                return result(FlutterError(code: "-1", message: "can't get arguments", details: nil))
            }
            
            do {
                self.ethreeWrappers[channelID] = try EThreeWrapper.init(methodChannelID: channelID, messenger: self.messenger, identity: identity)
            } catch let error {
                return result(FlutterError(code: "-1", message: "can't init ethree", details: error.localizedDescription))
            }
            
            return result(true)
        default:
          return result(FlutterError(code: "-1", message: "method not implemented"+call.method, details: nil))
        }
  }
}
