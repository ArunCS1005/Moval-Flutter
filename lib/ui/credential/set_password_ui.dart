import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:moval/ui/credential/widget/credential_container.dart';
import 'package:moval/util/routes.dart';
import 'package:moval/widget/a_snackbar.dart';
import 'package:moval/widget/button.dart';
import 'package:moval/widget/edit_text.dart';

import '../../api/api.dart';
import '../../api/common_methods.dart';
import '../../util/preference.dart';

class SetPassword extends StatefulWidget{

  const SetPassword({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _State();
  }

}

class _State extends State<SetPassword>{

  final Map _data = {};
  bool _apiProgress = false;

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _funGetArguments();
    });
  }

  void _funGetArguments() async {
    ModalRoute? modalRoute = ModalRoute.of(context);

    await Future.delayed(Duration.zero);

    Map<String, dynamic> data =
        (modalRoute?.settings.arguments as Map<String, dynamic>?) ?? {};
    _data.addAll(data);
  }

  @override
  Widget build(BuildContext context) {

    final size = MediaQuery.of(context).size;

    return CredentialContainer(
        "Set Password", 
        "Set your password", 
        [
          EditText('Enter password', 'password', _data, obscure: true, icon:'password-lock.svg',),
          EditText('Confirm password', 'confirmPassword', _data, icon: 'confirm-password.svg', obscure: true, onSubmitted: _funOnSetPassword,),
          Button("Set",
            progress: _apiProgress,
            onTap: _funOnSetPassword,
            margin: EdgeInsets.only(left: size.width * .08, top: size.height * 0.05 + 30, right: size.width * .08, bottom: 30),
          ),
        ]);
  }

  _funOnSetPassword() async {
    ScaffoldMessengerState scaffoldMessengerState =
        ScaffoldMessenger.of(context);
    NavigatorState navigatorState = Navigator.of(context);
    FocusScope.of(context).requestFocus(FocusNode());
    bool isConnected = await CommonMethods().checkNetwork();

    if (_data['password'].isEmpty) {
      ASnackBar.showSnackBar(scaffoldMessengerState, "Enter password", 0);

      return;
    } else if (_data['password'].length < 6) {
      ASnackBar.showSnackBar(
          scaffoldMessengerState, "Password must be 6 character long", 0);

      return;
    } else if (_data['confirmPassword'].isEmpty) {
      ASnackBar.showSnackBar(
          scaffoldMessengerState, "Enter Confirm password", 0);

      return;
    } else if (_data['confirmPassword'].length < 6) {
      ASnackBar.showSnackBar(
          scaffoldMessengerState, "Password must be 6 character long", 0);

      return;
    } else if (_data['password'] != _data['confirmPassword']) {
      ASnackBar.showSnackBar(scaffoldMessengerState, "Password mismatched", 0);

      return;
    } else if (!isConnected) {
      ASnackBar.showSnackBar(
          scaffoldMessengerState, "Internet not connected...!", 0);
      return;
    }

    if (_apiProgress) return;
    _apiProgress = true;
    _funUpdateUi();

    final response = await Api(scaffoldMessengerState).setPassword(
      _data['password'],
      _data['confirmPassword'],
      Preference.getStr(Preference.userNameId).toString(),
      platformIndex: _data['platform'] ?? 1,
    );

    _apiProgress = false;
    _funUpdateUi();

    if (response == Api.success) {
      ASnackBar.showSuccess(
          scaffoldMessengerState, 'Password change successfully');
      Preference.setValue(Preference.isLogin, true);
      Preference.setValue(Preference.isSetPassword, 'yes');
      if (Preference.getBool(Preference.isRememberMe)) {
        Preference.setValue(Preference.loginUserPassword, _data['password']);
      }
      if (Preference.getBool(Preference.isFromForgetPassword)) {
        Preference.setValue(Preference.isFromForgetPassword, false);
        Preference.setValue(Preference.isLogin, false);
        navigatorState.pushReplacementNamed(Routes.login);
      } else {
        navigatorState.pushReplacementNamed(Routes.homeScreen);
      }
    } else if (response == Api.internetError) {
      ASnackBar.showError(scaffoldMessengerState, 'Internet not connected...!');
    } else {
      ASnackBar.showError(scaffoldMessengerState, response);
    }

  }

  
  _funUpdateUi() {
    setState(() {});
  }

}