import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:moval/widget/a_text.dart';

class PermissionDialog extends StatelessWidget {
  final String title;
  final String message;
  final String action;
  final Function()? onActionPosition;

  const PermissionDialog(
      this.title,
      this.message,
      this.action,
      {Key? key, this.onActionPosition,}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CupertinoAlertDialog(
      title: AText(
        title,
        textColor: Colors.black,
        fontSize: 17,
        fontWeight: FontWeight.w500,
      ),
      content: AText(message),
      actions: [
        CupertinoDialogAction(
          onPressed: onActionPosition,
          child: AText(action),
        ),
        CupertinoDialogAction(
          child: const AText("Close"),
          onPressed: () {
            Navigator.pop(context, 'n');
          },
        ),
      ],
    );
  }
}
