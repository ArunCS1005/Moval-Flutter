import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../util/job_submit_service.dart';

class SubmitConfimationDialog extends StatelessWidget {

  const SubmitConfimationDialog({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return CupertinoAlertDialog(
      title: const Text('Confirm to submit job', style: TextStyle(fontSize: 18),),
      actions: [
        CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('Review', style: TextStyle(fontSize: 18, color: Colors.red),),),
        CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context, true),
          child: const Text(
            'Confirm 1',
            style: TextStyle(fontSize: 18, color: Colors.green),
          ),
        ),
      ],
    );
  }
}

class SubmitDataDialog extends StatefulWidget {
  @override
  _SubmitDataDialogState createState() => _SubmitDataDialogState();
}

class _SubmitDataDialogState extends State<SubmitDataDialog> {
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    return CupertinoAlertDialog(
      title: const Text('Confirm to submit job', style: TextStyle(fontSize: 18)),
      actions: [
        CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('Review',
              style: TextStyle(fontSize: 18, color: Colors.red)),
        ),
        _isSubmitting
            ? Container(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              )
            : CupertinoActionSheetAction(
                onPressed: () async {
                  setState(() {
                    _isSubmitting = true;
                  });
                  
                  try {
                    await submitJobData(context);
                    
                    Navigator.pop(context);
                    Navigator.of(context).popUntil((route) {
                      return route.settings.name == '/pendingJobs' || route.isFirst;
                    });
                  } catch (e) {
                    // In case of error, allow the user to retry
                    setState(() {
                      _isSubmitting = false;
                    });
                  }
                },
                child: const Text('Confirm',
                    style: TextStyle(fontSize: 18, color: Colors.green)),
              ),
      ],
    );
  }
}
