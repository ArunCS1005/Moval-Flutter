
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:moval/api/api.dart';
import 'package:moval/util/device_info.dart';
import 'package:moval/util/routes.dart';

import '../util/preference.dart';
import 'credential/set_password_ui.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with WidgetsBindingObserver {
  final String _apiResponse = '';
  final bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkUserStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _checkUserStatus() async {
    await Future.delayed(const Duration(seconds: 2));

    String credentialStr = Preference.getStr(Preference.credential);

    if (credentialStr.isEmpty || !Preference.getBool(Preference.isLogin)) {
      _navigateToLogin();
    } else {
      _loginUser(credentialStr);
    }
  }

Future<void> _loginUser(String credentialStr) async {
    final credentials = jsonDecode(credentialStr);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    bool isRememberMe = Preference.getBool(Preference.isRememberMe);

    if (!isRememberMe) {
      _navigateToLogin();
      return;
    }

    final response = await Api(scaffoldMessenger).login(
      credentials['id'],
      credentials['password'],
      credentials['platform'],
      await DeviceInfo.getDeviceId(),
      Preference.getStr(Preference.firebaseToken),
    );

    if (response == Api.defaultError || response == Api.authError) {
      _navigateToLogin();
    } else {
      print(Preference.userToken);
      _navigateToHome();
    }
  }

  void _navigateToLogin() {

    Navigator.of(context).pushReplacementNamed(Routes.login);
  }

  void _navigateToHome() {
    Navigator.of(context).pushReplacementNamed(Routes.homeScreen);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Image.asset('assets/images/img_splash_new.jpg',
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}
