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
            await submitJobData(context);

            Navigator.pop(context);
          },
          child: const Text('Confirm 2',
              style: TextStyle(fontSize: 18, color: Colors.green)),
        ),
      ],
    );
  }
}
