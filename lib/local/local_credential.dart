import 'package:hive_flutter/hive_flutter.dart';
import 'package:moval/local/hive_box_key.dart';

class LocalCredential {

  static const userId = 'user_id';
  static const userPassword = 'user_password';
  static const isLogin = 'is_login';
  static const isGuest = 'is_guest_employee';
  static const isCredentialSave = 'is_credential_save';
  static const isRememberMe = 'remember_me';
  static const token = 'token';

  static const _credentialKey = '0';

  static saveCredential(value) async {
    await Hive.box(HiveBoxKey.credential).put(_credentialKey, value);
  }

  static getCredential() async {
    final data = await Hive.box(HiveBoxKey.credential).get(_credentialKey, defaultValue: {});
    return data;
  }

  static isUserLogin() async {
    final data = await getCredential();
    return data[isLogin] ?? false;
  }

  static isUserGuest() async {
    final data = await getCredential();
    return data[isGuest] == '1';
  }

  static logoutUser({bool clc = false}) async {
    final data = await getCredential();
    data[isLogin] = false;
    data[isCredentialSave] = false;
    saveCredential(data);
  }

}
