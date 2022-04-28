import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:virgil_e3kit/virgil_e3kit.dart';
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'dart:io';

void main() {
  runApp(MyApp());
}

String getRandString(int len) {
  var random = Random.secure();
  var values = List<int>.generate(len, (i) => random.nextInt(255));
  return base64UrlEncode(values);
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String _state = 'Unknown';

  Future<void> multi_device() async {
    //User identity should remain the same across different devices
    //To verify multi device properly, you need to launch this code on multiple
    //devices.
    final String initIdentity = "multi_device_support";

    final tokenCallback = () async {
      var host = Uri.parse('http://localhost:8080/jwt');
      if (Platform.isAndroid) {
        host = Uri.parse('http://10.0.2.2:8080/jwt');
      }
      var response =
          await http.post(host, body: '{"identity": "$initIdentity"}');
      final resp = jsonDecode(response.body);

      return resp["virgilToken"];
    };

    String result;
    final String password = "12345";
    final ethree = await Ethree.init(initIdentity, tokenCallback);

    try {
      result = "Key is taken from local storage";
      var hasKeyLocally = await ethree.hasLocalPrivateKey();
      if (!hasKeyLocally) {
        print("Trying to restore private key");
        await ethree.restorePrivateKey(password);
        result = "Key is restored from cloud";
      }
    } on PlatformException catch (e) {
      print("Failed to get identity: '${e.message}' '${e.code}' '${e.details}'.");
      print("Register user: $initIdentity");
      await ethree.register();

      print("Backup private key");
      await ethree.backupPrivateKey(password);
      result = "User was registered and private key backuped";
    }
    setResult(result);
  }

  Future<void> random_user() async {
    final String initIdentity = getRandString(10);

    final tokenCallback = () async {
      var host = Uri.parse('http://localhost:8080/jwt');
      if (Platform.isAndroid) {
        host = Uri.parse('http://10.0.2.2:8080/jwt');
      }
      var response =
      await http.post(host, body: '{"identity": "${initIdentity}"}');
      final resp = jsonDecode(response.body);

      return resp["jwt"];
    };

    String result;
    try {
      final ethree = await Ethree.init(initIdentity, tokenCallback);
      await ethree.register();
      await ethree.hasLocalPrivateKey();
      await ethree.backupPrivateKey("1111");
      await ethree.changePassword("1111", "11111");
      await ethree.cleanup();
      await ethree.restorePrivateKey("11111");
      await ethree.resetPrivateKeyBackup();
      await ethree.cleanup();
      await ethree.rotatePrivateKey();
      await ethree.backupPrivateKey("1111");

      //These users should exist in the cloud, so you can register them manually
      //if you need whole example to work
      final users = await ethree
          .findUsers(["identity1", "identity2", initIdentity], true);
      final data = await ethree.authEncrypt(users, "data");
      final decryptedData = await ethree.authDecrypt(data, users[initIdentity]);
      result = "My identity: $initIdentity, Data: $decryptedData";
    } on PlatformException catch (e) {
      result =
      "Failed to get identity level: '${e.message}' '${e.code}' '${e.details}'.";
    }

    setResult(result);
  }

  setResult(final String state) {
    setState(() {
      _state = state;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Text("Each button starts fully separate examples of ethree usage"),
            ElevatedButton(
              child: Text('Gen random user'),
              onPressed: random_user,
            ),
            ElevatedButton(
              child: Text('Try multi device'),
              onPressed: multi_device,
            ),
            Text("Result: $_state"),
          ],
        ),
      ),
    );
  }
}
