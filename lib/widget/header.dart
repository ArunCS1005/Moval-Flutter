import 'package:flutter/material.dart';
import 'package:moval/util/preference.dart';
import 'package:moval/util/routes.dart';
import 'package:moval/widget/a_text.dart';

import 'a_snackbar.dart';

///
/// Header along with scaffold
///
class Header extends StatelessWidget{

  final String title;
  final Widget? child;
  final double height;
  final bool doublePressEnable;
  final dynamic returnedData;

  const Header(
    this.title, {
    Key? key,
    this.child,
    this.height = 95,
    this.doublePressEnable = false,
    this.returnedData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    int backTapCount = 0;

    final appbar = Container(
      height: height,
      alignment: Alignment.bottomCenter,
      child: Row(
        children: [
          IconButton(
            onPressed: () async {
              ScaffoldMessengerState scaffoldMessengerState =
                  ScaffoldMessenger.of(context);

              if (!doublePressEnable) {
                Navigator.pop(context, returnedData);
                return;
              }

              ++backTapCount;

              Future.delayed(const Duration(milliseconds: 1000)).then((_) {
                if (backTapCount >= 2) return;
                ASnackBar.showWarning(
                  scaffoldMessengerState,
                  'Please double click on back button to close this form',
                );
                backTapCount = 0;
              });

              if (backTapCount > 1) {
                if (Preference.getBool(Preference.isGuest)) {
                  Preference.setValue(Preference.isLogin, false);
                  Navigator.pushReplacementNamed(context, Routes.login);
                } else {
                  Navigator.pop(context, returnedData);
                }
              }
            }, icon: const Icon(Icons.arrow_back, color: Colors.red,),),
          AText(title, fontSize: 16, fontWeight: FontWeight.w500,),
        ],
      ),
    );

    final child0 = Padding(
      padding: EdgeInsets.only(top: height),
      child: child,
    );

    return Scaffold(
      body: Stack(
        children: [
          appbar,
          child0,
        ],
      ),
    );
  }

}