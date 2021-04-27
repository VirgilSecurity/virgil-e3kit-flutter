import 'dart:async';
import 'dart:math';
import 'dart:convert';
import 'package:flutter/services.dart';

typedef GetJWTCallback = Future<dynamic> Function();
final MethodChannel globalChannel = MethodChannel('com.virgilsecurity/ethree');

class Ethree {
  final MethodChannel _channel;
  final GetJWTCallback tokenCallback;
  final String identity;

  Ethree(this.identity, this.tokenCallback, this._channel) {
    this._channel.setMethodCallHandler(this.handleMethodCall);
  }

  static Future<Ethree> init(
      String identity, GetJWTCallback tokenCallback) async {
    final String channelID = getRandString(32);
    bool result = await globalChannel
        .invokeMethod('init', {'channelID': channelID, 'identity': identity});
    if (result == false) {
      return null;
    }

    final MethodChannel localChannel = MethodChannel(channelID);
    final ethree = Ethree(identity, tokenCallback, localChannel);

    return ethree;
  }

  Future<String> getIdentity() async {
    return _channel.invokeMethod('getIdentity');
  }

  Future<bool> register() async {
    return _channel.invokeMethod('register');
  }

  Future<bool> unregister() async {
    return _channel.invokeMethod("unregister");
  }

  Future<bool> backupPrivateKey(String password) async {
    return _channel.invokeMethod("backupPrivateKey", {"password": password});
  }

  Future<bool> changePassword(String oldPassword, String newPassword) async {
    return _channel.invokeMethod("changePassword",
        {"oldPassword": oldPassword, "newPassword": newPassword});
  }

  Future<bool> resetPrivateKeyBackup() async {
    return _channel.invokeMethod("resetPrivateKeyBackup");
  }

  Future<bool> restorePrivateKey(String password) async {
    return _channel.invokeMethod("restorePrivateKey", {'password': password});
  }

  Future<bool> rotatePrivateKey() async {
    return _channel.invokeMethod("rotatePrivateKey");
  }

  Future<bool> hasLocalPrivateKey() async {
    return _channel.invokeMethod("hasLocalPrivateKey");
  }

  Future<bool> cleanup() async {
    return _channel.invokeMethod("cleanup");
  }

  Future<String> findUser(String identity) async {
    final String card =
        await _channel.invokeMethod('findUser', {'identity': identity});

    return card;
  }

  Future<Map> findUsers(List<String> identities, bool forceReload) async {
    Map users = await _channel.invokeMethod(
        "findUsers", {"identities": identities, "forceReload": forceReload});

    return users;
  }

  Future<String> findCachedUser(String identity) async {
    final String card =
        await _channel.invokeMethod("findCachedUser", {'identity': identity});

    return card;
  }

  Future<Map> findCachedUsers(List<String> identities) async {
    final Map users = await _channel
        .invokeMethod("findCachedUsers", {"identities": identities});

    return users;
  }

  Future<bool> updateCachedUsers() async {
    return _channel.invokeMethod("updateCachedUsers");
  }

  Future<String> authEncrypt(Map users, String data) async {
    return _channel.invokeMethod("authEncrypt", {"users": users, "data": data});
  }

  Future<String> authDecrypt(String data, [String card = ""]) async {
    return _channel.invokeMethod("authDecrypt", {"data": data, "card": card});
  }

  Future<dynamic> handleMethodCall(MethodCall call) {
    switch (call.method) {
      case 'tokenCallback':
        return this.tokenCallback();
    }
    return null;
  }
}

String getRandString(int len) {
  var random = Random.secure();
  var values = List<int>.generate(len, (i) => random.nextInt(255));
  return base64UrlEncode(values);
}
