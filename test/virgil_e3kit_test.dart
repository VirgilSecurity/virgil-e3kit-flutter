import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:virgil_e3kit/virgil_e3kit.dart';

void main() {
  const MethodChannel channel = MethodChannel('virgil_e3kit');

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
    expect(await VirgilE3kit.platformVersion, '42');
  });
}
