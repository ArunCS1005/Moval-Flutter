import 'package:flutter/material.dart';
import 'package:moval/widget/a_text.dart';

class ARadioNew extends StatefulWidget {

  final String               title;
  final String               dataKey;
  final Map<String, String>  data;
  final List<String>         options;
  final bool                 horizontal;
  final String               hint;

  const ARadioNew(this.title,
      this.dataKey,
      this.data,
      this.options,
      {Key? key, this.horizontal = true, this.hint = 'Please Specify'}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _ARadioNew();
  }
}

class _ARadioNew extends State<ARadioNew> {

  int _value = -1;
  final TextEditingController _controller = TextEditingController();
  @override
  void initState() {

    if (widget.data.containsKey(widget.dataKey)) {
      _value = widget.options.indexOf(widget.data[widget.dataKey] ?? '');
      _controller.text = widget.data[widget.dataKey] ?? '';
    } else {
      widget.data[widget.dataKey] = '';
    }

    super.initState();
  }

  @override
  Widget build(BuildContext context) {

    List<Widget> children = [];

    for (int a = 0; a < widget.options.length; a++) {
      children.add(_item(widget.options[a], a == _value, _funOnItemSelect));
    }

    return Container(
      margin: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AText(widget.title, fontWeight: FontWeight.w500, margin: const EdgeInsets.only(left: 10, bottom: 5),),
          if(widget.horizontal)
            ...children,
          if(!widget.horizontal)
            Row(
              children: children,
            ),
          Visibility(visible: showOtherTextField(), child: Container(
            margin: const EdgeInsets.only(top: 10),
            decoration: const BoxDecoration(boxShadow: [
            ], color: Colors.white),
            child: TextField(
              maxLines: 1,
              controller: _controller,
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.done,
              onChanged: _onChanged,
              decoration: InputDecoration(
                isCollapsed: false,
                contentPadding: const EdgeInsets.all(10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(0)),
                hintText: widget.hint
              ),
            ),))

        ],
      ),
    );
  }

  _funOnItemSelect(String item) {

    _value = widget.options.indexOf(item);
    widget.data[widget.dataKey] = item;

    _funUpdateUi();
  }

  _funUpdateUi(){
    setState(() {});
  }

  _item(String item, bool selected, Function(String) onTap) => Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      InkWell(
        onTap: (){
          onTap.call(item);
        },
        child: Container(
          margin: const EdgeInsets.fromLTRB(10, 4, 15, 4),
          width: 18,
          height: 18,
          decoration: BoxDecoration(
              color: selected ? Colors.green : Colors.white,
              border: Border.all(color:  selected ? Colors.green : Colors.black),
              borderRadius: BorderRadius.circular(180),
              boxShadow: const [
                BoxShadow(
                  blurRadius: 4,
                  color: Colors.black45,
                  offset: Offset(1, 2),
                )
              ]
          ),
        ),
      ),
      AText(item, fontSize: 15,),
    ],
  );

  showOtherTextField() {
    if(widget.data[widget.dataKey] == 'Others'){
      return true;
    }else{
      return false;
    }
  }


  void _onChanged(String value) {
    widget.data[widget.dataKey] = value;
    if(value.isEmpty){
      widget.data[widget.dataKey] = 'Others';
    }
  }
}