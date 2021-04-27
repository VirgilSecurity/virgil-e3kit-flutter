import Foundation
import Flutter
import VirgilE3Kit
import VirgilSDK

enum EThreeError: Error {
    case InvalidParameter(key: String)
}

class EThreeWrapper {
    let methodChannel: FlutterMethodChannel
    var ethree: EThree
    
    init(methodChannelID: String, messenger: FlutterBinaryMessenger, identity: String) throws {
        let ethreeObj: EThree
        let methodChannelObj: FlutterMethodChannel = FlutterMethodChannel(name: methodChannelID, binaryMessenger: messenger)
        do {
            ethreeObj = try EThree.init(params: EThreeParams(identity: identity, tokenCallback: { completion in
                methodChannelObj.invokeMethod("tokenCallback", arguments: identity, result: { (data: Any) in
                    completion(data as? String, data as? Error)
                })
            }))
        } catch let error {
            throw error
        }
        
        self.ethree = ethreeObj
        self.methodChannel = methodChannelObj
        self.methodChannel.setMethodCallHandler(self.handle)
    }
    
    public func handle(call: FlutterMethodCall, result: @escaping FlutterResult) {
        func getArgument<T>(key: String) throws -> T {
            guard let arg = (call.arguments as? [String: Any])?[key] as? T else {
                throw(EThreeError.InvalidParameter(key: key))
            }
            
            return arg
        }
        
        do {
            switch call.method {
            case "getIdentity":
                self.getIdentity(result: result)
            case "register":
                self.register(result: result)
            case "unregister":
                self.unregister(result: result)
            case "backupPrivateKey":
                self.backupPrivateKey(password: try getArgument(key: "password"), result: result)
            case "changePassword":
                self.changePassword(oldPassword: try getArgument(key: "oldPassword"), newPassword: try getArgument(key: "newPassword"), result: result)
            case "resetPrivateKeyBackup":
                self.resetPrivateKeyBackup(result: result)
            case "restorePrivateKey":
                self.restorePrivateKey(password: try getArgument(key: "password"), result: result)
            case "rotatePrivateKey":
                self.rotatePrivateKey(result: result)
            case "hasLocalPrivateKey":
                self.hasLocalPrivateKey(result: result)
            case "cleanup":
                self.cleanup(result: result)
            case "findUser":
                self.findUser(identity: try getArgument(key: "identity"), result: result)
            case "findUsers":
                self.findUsers(identities: try getArgument(key: "identities"), result: result)
            case "findCachedUser":
                self.findCachedUser(identity: try getArgument(key: "identity"), result: result)
            case "findCachedUsers":
                self.findCachedUsers(identities: try getArgument(key: "identities"), result: result)
            case "updateCachedUsers":
                self.updateCachedUsers(result: result)
            case "authEncrypt":
                self.authEncrypt(data: try getArgument(key: "data"), users: try getArgument(key: "users"), result: result)
            case "authDecrypt":
                self.authDecrypt(data: try getArgument(key: "data"), cardStr: try getArgument(key: "card"), result: result)
            default:
                result(FlutterError(code: "-1", message: "method not implemented"+call.method, details: nil))
            }
        } catch let error {
            result(FlutterError(code: "-1", message: "error happened", details: error.localizedDescription))
        }
    }
    
    private func getIdentity(result: @escaping FlutterResult) {
        return result(self.ethree.identity)
    }
    
    private func register(result: @escaping FlutterResult) {
        self.ethree.register(completion: { error in
            if let error = error {
                return result(FlutterError(code: "2", message: "can't register user card", details: error.localizedDescription))
            }
            
            return result(true)
        })
    }
    
    private func unregister(result: @escaping FlutterResult) {
        self.ethree.unregister(completion: self.flutterCompletion(result: result, code: "3"))
    }
    
    private func backupPrivateKey(password: String, result: @escaping FlutterResult) {
        self.ethree.backupPrivateKey(password: password, completion: self.flutterCompletion(result: result, code: "4"))
    }
    
    private func changePassword(oldPassword: String, newPassword: String, result: @escaping FlutterResult) {
        self.ethree.changePassword(from: oldPassword, to: newPassword, completion: self.flutterCompletion(result: result, code: "5"))
    }
    
    private func resetPrivateKeyBackup(result: @escaping FlutterResult) {
        self.ethree.resetPrivateKeyBackup(completion: self.flutterCompletion(result: result, code: "6"))
    }
    
    private func restorePrivateKey(password: String, result: @escaping FlutterResult) {
        self.ethree.restorePrivateKey(password: password, completion: self.flutterCompletion(result: result, code: "7"))
    }
    
    private func rotatePrivateKey(result: @escaping FlutterResult) {
        self.ethree.rotatePrivateKey(completion: self.flutterCompletion(result: result, code: "8"))
    }
    
    private func hasLocalPrivateKey(result: @escaping FlutterResult) {
        let hasKey: Bool
        
        do {
            hasKey = try self.ethree.hasLocalPrivateKey()
        } catch let error {
            return result(FlutterError(code: "9", message: "error happened during check of local private key", details: error.localizedDescription))
        }
        
        return result(hasKey)
    }
    
    private func cleanup(result: @escaping FlutterResult) {
        do {
            try self.ethree.cleanUp()
        } catch let error {
            return result(FlutterError(code: "10", message: "error happened during cleanup", details: error.localizedDescription))
        }
        
        return result(true)
    }
    
    private func findUser(identity: String, result: @escaping FlutterResult) {
        self.ethree.findUser(with: identity, completion: { res, error in
            if let error = error {
                return result(FlutterError(code: "11", message: "error happened during findUser call", details: error.localizedDescription))
            }
            
            guard let res = res else {
                return result(FlutterError(code: "12", message: "no card was found", details: nil))
            }
            
            var user: String
            do {
                user = try res.getRawCard().exportAsBase64EncodedString()
            } catch let error {
                return result(FlutterError(code: "13", message: "can't export raw card into base64 string", details: error.localizedDescription))
            }
            
            return result(user)
        })
    }
    
    private func findUsers(identities: [String], result: @escaping FlutterResult) {
         self.ethree.findUsers(with: identities, completion: {res, error in
            if let error = error {
                return result(FlutterError(code: "14", message: "error happened during findUsers call", details: error.localizedDescription))
            }
            
            guard let res = res else {
                return result(FlutterError(code: "15", message: "no users were found", details: nil))
            }
            
            do {
                let cards = try res.compactMapValues({
                    try $0.getRawCard().exportAsBase64EncodedString()
                })
                
                return result(cards)
            } catch let error {
                return result(FlutterError(code: "16", message: "can't export raw card into base 64", details: error.localizedDescription))
            }
        })
    }
    
    private func findCachedUser(identity: String, result: @escaping FlutterResult) {
        let card = self.ethree.findCachedUser(with: identity)
        do {
            let user = try card?.getRawCard().exportAsBase64EncodedString()
            return result(user)
        } catch let error {
            return result(FlutterError(code: "17", message: "can't export card", details: error.localizedDescription))
        }
    }
    
    private func findCachedUsers(identities: [String], result: @escaping FlutterResult) {
        do {
            let cards = try self.ethree.findCachedUsers(with: identities)
            let users = try cards.compactMapValues({
                try $0.getRawCard().exportAsBase64EncodedString()
            })
            return result(users)
        } catch let error {
            return result(FlutterError(code: "18", message: "can't export cards", details: error.localizedDescription))
        }
    }
    
    private func updateCachedUsers(result: @escaping FlutterResult) {
        self.ethree.updateCachedUsers(completion: {error in
            if let error = error {
                return result(FlutterError(code: "19", message: "can't update cached users", details: error.localizedDescription))
            }
            
            return result(true)
        })
    }
    
    private func authEncrypt(data: String, users: [String: String], result: @escaping FlutterResult) {
        do {
            let users = try users.mapValues {
                try self.ethree.cardManager.importCard(fromBase64Encoded: $0)
            }
            let encyptedData = try self.ethree.authEncrypt(text: data, for: users)
            return result(encyptedData)
        } catch let error {
            return result(FlutterError(code: "21", message: "can't encrypt data for user", details: error.localizedDescription))
        }
    }
    
    private func authDecrypt(data: String, cardStr: String, result: @escaping FlutterResult) {
        do {
            var card: Card? = nil
            if cardStr != "" {
                card = try self.ethree.cardManager.importCard(fromBase64Encoded: cardStr)
            }
            
            let decryptedData = try self.ethree.authDecrypt(text: data, from: card)
            return result(decryptedData)
        } catch let error {
            return result(FlutterError(code: "23", message: "can't decrypt data from user", details: error.localizedDescription))
        }
    }
    
//    private func authEncryptFile(call: FlutterMethodCall, result: @escaping FlutterResult) {
//
//    }
//
//    private func authDecryptFile(call: FlutterMethodCall, result: @escaping FlutterResult) {
//
//    }
    
    private func flutterCompletion(result: @escaping FlutterResult, code: String) -> (_ error: Error?) -> Void {
        return { (error: Error?) -> Void in
            if let error = error {
                return result(FlutterError(code: code, message: "error happened", details: error.localizedDescription))
            }
            
            return result(true)
        }
    }

}
