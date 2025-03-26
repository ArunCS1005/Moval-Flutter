import 'package:flutter/material.dart';

class CredentialContainer extends StatelessWidget{

  final String title;
  final String description;
  final List<Widget> children;

  const CredentialContainer(this.title, this.description, this.children, {Key? key}) : super(key: key);

  final titleTextStyle = const TextStyle(fontSize: 27, fontWeight: FontWeight.w600);
  final descriptionTextStyle = const TextStyle(fontSize: 14, fontWeight: FontWeight.w400);

  @override
  Widget build(BuildContext context) {

    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.only(left: size.width * 0.08, top: size.height * 0.15, right: size.width * 0.08),
          child: Stack(
            children: [
              header,
              _child(size.height),
            ],
          ),
        ),
      ),
    );
  }


  get header => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: titleTextStyle,),
      divider,
      Text(description, style: descriptionTextStyle,),
    ],
  );


  get divider => const SizedBox(
        width: 60,
        height: 15,
        child: Divider(
          color: Colors.red,
          thickness: 4,
        ),
      );

  _child(height) => Container(
    margin: EdgeInsets.only(top: height * 0.15 + 30),
    child: Column(
      children: children,
    ),
  );
}