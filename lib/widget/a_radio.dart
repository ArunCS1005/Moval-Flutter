
import 'package:flutter/material.dart';
import 'package:moval/widget/a_text.dart';

class ARadio extends StatefulWidget {

  final String               title;
  final String               dataKey;
  final Map                  data;
  final List<String>         options;
  final bool                 byIndex;
  final bool                 horizontal;
  final RadioController?     controller;

  const ARadio(this.title,
      this.dataKey,
      this.data,
      this.options,
      {Key? key,
        this.horizontal = true,
        this.byIndex    = false,
        this.controller
      }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _ARadio();
  }
}

class _ARadio extends State<ARadio> {

  @override
  void initState() {
    _initiateWidget();
    super.initState();
  }


  @override
  void dispose() {
    widget.controller?.dispose(widget.dataKey);
    super.dispose();
  }

  _initiateWidget() async {

    await Future.delayed(const Duration(milliseconds: 75));
    widget.data.putIfAbsent(widget.dataKey, () => _data);
    widget.controller?.addListener(widget.dataKey, () => _updateUi);

    _updateUi;
  }


  @override
  Widget build(BuildContext context) {

    List<Widget> children = [];

    for (int a = 0; a < widget.options.length; a++) {
      if (widget.byIndex) {
        children.add(_item(widget.options[a], a == (_index == 1 ? 0 : _index == 0 ? 1 : _index), _funOnItemSelect));
      } else {
        children.add(_item(widget.options[a], a == _index, _funOnItemSelect));
      }
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
        ],
      ),
    );
  }

  _funOnItemSelect(String item) {

    widget.data[widget.dataKey] = widget.byIndex
        ? (widget.options.indexOf(item) == 1 ? 0 : 1).toString()
        : item;

    widget.controller?.invalidateHandler(widget.dataKey, _data);
    _updateUi;
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

  get _updateUi => setState((){});

  get _data => widget.data[widget.dataKey] ?? (widget.byIndex ? '-1' : '');

  get _index => widget.byIndex
      ? int.parse(_data.isEmpty ? '-1' : _data)
      : widget.options.indexOf(_data);

}


class RadioController {

  static get saveToLocalKey => '_saveToLocal';
  static get _handlerKey    => '_handler';

  final _listeners = {};

  addListener(String key, Function() listener) {
    _listeners[key] = listener;
  }

  addHandler(Function(String key, dynamic value) handler) {
    _listeners[_handlerKey] = handler;
  }

  invalidateAll() {
    for (var _key in _listeners.keys) {
      if (_key == saveToLocalKey || _key == _handlerKey) continue;
      _listeners[_key]?.call();
    }
  }

  saveToLocal() {
    _listeners[saveToLocalKey]?.call();
  }

  invalidateHandler(String k, dynamic v) {
    _listeners[_handlerKey]?.call(k, v);
  }

  dispose(String key) {
    _listeners.remove(key);
  }

}