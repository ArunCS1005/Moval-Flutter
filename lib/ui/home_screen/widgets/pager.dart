import 'package:flutter/material.dart';

class Pager extends StatelessWidget {

  const Pager({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return _Header(Container());
  }

}

class _Header extends StatefulWidget {

  final Widget _child;

  const _Header(this._child);

  @override
  State<StatefulWidget> createState() {
    return _HeaderState();
  }

}

class _HeaderState extends State<_Header>{
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _searchRow,
        _dateSelectionRow,
      ],
    );
  }

  get _searchRow => Row(
    children: [
      Container(),
      Expanded(child: Container(color: Colors.red,),),
      Container()
    ],
  );

  get _dateSelectionRow => {};

}

