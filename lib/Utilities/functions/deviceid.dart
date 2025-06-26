import 'dart:io';
import 'package:android_id/android_id.dart';
import 'package:device_info_plus/device_info_plus.dart';

Future<String?> getDeviceId() async {
  final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();

  if (Platform.isAndroid) {
    const androidIdPlugin = AndroidId();
    final String? androidId = await androidIdPlugin.getId();
    return androidId;
  } else if (Platform.isIOS) {
    final iosInfo = await deviceInfo.iosInfo;
    return iosInfo.identifierForVendor;
  }

  return null;
}