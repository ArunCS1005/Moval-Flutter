import 'package:flutter/material.dart';

import '../util_ui/UiUtils.dart';

class ProfileItem extends StatelessWidget{

  final String title;
  final EdgeInsets margin;
  final EdgeInsets padding;
  final Function()? onTap;
  final String img;
  const ProfileItem(this.title,
      {Key? key,
        this.onTap,
        this.margin = const EdgeInsets.only(top: 10),
        this.padding = const EdgeInsets.all(10),
        this.img = '',
      }
      ) : super(key: key);

  @override
  Widget build(BuildContext context) {


    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.maxFinite,
        margin: margin,
        padding: padding,
        decoration: UiUtils.decoration(),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          children: [
            Image(
                height: 24,
                width: 24,
                image: ExactAssetImage(
                  'assets/images/$img',
                )),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w500,
                  fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }

}