import 'package:flutter/material.dart';
import 'package:moval/util/routes.dart';
import 'package:moval/widget/a_snackbar.dart';
import 'package:moval/widget/button.dart';
import 'package:moval/widget/edit_text.dart';

import '../../api/api.dart';
import '../../util/preference.dart';
import '../../widget/header.dart';

class ChangePassword extends StatefulWidget{

  const ChangePassword({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _State();
  }

}

class _State extends State<ChangePassword>{

  final Map<String, String> _data = {};
  bool _apiProgress = false;

  @override
  Widget build(BuildContext context) {

    final size = MediaQuery.of(context).size;

    return Header('Change Password',
        child:
            Padding(padding: const EdgeInsets.all(20),
            child: Column (children: [
              EditText('Old password', 'oldPassword', _data, obscure: true, ),
              EditText('New password', 'newPassword', _data, obscure: true, ),
              EditText('Confirm password', 'confirmPassword', _data, obscure: true, onSubmitted: _funOnChangePassword,),
              Button("Change Password",
                progress: _apiProgress,
                onTap: _funOnChangePassword,
                margin: EdgeInsets.only(left: size.width * .08, top: size.height * 0.05 + 30, right: size.width * .08, bottom: 30),
              ),
            ],),));
  }

  _funOnChangePassword() async {
    ScaffoldMessengerState scaffoldMessengerState =
        ScaffoldMessenger.of(context);
    NavigatorState navigatorState = Navigator.of(context);
    FocusScope.of(context).requestFocus(FocusNode());

    if (_data['oldPassword']!.isEmpty) {
      ASnackBar.showSnackBar(scaffoldMessengerState, "Enter Old Password", 0);
      return;
    } else if (_data['newPassword']!.isEmpty) {
      ASnackBar.showSnackBar(scaffoldMessengerState, "Enter New Password", 0);
      return;
    } else if (_data['newPassword']!.length < 6) {
      ASnackBar.showSnackBar(scaffoldMessengerState, "Password must be 6 character long", 0);
      return;
    } else if (_data['confirmPassword']!.isEmpty) {
      ASnackBar.showSnackBar(scaffoldMessengerState, "Enter Confirm password", 0);
      return;
    } else if (_data['confirmPassword']!.length < 6) {
      ASnackBar.showSnackBar(scaffoldMessengerState, "Password must be 6 character long", 0);
      return;
    } else if (_data['newPassword'] != _data['confirmPassword']) {
      ASnackBar.showSnackBar(scaffoldMessengerState, "Password mismatched", 0);
      return;
    }


    if(_apiProgress) return;
    _apiProgress = true;

    _funUpdateUi();


    final response = await Api(scaffoldMessengerState).callChangePasswordApi(_data['oldPassword']!, _data['newPassword']!, _data['confirmPassword']!);

    if (response == Api.defaultError) {
      ASnackBar.showError(scaffoldMessengerState, 'Something went wrong');
    }
    else if (response == Api.internetError) {
      ASnackBar.showError(scaffoldMessengerState, 'Internet not connected');
    }
    else if (response == Api.authError) {
      Preference.setValue(Preference.isLogin, false);
      Preference.setValue(Preference.isRememberMe, false);
      navigatorState.pushNamedAndRemoveUntil(Routes.login, (route) => false);
    }
    else {
      ASnackBar.showSuccess(scaffoldMessengerState, 'Password set successfully.');
    }

    await Future.delayed(const Duration(milliseconds: 1000));

    _apiProgress = false;
    _funUpdateUi();
  }

  _funUpdateUi() {
    setState(() {});
  }

}