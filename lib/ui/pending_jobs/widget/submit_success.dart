import 'package:flutter/material.dart';

class SubmitSuccess extends StatelessWidget {

  final int _jobId;
  final bool _isLocal;

  const SubmitSuccess(this._jobId, this._isLocal, {Key? key}) : super(key: key);

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
              color: Colors.green,
              height: 130,
              alignment: Alignment.center,
              child: Image.asset('assets/images/success.png', height: 45, width: 45, color: Colors.white,),
            ),
            Container(
              margin: const EdgeInsets.only(top: 60, bottom: 35),
              padding: const EdgeInsets.only(left: 20, right: 20),
              child: Text(
                'Job No.${_jobId.isNegative ? 'NEW' : _jobId} ${ _isLocal ? 'save locally.' : 'submitted successfully on server.'}',
                style: const TextStyle(color: Colors.black, fontSize: 17),
                textAlign: TextAlign.center,
              ),
            ),
            InkWell(
              onTap: ()=> Navigator.pop(context),
              child: Container(
                decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(45),),
                padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 5),
                child: const Text('Okay', style: TextStyle(color: Colors.white, fontSize: 16),)),
            ),
            const SizedBox(height: 12,),
          ],
        ),
      ),
    );
  }
}