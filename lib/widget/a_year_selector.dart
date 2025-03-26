import 'package:flutter/material.dart';
import 'package:dropdown_search/dropdown_search.dart';

class AYearSelector extends StatefulWidget {
  final String text;
  final String dataKey;
  final Map<String, String> data;
  final int maxYear;
  const AYearSelector(
    this.text,
    this.dataKey,
    this.data,
    this.maxYear, {
    super.key,
  });

  @override
  State<StatefulWidget> createState() {
    return _AYearSelector();
  }
}

class _AYearSelector extends State<AYearSelector> {
  String? _value;
  @override
  void initState() {
    if (widget.data.containsKey(widget.dataKey)) {
      _value = widget.data[widget.dataKey];
    } else {
      widget.data[widget.dataKey] = '';
    }

    super.initState();
  }

  List<String> newMethod() =>
      [for (int a = 1900; a < widget.maxYear; a++) a.toString()];

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      child: DropdownSearch<String>(
        selectedItem: _value,
        items: (str, prop) {
          return [];
        },
        popupProps: const PopupProps.menu(
          showSearchBox: true,
          showSelectedItems: true,
        ),
        decoratorProps: DropDownDecoratorProps(
          decoration: InputDecoration(
            icon: _icon,
            hintText: widget.text,
            hintStyle: const TextStyle(
              color: Color.fromARGB(165, 0, 0, 0),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(0),
            ),
            isCollapsed: true,
            contentPadding: const EdgeInsets.only(left: 10),
          ),
        ),
        onChanged: _funOnChanged,
      ),
    );
  }

  void _funOnChanged(String? value) {
    setState(() {
      widget.data[widget.dataKey] = value ?? '';
    });
  }

  Icon get _icon => const Icon(
        Icons.keyboard_arrow_down_sharp,
        color: Colors.red,
      );
}