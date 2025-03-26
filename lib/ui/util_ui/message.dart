import 'package:flutter/material.dart';

class Message extends StatelessWidget {

  final String msg;
  final String btn;
  final Function()? onTap;
  final bool scrollable;

  const Message(this.msg,
      {Key? key,
        this.btn = '',
        this.onTap,
        this.scrollable = false})
      : super(key: key);

  @override
  Widget build(BuildContext context) {

    final items = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          msg,
          style: const TextStyle(
            fontSize: 18,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10,),
        if (btn.isNotEmpty)
          TextButton(
            onPressed: onTap,
            style: ButtonStyle(
              backgroundColor: MaterialStateProperty.all(Colors.blue),
              padding: MaterialStateProperty.all(
                const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
              ),
            ),
            child: Text(
              btn,
              style: const TextStyle(color: Colors.white),
            ),
          ),
      ],
    );


    return LayoutBuilder(
      builder: (context, constraints) {
        return scrollable
            ? SingleChildScrollView(
                physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                child: Container(
                  width: constraints.maxWidth,
                  height: constraints.maxHeight,
                  padding: EdgeInsets.zero,
                  child: items,
                ),
              )
            : items;
      },
    );
  }

}
