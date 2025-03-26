import 'package:flutter/material.dart';
import 'package:moval/widget/a_text.dart';

class ADropDown extends StatefulWidget {

  final String               text;
  final String               dataKey;
  final Map<String, String>  data;
  final List<String>         options;

  const ADropDown(
    this.text,
    this.dataKey,
    this.data,
    this.options, {
    Key? key,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _ADropDown();
  }
}

class _ADropDown extends State<ADropDown> {

  String? _value;

  @override
  void initState() {

    if (widget.data.containsKey(widget.data)) {
      _value = widget.data[widget.dataKey];
    } else {
      widget.data[widget.dataKey] = '';
    }

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        margin: const EdgeInsets.only(top: 10),
        child: DropdownButtonFormField(
          value: _value,
          icon: _icon,
          onChanged: _funOnChanged,
          hint: AText(widget.text, textColor: const Color.fromARGB(165, 0, 0, 0),),
          decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(0),),
              isCollapsed: true,
              contentPadding: const EdgeInsets.all(10),
          ),
          items: [
            for(int a = 0; a< widget.options.length; a++)
              DropdownMenuItem(value: widget.options[a],child: AText(widget.options[a]),),
          ],
        ),
    );
  }

  _funOnChanged(String? value) {
    widget.data[widget.dataKey] = value ?? '';
  }

  get _icon => const Icon(
    Icons.keyboard_arrow_down_sharp,
    color: Colors.red,
  );

}
