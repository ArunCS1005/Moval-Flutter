import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:moval/api/urls.dart';
import 'package:moval/util/preference.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_signaturepad/signaturepad.dart';

import '../api/api.dart';
import '../util/routes.dart';
import '../widget/a_snackbar.dart';

class SignatureDialog extends StatefulWidget {
  final int jobId;
  final String platform;

  const SignatureDialog(
    this.jobId, {
    Key? key,
    required this.platform,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _SignatureDialog();
  }
}

class _SignatureDialog extends State<SignatureDialog> {
  final GlobalKey<SfSignaturePadState> _signatureGlobalKey = GlobalKey();

  bool _isConvertingImage = false;

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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Align(
              alignment: Alignment.topRight,
              child: InkWell(
                onTap: () => Navigator.pop(context),
                child: Container(
                  margin: const EdgeInsets.only(top: 5.0, right: 5.0),
                  padding: const EdgeInsets.all(5.0),
                  decoration: const BoxDecoration(
                    color: Colors.redAccent,
                    borderRadius: BorderRadius.all(Radius.circular(8.0)),
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
            const Align(
              alignment: Alignment.center,
              child: Text(
                'Add Signature',
                style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w300,
                    fontSize: 18),
              ),
            ),
            Container(
              margin: const EdgeInsets.all(10.0),
              decoration:
                  BoxDecoration(border: Border.all(color: Colors.redAccent)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    flex: 1,
                    child: SizedBox(
                      // width: width * 1,
                      // height: width * 0.7,
                      child: SfSignaturePad(
                        key: _signatureGlobalKey,
                        backgroundColor: Colors.white,
                        strokeColor: Colors.black,
                        minimumStrokeWidth: 0.5,
                        maximumStrokeWidth: 4.0,
                      ),
                    ),),

                ],
              ),),
            const Padding(padding: EdgeInsets.only(top: 10),),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  flex: 1,
                  child: Container(
                    margin: const EdgeInsets.all(10.0),
                    padding: const EdgeInsets.only(top: 10.0, bottom: 10.0),
                    decoration: BoxDecoration(
                        border: Border.all(color: Colors.redAccent)),
                    alignment: Alignment.center,
                    // color: Colors.blueAccent,
                    child: InkWell(
                      onTap: _clearSignature,
                      child: const Text(
                        "Clear",
                        style: TextStyle(color: Colors.redAccent, fontSize: 16),
                      ),
                    ),
                  ),
                ),
                InkWell(
                  onTap: _okaySignature,
                  child: Flexible(
                    flex: 1,
                    child: Container(
                      margin: const EdgeInsets.all(10.0),
                      padding: const EdgeInsets.only(top: 10.0, bottom: 10.0),
                      alignment: Alignment.center,
                      color: Colors.redAccent,
                      child: _isConvertingImage
                          ? const SizedBox(
                              width: 26,
                              height: 26,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Text(
                              "Okay",
                              style:
                                  TextStyle(color: Colors.white, fontSize: 16),
                            ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10,),
          ],
        ));
  }

  void onClickYes() {
    Preference.setValue(Preference.credential, '');
    Navigator.popUntil(context, (route) => route.isFirst);
    Navigator.pushReplacementNamed(context, Routes.login);
  }


  _clearSignature() {
    _signatureGlobalKey.currentState?.clear();
  }

  _okaySignature() async {
    ScaffoldMessengerState scaffoldMessengerState =
        ScaffoldMessenger.of(context);
    NavigatorState navigatorState = Navigator.of(context);

    if (_isConvertingImage) return;
    _isConvertingImage = true;
    _updateUi();

    try {
      final data =
          await _signatureGlobalKey.currentState?.toImage(pixelRatio: 3.0);
      final bytes = await data?.toByteData(format: ui.ImageByteFormat.png);

      String tempPath = (await getTemporaryDirectory()).path;
      File file = File('$tempPath/signature.png');
      await file.writeAsBytes(
          bytes!.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes));
      String response = (widget.platform == platformTypeMS)
          ? await Api(scaffoldMessengerState).uploadMSFile(
              file: file,
            )
          : await Api(scaffoldMessengerState).uploadMVFile(
              jobId: widget.jobId,
              type: 'Vehicle Owner Image',
              file: file,
            );

      if (response.startsWith('job_files')) {
        await Future.delayed(const Duration(milliseconds: 500));
        navigatorState.pop(bytes);
      } else {
        _isConvertingImage = false;
        _updateUi();
        ASnackBar.showSnackBar(scaffoldMessengerState, response, 0);
      }
    }catch(e){
      log(e.toString());
      _isConvertingImage = false;
      _updateUi();
    }
  }

  _updateUi(){
    setState(() {});
  }


}
