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

class SubmitDataDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CupertinoAlertDialog(
      title:
          const Text('Confirm to submit job', style: TextStyle(fontSize: 18)),
      actions: [
        CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('Review',
              style: TextStyle(fontSize: 18, color: Colors.red)),
        ),
        CupertinoActionSheetAction(
          onPressed: () async {
            // Close the dialog first
            Navigator.pop(context);
            // Submit the job data
            await submitJobData(context);
            // Navigate back to pending jobs page with a simple pop until
            // instead of using popUntil and pushReplacement which can cause black screen
            Navigator.of(context).popUntil((route) {
              return route.settings.name == '/pendingJobs' || route.isFirst;
            });
            // Refresh the jobs list
            Navigator.of(context).pushReplacementNamed('/pendingJobs', arguments: 'refresh');
          },
          child: const Text('Confirm',
              style: TextStyle(fontSize: 18, color: Colors.green)),
        ),
      ],
    );
  }
}
