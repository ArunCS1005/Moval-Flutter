
import 'package:flutter/material.dart';
import 'package:moval/ui/credential/verify_otp_ui.dart';
import 'package:moval/ui/credential/widget/credential_container.dart';
import 'package:moval/widget/a_snackbar.dart';
import 'package:moval/widget/button.dart';

import '../../api/api.dart';
import '../../widget/a_text.dart';
import '../../widget/edit_text.dart';

class ForgetPassword extends StatefulWidget {

  const ForgetPassword({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _ForgetPassword();
  }
}

class _ForgetPassword extends State<ForgetPassword> {

  //final _regExp =  RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+");
  final Map _data = {'mobileNo': '', 'userId': ''};
  bool _apiProgress = false;
  String userId = '', userPassword = '';
  String? _selectedPlatformKey;
  final Map<String, String> _platforms = {
    'mv': 'Motor Valuation',
    'ms': 'Motor Survey',
  };

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return CredentialContainer(
      "Forget Password",
      "Enter your mobile no. and user id",
      [
        Container(
          margin: const EdgeInsets.only(top: 10),
          decoration: const BoxDecoration(boxShadow: [], color: Colors.white),
          child: DropdownButtonFormField(
            value: _selectedPlatformKey,
            onChanged: _funOnChangeAccountType,
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
            items: [
              for (MapEntry<String, String> e in _platforms.entries)
                DropdownMenuItem(
                  value: e.key,
                  child: AText(e.value),
                ),
            ],
          ),
        ),
        EditText('User id', 'userId', _data, onSubmitted: _funGetOtp,),
        Button("Get OTP",
          onTap: _funGetOtp,
          progress: _apiProgress,
          margin: EdgeInsets.only(left: size.width * .08, top: size.height * 0.05 + 30, right: size.width * .08, bottom: 30),),
      ],
    );
  }

  void _funOnChangeAccountType(String? value) {
    _selectedPlatformKey = value;
    _updateUi;
  }

  void _funGetOtp() async {
    ScaffoldMessengerState scaffoldMessengerState =
        ScaffoldMessenger.of(context);
    NavigatorState navigatorState = Navigator.of(context);
    FocusScope.of(context).requestFocus(FocusNode());

    if (_data['userId'].isEmpty) {
      ASnackBar.showSnackBar(scaffoldMessengerState, "Please Enter User Id", 0);
      return;
    }

    if (_selectedPlatformKey == null) {
      ASnackBar.showSnackBar(
          scaffoldMessengerState, "Platform must be selected", 0);
      return;
    }

    if (_apiProgress) return;
    _apiProgress = true;
    _updateUi;

    String response = await Api(scaffoldMessengerState)
        .callSendForgotPasswordRequest(_data['userId'], _selectedPlatformKey!);

    if (response.startsWith(Api.success)) {
      navigatorState.push(
        MaterialPageRoute(
          builder: (context) => VerifyOtp(
            platformKey: _selectedPlatformKey!,
            userId: _data['userId'],
            id: response.replaceFirst(Api.success, ''),
          ),
        ),
      );
    } else if (response == Api.internetError) {
      ASnackBar.showError(scaffoldMessengerState, 'Internet not connected...!');
    } else {
      ASnackBar.showError(scaffoldMessengerState, response);
    }

    _apiProgress = false;
    _updateUi;
  }

  get _updateUi => setState((){});

}


