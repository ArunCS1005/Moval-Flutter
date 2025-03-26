import 'package:flutter/material.dart';

class AText extends StatelessWidget{

  final String text;
  final TextStyle? style;
  final Color textColor;
  final Color background;
  final double fontSize;
  final FontWeight fontWeight;
  final EdgeInsets padding;
  final EdgeInsets margin;
  final TextAlign? textAlign;

  const AText(
    this.text, {
    Key? key,
    this.style,
    this.textColor = Colors.black,
    this.background = Colors.transparent,
    this.fontSize = 16,
    this.fontWeight = FontWeight.w400,
    this.padding = const EdgeInsets.all(0),
    this.margin = const EdgeInsets.all(0),
    this.textAlign,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: background,
      padding: padding,
      margin: margin,
      child: Text(
        text,
        style: _style,
        textAlign: textAlign,
      ),
    );
  }

  get _style => style ?? TextStyle(fontSize: fontSize, fontWeight: fontWeight, color: textColor);

}