import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
class IconTabHeaderNew extends StatelessWidget{

  final String title;
  final bool active;
  final String icon;

  const IconTabHeaderNew(this.title, this.active, this.icon ,{Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      // onTap: (){},
      onTap: null,
      child: Column(children: [
        Container(width: 30, height: 30, padding: const EdgeInsets.all(5), child: SvgPicture.asset('assets/images/$icon',color: active ? Colors.black54 : Colors.black),),
        Text(title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            color: active ? Colors.black54 : Colors.black,
          ),),
      ],),
    );
  }

}