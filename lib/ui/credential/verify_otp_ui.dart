import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:moval/ui/credential/widget/credential_container.dart';
import 'package:moval/ui/credential/widget/custom_otp_field.dart';
import 'package:moval/util/routes.dart';
import 'package:moval/widget/a_text.dart';

import '../../api/api.dart';
import '../../util/preference.dart';
import '../../widget/a_snackbar.dart';
import '../../widget/button.dart';


class VerifyOtp extends StatefulWidget {
  final String userId;
  final String id;
  final String platformKey;

  const VerifyOtp({
    Key? key,
    this.platformKey = '',
    this.userId = '',
    this.id = '',
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _VerifyOtp();
  }
}

class _VerifyOtp extends State<VerifyOtp> {

  bool _otpRequest = false;
  bool _apiVerifyProgress = false;
  int _counter = 30;
  String _timeLabel = 'Resend code in 00:30';

  String otpPin = '';

  @override
  void initState() {
    _resendCountDown();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {

    final size = MediaQuery.of(context).size;


    return CredentialContainer(
      "Forget Password",
      "Enter 4 digit code we sent to your\nregistered email id.",
      [
        CustomOTPField(
          length: 4,
          width: MediaQuery.of(context).size.width,
          textFieldAlignment: MainAxisAlignment.spaceEvenly,
          fieldWidth: 50,
          outlineBorderRadius: 4,
          style: const TextStyle(fontSize: 14),
          onCompleted: (pin) {
            otpPin = pin;
            log("Completed: $otpPin");
          },
        ),
        Container(
            height: 60,
            alignment: Alignment.center,
            margin: const EdgeInsets.only(top: 20.0),
            child: _timeLabel.isNotEmpty
                ? AText( _timeLabel, textColor: Colors.grey, fontSize: 14, fontWeight: FontWeight.w600,)
                : _otpRequest
                ? const SizedBox(height: 15, width: 15, child: CircularProgressIndicator(strokeWidth: 2,),)
                : TextButton(onPressed: _funGetOtp, child: const Text('Resend OTP')),
        ),
        Button(
          "Verify",
          onTap: _funVerifyOtp,
          progress: _apiVerifyProgress,
          margin: EdgeInsets.only(
            left: size.width * .08,
            top: size.height * 0.05 + 30,
            right: size.width * .08,
          ),
        ),
      ],
    );
  }

  void _resendCountDown() async {
    _counter--;
    _timeLabel = 'Resend code in 00:${_counter > 9 ? '' : '0'}$_counter';
    _updateUi;
    await Future.delayed(const Duration(seconds: 1));
    if (_counter > 1) {
      _resendCountDown();
    } else {
      _timeLabel = '';
      _updateUi;
    }
  }

  void _funVerifyOtp() async {
    ScaffoldMessengerState scaffoldMessengerState =
        ScaffoldMessenger.of(context);
    NavigatorState navigatorState = Navigator.of(context);

    FocusScope.of(context).requestFocus(FocusNode());

    if (otpPin.length < 4 || otpPin.isEmpty) {
      ASnackBar.showSnackBar(scaffoldMessengerState, "Please Enter Otp", 0);
      return;
    }

    if (_apiVerifyProgress) return;
    _apiVerifyProgress = true;
    _updateUi;

    final response =
        await Api(scaffoldMessengerState).callVerifyOtp(otpPin, widget.id);

    if (response.runtimeType != String) {
      Preference.setValue(Preference.userId, int.parse(widget.id));
      Preference.setValue(Preference.isRememberMe, false);
      Preference.setValue(Preference.userToken, 'Bearer ${response['token']}');
      Preference.setValue(Preference.isFromForgetPassword, true);
      String credentialStr = Preference.getStr(Preference.credential);
      if (credentialStr.isNotEmpty) {
        int platformIndex = jsonDecode(credentialStr)['platform'];
        await Future.delayed(const Duration(seconds: 2));
        navigatorState.pushNamedAndRemoveUntil(
          Routes.setPassword,
          (Route<dynamic> route) => false,
          arguments: {
            'platform': platformIndex,
          },
        );
      }
    } else {
      ASnackBar.showError(scaffoldMessengerState, response);
    }

    _apiVerifyProgress = false;
    _updateUi;

  }

  void _funGetOtp() async {
    ScaffoldMessengerState scaffoldMessengerState =
        ScaffoldMessenger.of(context);

    if (_otpRequest) return;

    _otpRequest = true;
    _updateUi;

    String response = await Api(scaffoldMessengerState)
        .callSendForgotPasswordRequest(widget.userId, widget.platformKey);

    if (response.startsWith(Api.success)) {
      _counter = 30;
      _resendCountDown();
    } else if (response == Api.internetError) {
      ASnackBar.showError(scaffoldMessengerState, 'Internet not connected...!');
    } else {
      ASnackBar.showError(scaffoldMessengerState, response);
    }

    _otpRequest = false;
    _updateUi;

  }

  get _updateUi => setState((){});

}