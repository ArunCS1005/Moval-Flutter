import 'package:device_info_plus/device_info_plus.dart';

class DeviceInfo {

  static final _deviceInfo = DeviceInfoPlugin();

  static Future<AndroidDeviceInfo> getInfo() async {
    return _deviceInfo.androidInfo;
  }

  static Future<String> getDeviceId() async {
    final data = await getInfo();
    return data.id;
  }

}