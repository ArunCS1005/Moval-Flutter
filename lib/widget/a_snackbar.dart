import 'package:flutter/material.dart';
import 'package:moval/api/api.dart';
import 'package:moval/widget/a_text.dart';

class ASnackBar {
  static showSnackBar(ScaffoldMessengerState state, String text, int code,
      {String status = '', Duration? duration}) {
    Color color = Colors.redAccent;

    switch (status) {
      case Api.warning:
        color = Colors.redAccent;
        break;
      case Api.internetError:
      case Api.defaultError:
        color = Colors.redAccent;
        break;
      case Api.success:
        color = Colors.green;
        break;
    }

    state.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(0.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(0.0),
        ),
        content: AText(
          text,
          textColor: Colors.white,
        ),
        backgroundColor: color,
        duration: duration ?? const Duration(seconds: 1),
      ),
    );
  }

  static showWarning(ScaffoldMessengerState state, String msg) {
    showSnackBar(state, msg, 0, status: Api.warning);
  }

  static showError(
    ScaffoldMessengerState state,
    String msg, {
    bool internetError = false,
  }) {
    String msg0 = '';
    if (msg.startsWith(Api.defaultError) &&
        msg.length == Api.defaultError.length) {
      msg0 = 'Something went wrong.';
    } else if (msg.startsWith(Api.defaultError)) {
      msg0 = msg.replaceFirst(Api.defaultError, '');
    } else if (msg.startsWith(Api.internetError)) {
      msg0 = 'Please check your internet connection...!';
    } else {
      msg0 = msg;
    }
    showSnackBar(state, msg0, 0,
        status: internetError ? Api.internetError : Api.defaultError);
  }

  static showSuccess(ScaffoldMessengerState state, String msg) {
    showSnackBar(state, msg, 0, status: Api.success);
  }

}
