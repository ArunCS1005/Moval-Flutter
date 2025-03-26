import 'dart:async';

import 'package:flutter/material.dart';

class WaitingDialog extends StatefulWidget {

  const WaitingDialog({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _WaitingDialogState();
  }

}

class _WaitingDialogState extends State<WaitingDialog> {

  int _count = 60;

  @override
  void initState() {
    _startCountDown();
    super.initState();
  }

  _startCountDown() async {

    await Future.delayed(const Duration(seconds: 1));

    --_count;
    _updateUi;

    if (_count > 0) {
      _startCountDown();
    } else {
      Navigator.pop(context, true);
    }

  }

  get _updateUi => setState((){});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              color: Colors.redAccent,
              height: 130,
              alignment: Alignment.center,
              child: Image.asset('assets/images/location.png', height: 45, width: 45, color: Colors.white,),
            ),
            Container(
              margin: const EdgeInsets.only(top: 50, bottom: 35),
              padding: const EdgeInsets.only(left: 20, right: 20),
              child: Text(
                'Please wait, capturing your location${'.' * (4 - (_count % 4))}',
                style: const TextStyle(color: Colors.black, fontSize: 17),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 12,),
          ],
        ),
      ),
    );
  }

}


