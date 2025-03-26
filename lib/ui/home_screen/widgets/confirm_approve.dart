import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ConfirmApprove extends StatelessWidget {
  const ConfirmApprove({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoAlertDialog(
      title: const Text(
        'Are you sure you want to approve ILA?',
        style: TextStyle(fontSize: 18),
      ),
      actions: [
        CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'No',
            style: TextStyle(fontSize: 18, color: Colors.red),
          ),
        ),
        CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context, true),
          child: const Text(
            'Yes',
            style: TextStyle(fontSize: 18, color: Colors.green),
          ),
        ),
      ],
    );
  }
}
