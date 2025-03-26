import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class JobRejected extends StatelessWidget {

  final int _jobId;
  final String _reason;

  const JobRejected(this._jobId, this._reason, {Key? key}) : super(key: key);

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
              child: SvgPicture.asset(
                'assets/images/remark-flag.svg',
                color: Colors.white,
                width: 45,
                height: 45,
              ),
            ),
            Container(
              margin: EdgeInsets.only(top: _reason.isEmpty ? 60 : 40, bottom: 10),
              padding: const EdgeInsets.only(left: 20, right: 20),
              child: Text(
                'Job No.$_jobId rejected.',
                style: const TextStyle(color: Colors.black, fontSize: 17),
                textAlign: TextAlign.center,
              ),
            ),
            Container(
              margin: EdgeInsets.only(bottom: _reason.isEmpty ? 10 : 35),
              padding: const EdgeInsets.only(left: 20, right: 20),
              child: RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    children: [
                      const TextSpan(
                        text: 'Remark: ',
                        style: TextStyle(fontSize: 17, color: Colors.black, fontWeight: FontWeight.w500),
                      ),
                      TextSpan(
                        text: _reason,
                        style: const TextStyle(fontSize: 17, color: Colors.black)
                      ),
                    ],
                  ),
              ),
            ),
            InkWell(
              onTap: ()=> Navigator.pop(context),
              child: Container(
                  decoration: BoxDecoration(color: Colors.blueAccent, borderRadius: BorderRadius.circular(45),),
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