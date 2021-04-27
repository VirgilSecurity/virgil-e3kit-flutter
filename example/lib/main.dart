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
  String _identity = 'Unknown';

  Future<void> ethree() async {
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

    String identity;
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

      final users = await ethree
          .findUsers(["identity1", "identity2", initIdentity], true);
      final data = await ethree.authEncrypt(users, "data");
      await ethree.authDecrypt(data, users[initIdentity]);
    } on PlatformException catch (e) {
      identity =
          "Failed to get identity level: '${e.message}' '${e.code}' '${e.details}'.";
    }

    setState(() {
      _identity = identity;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(
              child: Text('Get Battery Level'),
              onPressed: ethree,
            ),
            Text(_identity),
          ],
        ),
      ),
    );
  }
}
