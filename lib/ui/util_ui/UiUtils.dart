import 'package:flutter/material.dart';
import 'package:moval/util/preference.dart';
import 'package:moval/util/routes.dart';

class UiUtils {
  static BoxDecoration decoration() => const BoxDecoration(
        boxShadow: [
          BoxShadow(
            blurRadius: 4,
            color: Colors.black26,
          )
        ],
        color: Colors.white,
      );

  static void authFailed(NavigatorState navigatorState) {
    Preference.setValue(Preference.isLogin, false);
    Preference.setValue(Preference.isRememberMe, false);
    Preference.setValue(Preference.credential, '');
    navigatorState.pushNamedAndRemoveUntil(Routes.login, (route) => false);
  }

  static String? getRawJsonData(dynamic json) {
    if(json == null) {
      return null;
    }

    if(json is String) {
      return '"$json"';
    }

    if(json is int) {
      return json.toString();
    }

    if(json is double) {
      return json.toString();
    }

    if(json is bool) {
      return json.toString();
    }

    if(json is Map<String, dynamic>) {
      return '{${json.entries.map((e) => '"${e.key}": ${getRawJsonData(e.value)}').toList().join(', ')}}';
    }

    if(json is List) {
      return '[${json.map((e) => '${getRawJsonData(e)}').toList().join(', ')}]';
    }

    return null;
  }
}
