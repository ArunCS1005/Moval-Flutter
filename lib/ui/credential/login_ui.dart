import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:moval/api/common_methods.dart';
import 'package:moval/ui/credential/widget/credential_container.dart';
import 'package:moval/util/device_info.dart';
import 'package:moval/util/preference.dart';
import 'package:moval/util/routes.dart';
import 'package:moval/widget/a_snackbar.dart';
import 'package:moval/widget/button.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../api/api.dart';
import '../../widget/a_text.dart';
import 'forget_password_ui.dart';

class Login extends StatefulWidget {
  const Login({Key? key}) : super(key: key);
  @override
  State<StatefulWidget> createState() {
    return _LoginState();
  }
}

class _LoginState extends State<Login> {

  Future<void> getPermissions() async {
    await [
      Permission.camera,
      Permission.location,
      Permission.microphone,
      Permission.storage,
    ].request();
  }
  bool _rememberMeValue = false;
  bool _apiProgress = false;
  Map<String, TextEditingController> controllers = {};
  final List<String> _platforms = [
    'Motor Valuation',
    'Motor Survey',
  ];
  String? _selectedPlatform;
  bool _obscureText = true;

  void _togglePasswordVisibility() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }
  @override
  void initState() {
    super.initState();
    _getFirebaseToken();
  }

  void _getFirebaseToken() async {
    try {
      // Get a fresh token
      String? token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        print("Firebase token on login: $token");
        Preference.setValue(Preference.firebaseToken, token);
        
        // Set up token refresh listener early
        FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
          print("Firebase token refreshed: $newToken");
          Preference.setValue(Preference.firebaseToken, newToken);
        });
      } else {
        print("Failed to get Firebase token");
      }
    } catch (e) {
      print("Error getting Firebase token: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    final accountTypeDropdown = Container(
      margin: const EdgeInsets.only(top: 10),
      decoration: const BoxDecoration(boxShadow: [], color: Colors.white),
      child: DropdownButtonFormField(
        value: _selectedPlatform,
        onChanged: _onChangeAccountType,
        hint: const AText(
          'Platform',
          textColor: Color.fromARGB(165, 0, 0, 0),
        ),
        decoration: InputDecoration(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(0),
          ),
          isCollapsed: true,
          contentPadding: const EdgeInsets.all(10),
          prefixIcon: const Icon(
            Icons.account_circle_outlined,
            color: Colors.black,
          ),
        ),
        items: _platforms.map((platform) {
          return DropdownMenuItem(
            value: platform,
            child: AText(platform),
          );
        }).toList(),
      ),
    );

    final userIdField = Container(
      margin: const EdgeInsets.only(top: 10),
      decoration: const BoxDecoration(boxShadow: [], color: Colors.white),
      child: TextField(
        maxLines: 1,
        controller:
            controllers.putIfAbsent("User Id", () => TextEditingController()),
        keyboardType: TextInputType.text,
        textInputAction: TextInputAction.next,
        decoration: InputDecoration(
          isCollapsed: false,
          contentPadding: const EdgeInsets.all(10),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(0)),
          hintText: "User Id",
          prefixIcon: Container(
              width: 40,
              height: 40,
              padding: const EdgeInsets.all(13),
              child: SvgPicture.asset('assets/images/user-account.svg')),
        ),
      ),
    );

    final passwordField = Container(
      margin: const EdgeInsets.only(top: 10),
      decoration: const BoxDecoration(boxShadow: [], color: Colors.white),
      child: TextField(
        maxLines: 1,
        controller:
            controllers.putIfAbsent("Password", () => TextEditingController()),
        keyboardType: TextInputType.text,
        textInputAction: TextInputAction.done,
        onSubmitted: (String? value) {
          _onLogin();
        },
        decoration: InputDecoration(
          isCollapsed: false,
          contentPadding: const EdgeInsets.all(10),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(0)),
          hintText: "Password",
          prefixIcon: Container(
            width: 40,
            height: 40,
            padding: const EdgeInsets.all(13),
            child: SvgPicture.asset('assets/images/password-lock.svg'),
        ),
          suffixIcon: IconButton(
            icon: Icon(
              _obscureText ? Icons.visibility_off : Icons.visibility,
            ),
            onPressed: _togglePasswordVisibility,
          ),
        ),
        obscureText: _obscureText,
      ),
    );

    return CredentialContainer(
      "Log in",
      "Enter your user id and password",
      [
        accountTypeDropdown,
        userIdField,
        passwordField,
        _forgetPassword,
        _rememberMe,
        Button(
          "Login",
          onTap: _onLogin,
          progress: _apiProgress,
          margin: EdgeInsets.only(
            left: size.width * .08,
            top: size.height * 0.05 + 30,
            right: size.width * .08,
            bottom: 30,
          ),
        ),
      ],
    );
  }

  void _onForgetPassword() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ForgetPassword()),
    );
  }

  void _onRememberMeChanged(bool? value) {
    setState(() {
      _rememberMeValue = value ?? false;
      if (_rememberMeValue) {
        _loadSavedCredentials();
      } else {
        _clearCredentials();
      }
    });
  }

  void _loadSavedCredentials() {
    String userId = Preference.getStr(Preference.loginUserId);
    String userPassword = Preference.getStr(Preference.loginUserPassword);
    String credentialStr = Preference.getStr(Preference.credential);
    if (userId.isNotEmpty &&
        userPassword.isNotEmpty &&
        credentialStr.isNotEmpty) {
      controllers["User Id"]!.text = userId;
      controllers["Password"]!.text = userPassword;
      _selectedPlatform = _platforms[jsonDecode(credentialStr)['platform']];
    }
  }

  void _clearCredentials() {
    controllers["User Id"]!.clear();
    controllers["Password"]!.clear();
    _selectedPlatform = null;
  }

  void _onChangeAccountType(String? value) {
    setState(() {
      _selectedPlatform = value;
    });
  }

  Future<void> _onLogin() async {
    ScaffoldMessengerState scaffoldMessengerState =
        ScaffoldMessenger.of(context);
    NavigatorState navigatorState = Navigator.of(context);
    FocusScope.of(context).unfocus();

    bool isConnected = await CommonMethods().checkNetwork();

    String id = controllers["User Id"]!.text,
        password = controllers["Password"]!.text;
    int platformIndex = _platforms.indexWhere((e) => e == _selectedPlatform);

    if (platformIndex < 0) {
      ASnackBar.showSnackBar(
          scaffoldMessengerState, "Platform must be selected", 0);
      return;
    } else if (id.isEmpty) {
      ASnackBar.showSnackBar(
          scaffoldMessengerState, "User id can't be empty", 0);
      return;
    } else if (password.isEmpty) {
      ASnackBar.showSnackBar(
          scaffoldMessengerState, "Password can't be empty", 0);
      return;
    } else if (password.length < 6) {
      ASnackBar.showSnackBar(
          scaffoldMessengerState, "Password must be 6 characters long", 0);
      return;
    } else if (!isConnected) {
      ASnackBar.showSnackBar(
          scaffoldMessengerState, "Internet not connected...!", 0);
      return;
    }

    if (_apiProgress) return;
    setState(() {
      _apiProgress = true;
    });

    final response = await Api(scaffoldMessengerState).login(
      id,
      password,
      platformIndex,
      await DeviceInfo.getDeviceId(),
      Preference.getStr(Preference.firebaseToken),
    );

    if (response == Api.defaultError) {
      ASnackBar.showError(scaffoldMessengerState, 'Something went wrong');
    } else if (response == Api.internetError) {
      ASnackBar.showError(scaffoldMessengerState, 'Internet not connected');
    } else if (response.runtimeType == String &&
        response.startsWith(Api.authError)) {
      ASnackBar.showError(
          scaffoldMessengerState, response.replaceFirst(Api.authError, ''));
    } else {
      final detail = response['detail'];


        Preference.setValue(Preference.loginUserId, id);
        Preference.setValue(Preference.loginUserPassword, password);
        Preference.setValue(
          Preference.credential,
          jsonEncode({
            'id': id,
            'password': password,
            'rememberMe': _rememberMeValue,
            'platform': platformIndex,
          }),
        );
      

      // Always save these values regardless of 'Remember Me'
      Preference.setValue(Preference.userToken, 'Bearer ${detail['token']}');
      Preference.setValue(Preference.userId, detail['id']);
      Preference.setValue(Preference.userNameId, detail['user_id']);
      Preference.setValue(Preference.userName, detail['name']);
      Preference.setValue(Preference.userEmail, detail['email']);
      Preference.setValue(Preference.userMobileNo, detail['mobile_no']);
      Preference.setValue(Preference.userRole, detail['role']);
      Preference.setValue(Preference.isLogin, true);

      Preference.setValue(Preference.isRememberMe, _rememberMeValue);

      // Request permissions
      await getPermissions();

      if (detail['is_set_password'] == 'yes') {
        navigatorState.pushReplacementNamed(Routes.homeScreen);
      } else {
        navigatorState.pushReplacementNamed(
          Routes.setPassword,
          arguments: {
            'platform': platformIndex,
          },
        );
      }
    }

    setState(() {
      _apiProgress = false;
    });
  }

  get _forgetPassword => InkWell(
        onTap: _onForgetPassword,
        child: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(top: 10, left: 10, bottom: 10),
          child: const Text(
            "Forget password?",
            style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
          ),
        ),
      );

  get _rememberMe => Row(
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: Checkbox(
              value: _rememberMeValue,
              activeColor: Colors.red,
              onChanged: _onRememberMeChanged,
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            "Remember me",
            style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
          )
        ],
      );
}
