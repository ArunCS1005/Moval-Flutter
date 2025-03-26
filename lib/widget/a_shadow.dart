import 'package:flutter/material.dart';

class AShadow extends StatelessWidget{

  final Color background;
  final Color color;
  final double height;
  final double radius;
  final double range;

  const AShadow({Key? key,
    this.background = Colors.white,
    this.color = Colors.black,
    this.height = 3,
    this.radius = 4,
    this.range = 2, }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          height: height,
          decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                    blurRadius: radius,
                    offset: Offset(0, range)
                ),
              ]
          ),
        ),
        Container(
          height: height * 2,
          color: Colors.white,
        ),
      ],
    );
  }

}