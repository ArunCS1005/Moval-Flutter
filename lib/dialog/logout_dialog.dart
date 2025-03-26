import 'package:flutter/material.dart';
import 'package:moval/util/preference.dart';

import '../util/routes.dart';

class LogoutDialog extends StatefulWidget {

  const LogoutDialog({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _LogoutDialog();
  }
}

class _LogoutDialog extends State<LogoutDialog> {
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
        padding: const EdgeInsets.only(top: 30),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.all(Radius.circular(8.0)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Align(
              alignment: Alignment.center,
              child:  Text('Are you sure to Logout?',
                style: TextStyle(color: Colors.black, fontWeight: FontWeight.w300, fontSize: 18),),
            ),
            const SizedBox(height: 10,),
            const Divider(height: 1.0, color: Colors.black),
            Row(
              children: [
                Expanded(
                    child: InkWell(
                      child: const Align(
                        alignment: Alignment.center,
                        child: Text('Yes',
                          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w500, fontSize: 18),),
                      ),
                      onTap: () {
                        onClickYes();
                      },
                    )),
                const SizedBox(
                  height: 50,
                  child: VerticalDivider(
                    width: 1.0,
                    color: Colors.black,
                  ),
                ),
                Expanded(
                  child: InkWell(
                    child: const Align(
                      alignment: Alignment.center,
                      child: Text('No',
                        style: TextStyle(color: Colors.black, fontWeight: FontWeight.w500, fontSize: 18),),
                    ),
                    onTap: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
          ],
        ));
  }

  void onClickYes() {
    Preference.setValue(Preference.credential, '');
    Navigator.popUntil(context, (route) => route.isFirst);
    Navigator.pushReplacementNamed(context, Routes.login);
  }

}
