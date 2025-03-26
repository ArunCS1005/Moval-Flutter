import 'package:flutter/material.dart';

class Button extends StatelessWidget{

  final String title;
  final EdgeInsets margin;
  final void Function()? onTap;
  final bool progress;
  final bool enable;

  const Button(this.title,
      {Key? key,
        this.onTap,
        this.margin = const EdgeInsets.only(top: 10),
        this.progress = false,
        this.enable = true,
      }
      ) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      height: 46,
      child: InkWell(
        onTap: enable ? onTap : null,
        child: Container(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(4), color: enable ? Colors.red : Colors.black38),
          alignment: Alignment.center,
          child: child,
        ),
      ),
    );
  }


  get child => progress
      ? const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 1.8, color: Colors.white,),)
      : Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 16),);

}