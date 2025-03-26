import 'package:flutter/cupertino.dart';

class FileUploadFailedDialog extends StatelessWidget{

  final String files;

  const FileUploadFailedDialog({Key? key, required this.files}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CupertinoAlertDialog(
      title: const Text('File upload failed', style: TextStyle(fontSize: 18),),
      content: Text('$files failed to upload.\nBefore submitting job you need to upload all mandatory files.', style: const TextStyle(fontSize: 16),),
      actions: [
        CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(fontSize: 18),),),
        CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Retry', style: TextStyle(fontSize: 18),),),
      ],
    );
  }

}