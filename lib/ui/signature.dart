import 'dart:developer';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:moval/api/urls.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_signaturepad/signaturepad.dart';

import '../api/api.dart';
import '../widget/a_snackbar.dart';
import '../widget/header.dart';

class Signature extends StatefulWidget {
  const Signature(
    this.jobId, {
    Key? key,
    required this.platform,
  }) : super(key: key);

  final int jobId;
  final String platform;

  @override
  State<StatefulWidget> createState() {
    return _Signature();
  }
}

class _Signature extends State<Signature> {

  final GlobalKey<SfSignaturePadState> _signatureGlobalKey = GlobalKey();

  bool _isConvertingImage = false;
  bool _isSignatureAdded = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final rowButtons = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
          child: _buttonClear,
          flex: 1,
        ),
        Flexible(
          child: _buttonOkay,
          flex: 1,
        ),
      ],
    );

    final rowSignature = Container(
      margin: const EdgeInsets.all(10.0),
      decoration: BoxDecoration(border: Border.all(color: Colors.redAccent)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            flex: 1,
            child: SizedBox(
              // width: width * 1,
              // height: width * 0.7,
              child: _signatureWidget,
            ),
          ),
        ],
      ),
    );

    final rowSignatureButton = Column(
      children: [
        // _rowHeading,
        rowSignature,
        const Padding(
          padding: EdgeInsets.only(top: 10),
        ),
        rowButtons,
      ],
    );

    final rowDummy = Container(
      height: 50,
    );

    // return HomeView(
    //   selectedTab: 0,
    //   showAddBtn: false,
    //   child: Header('Add Signature',
    //     child:Column(
    //       mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    //       children: [
    //         _rowSignatureButton,
    //         _rowDummy,
    //       ],
    //     ),
    //   ),
    // );

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Header(
        'Add Signature',
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            rowSignatureButton,
            rowDummy,
          ],
        ),
      ),
    );
  }


  get _signatureWidget => SfSignaturePad(
    key: _signatureGlobalKey,
    backgroundColor: Colors.white,
    strokeColor: Colors.black,
    minimumStrokeWidth: 0.5,
    maximumStrokeWidth: 4.0,
    onDrawStart: () {
      _isSignatureAdded = true;
      _updateUi();
      return false;
    },
  );


  get _buttonClear => Container(
    margin: const EdgeInsets.all(10.0),
    padding: const EdgeInsets.only(top: 10.0,bottom: 10.0),
    decoration: BoxDecoration(
        border: Border.all(color: Colors.redAccent)
    ),
    alignment: Alignment.center,
    // color: Colors.blueAccent,
    child: InkWell(
      onTap: _clearSignature,
      child: const Text(
        "Clear",
        style: TextStyle(color: Colors.redAccent, fontSize: 16),
      ),
    ),
  );


  get _buttonOkay =>
      Container(
        margin: const EdgeInsets.all(10.0),
        padding: const EdgeInsets.only(top: 10.0,bottom: 10.0),
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
            : InkWell(
          onTap: _okaySignature,
          child: const Text(
            "Okay",
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
      );

  _clearSignature() {

    _signatureGlobalKey.currentState?.clear();

    _isSignatureAdded = false;
    _updateUi();
  }

  _okaySignature() async {
    NavigatorState navigatorState = Navigator.of(context);
    ScaffoldMessengerState scaffoldMessengerState =
        ScaffoldMessenger.of(context);

    if (_isConvertingImage) return;
    _isConvertingImage = true;
    _updateUi();

    try {
      final data =
          await _signatureGlobalKey.currentState?.toImage(pixelRatio: 3.0);
      final bytes = await data?.toByteData(format: ui.ImageByteFormat.png);
      if (_isSignatureAdded) {
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

        if (response.startsWith('job_files') || response.startsWith('http')) {
          await Future.delayed(const Duration(milliseconds: 500));
          navigatorState.pop([bytes, response]);
        } else {
          _isConvertingImage = false;
          _updateUi();
          ASnackBar.showSnackBar(scaffoldMessengerState, response, 0);
        }
      }else{
        _isConvertingImage = false;
        _updateUi();
        ASnackBar.showSnackBar(
            scaffoldMessengerState, 'Add Signature before proceed', 0);
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
