import 'dart:developer';
import 'package:shared_preferences/shared_preferences.dart';

class Preference {
  static SharedPreferences? _sharedPreferences;

  /// Ensures SharedPreferences is initialized before using it
  static Future<void> initialize() async {
    if (_sharedPreferences == null) {
      _sharedPreferences = await SharedPreferences.getInstance();
      log("Preferences initialized...");
    }
  }

  /// Returns an instance of SharedPreferences after ensuring it's initialized
  static SharedPreferences get _prefs {
    if (_sharedPreferences == null) {
      throw Exception(
          "SharedPreferences not initialized. Call Preference.initialize() first.");
    }
    return _sharedPreferences!;
  }

  /// Synchronously access SharedPreferences values
  static bool getBool(String key) {
    return _prefs.getBool(key) ?? false;
  }

  static String getStr(String key) {
    return _prefs.getString(key) ?? "";
  }

  static int getInt(String key) {
    return _prefs.getInt(key) ?? -1;
  }

  static double getDouble(String key) {
    return _prefs.getDouble(key) ?? -1.0;
  }

  static void setValue(String k, dynamic v) {
    if (v == null) {
      _prefs.remove(k);
      return;
    }

    switch (v.runtimeType) {
      case String:
        _prefs.setString(k, v);
        break;
      case bool:
        _prefs.setBool(k, v);
        break;
      case double:
        _prefs.setDouble(k, v);
        break;
      case int:
        _prefs.setInt(k, v);
        break;
      default:
        throw Exception("Unsupported type");
    }
  }

  static dynamic value(String k) {
    return _prefs.get(k);
  }

  /// Keys
  static const isLogin = 'is_login';
  static const isRememberMe = 'is_remember_me';
  static const isGuest = 'is_guest';
  static const guestJobId = 'guest_job_id';
  static const userToken = 'user_token';
  static const firebaseToken = 'firebase_token';
  static const userName = 'user_name';
  static const userEmail = 'user_email';
  static const userMobileNo = 'user_mobile_no';
  static const userAddress = 'user_address';
  static const userId = 'user_id';
  static const userNameId = 'user_name_id';
  static const userParentId = 'parent_id';
  static const loginUserId = 'login_user_id';
  static const loginUserPassword = 'login_user_password';
  static const isSetPassword = 'is_set_password';
  static const userRole = 'user_role';
  static const currentJob = 'currentJob';
  static const credential = 'credential';
  static const fromDate = 'fromDate';
  static const toDate = 'toDate';
  static const isFromForgetPassword = 'is_from_forget_password';
  static const otherImageLimit = "other_image_limit";
  static const lastDateOfPayment = "last_date_of_payment";
  static const isShowMessageToEmployee = "is_show_message_to_employee";
}
