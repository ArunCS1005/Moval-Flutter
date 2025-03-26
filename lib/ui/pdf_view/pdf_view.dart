import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';

import '../../api/api.dart';
import '../../widget/a_snackbar.dart';
import '../../widget/header.dart';
import '../util_ui/UiUtils.dart';

class PDFViewer extends StatefulWidget {
  const PDFViewer({super.key});

  @override
  State<PDFViewer> createState() => _PDFViewerState();
}

class _PDFViewerState extends State<PDFViewer> {
  String _title = '';
  File? _pFile;

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _getDetail();
    });
  }

  _getDetail() async {
    ScaffoldMessengerState scaffoldMessengerState =
        ScaffoldMessenger.of(context);
    NavigatorState navigatorState = Navigator.of(context);
    Map<String, dynamic> data =
        (ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?) ??
            {};

    _title = data['title'];
    _updateUi;

    final response = await Api(scaffoldMessengerState).getPdfFile(
      baseUrl: data['url'],
      jobId: data['job_id'],
      type: data['type']
    );

    if (response == Api.defaultError || response == Api.internetError) {
      ASnackBar.showSnackBar(
        scaffoldMessengerState,
        '$_title is not yet done, so please try later.',
        0,
      );
      navigatorState.pop(false);
    } else if (response == Api.authError) {
      UiUtils.authFailed(navigatorState);
    } else {
      try {
        final dir = await getApplicationDocumentsDirectory();
var file = File('${dir.path}/${data['job_id']}_${data['type']}.pdf');
        await file.writeAsBytes(response, flush: true);
        _pFile = file;
      } on Exception catch (e) {
        log('C41: $e');
        ASnackBar.showSnackBar(
          scaffoldMessengerState,
          '$_title is not yet done, so please try later.',
          0,
        );
        navigatorState.pop(false);
      }
    }

    _updateUi;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, _pFile != null);
        return false;
      },
      child: Header(
        _title,
        returnedData: _pFile != null,
        child: _pFile == null
            ? const Center(child: CircularProgressIndicator())
            : Center(
                child: PDFView(
                  filePath: _pFile!.path,
                ),
              ),
      ),
    );
  }

  get _updateUi => setState(() {});
}
