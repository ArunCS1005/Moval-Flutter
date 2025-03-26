import 'package:flutter/material.dart';
import 'package:moval/widget/a_text.dart';

class Loader extends StatefulWidget {
  final String mText;
  const Loader(this.mText,
      {Key? key,}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return LoaderState();
  }
}
class LoaderState extends State<Loader> {
  @override
  Widget build(BuildContext context) {
    return Center(
        child: Column(children: [
            const CircularProgressIndicator(
                backgroundColor: Colors.red,
                valueColor:AlwaysStoppedAnimation<Color>(Colors.grey),),
            const SizedBox(height: 10.0,),
            AText(widget.mText,textColor: Colors.black,fontSize: 18,fontWeight: FontWeight.w500,),
        ],)
    );
  }
}