import 'package:flutter/material.dart';

import '../widget/a_snackbar.dart';
import '../widget/a_text.dart';
import '../widget/button.dart';
import '../widget/edit_text.dart';

class ChangePasswordDialog extends StatefulWidget {

  const ChangePasswordDialog({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _ChangePasswordDialog();
  }
}

class _ChangePasswordDialog extends State<ChangePasswordDialog> {
  final Map<String, String> _data = {};
  bool _apiProgress = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadiusDirectional.circular(8)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: contentBox(context),
    );
  }

  contentBox(context) {
    return Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.all(Radius.circular(8.0)),
        ),
        // child: Padding(padding: EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const AText('Change Password',textColor: Colors.redAccent, fontWeight: FontWeight.w500),
            EditText('Old password', 'oldPassword', _data, obscure: true, ),
            EditText('New password', 'newPassword', _data, obscure: true, ),
            EditText('Confirm password', 'confirmPassword', _data, obscure: true, onSubmitted: funOnUpdatePassword,),
            Button("Update Password",
              progress: _apiProgress,
              onTap: funOnUpdatePassword,
            ),
          ],
        // ),
        ));
  }

  void onClickYes() {
    Navigator.pop(context);
  }


  funOnUpdatePassword()  async {
    ScaffoldMessengerState scaffoldMessengerState =
        ScaffoldMessenger.of(context);
    FocusScope.of(context).requestFocus(FocusNode());

    if (_data['oldPassword']!.isEmpty) {
      ASnackBar.showSnackBar(scaffoldMessengerState, "Enter Old Password", 0);
      return;
    } else if (_data['newPassword']!.isEmpty) {
      ASnackBar.showSnackBar(scaffoldMessengerState, "Enter New Password", 0);
      return;
    } else if (_data['newPassword']!.length < 6) {
      ASnackBar.showSnackBar(
          scaffoldMessengerState, "Password must be 6 character long", 0);
      return;
    } else if (_data['confirmPassword']!.isEmpty) {
      ASnackBar.showSnackBar(
          scaffoldMessengerState, "Enter Confirm password", 0);
      return;
    } else if (_data['confirmPassword']!.length < 6) {
      ASnackBar.showSnackBar(
          scaffoldMessengerState, "Password must be 6 character long", 0);
      return;
    } else if (_data['newPassword'] != _data['confirmPassword']) {
      ASnackBar.showSnackBar(scaffoldMessengerState, "Password mismatched", 0);
      return;
    }
    if(_apiProgress) return;
    _apiProgress = true;

    _funUpdateUi();

    await Future.delayed(const Duration(milliseconds: 1000));

    _apiProgress = false;
    _funUpdateUi();
  }

  _funUpdateUi() {
    setState(() {});
  }

}
