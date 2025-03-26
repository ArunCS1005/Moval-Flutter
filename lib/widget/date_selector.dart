import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DateSelector extends StatefulWidget{

  final EdgeInsets margin;
  final bool enableShadow;
  final int maxYear;
  final Map data;
  final String hint;
  final String dataKey;
  final DateController? controller;
  final String visibleDateFormat;
  final String savedDateFormat;
  final bool isEnabled;

  const DateSelector(
    this.hint,
    this.dataKey,
    this.data, {
    Key? key,
    this.margin = const EdgeInsets.only(top: 10),
    this.enableShadow = false,
    this.maxYear = 2050,
    this.controller,
    this.visibleDateFormat = 'dd/MM/yyyy',
    this.savedDateFormat = 'yyyy-MM-dd',
    this.isEnabled = true,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _DateSelector();
  }
}

class _DateSelector extends State<DateSelector> {

  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {

    widget.controller?.addListener(widget.dataKey, _updateWidget);
    widget.data.putIfAbsent(widget.dataKey, ()=> _data);

    super.initState();
  }

  @override
  void dispose() {
    widget.controller?.dispose(widget.dataKey);
    super.dispose();
  }

  _updateWidget() {
    if (_data.isEmpty) return;

    _controller.text = DateFormat(widget.visibleDateFormat)
        .format(DateFormat(widget.savedDateFormat).parse(_data));
    _updateUi;
  }

  get _updateUi => setState((){});

  selectDate() async {
    DateTime? dateTime = await showDatePicker(
      context: context,
      initialDate: _data.isEmpty
          ? DateTime.now()
          : DateFormat(widget.savedDateFormat).parse(_data),
      initialEntryMode: DatePickerEntryMode.calendar,
      firstDate: DateTime(1900),
      lastDate: DateTime(widget.maxYear),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.red, // header background color
              onPrimary: Colors.white, // header text color
              onSurface: Colors.black, // body text color
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.red, // button text color
              ),
            ),
          ),
          child: child!,
        );
      },);
    if(dateTime != null) {
      _controller.text = DateFormat(widget.visibleDateFormat).format(dateTime);
      widget.data[widget.dataKey] = DateFormat(widget.savedDateFormat).format(dateTime);
      setState(() {});
    }
  }


  @override
  Widget build(BuildContext context) {
    return Container(
      margin: widget.margin,
      decoration: BoxDecoration(boxShadow: [
        if (widget.enableShadow)
          const BoxShadow(
            color: Colors.black38,
            blurRadius: 4,
          ),
      ], color: Colors.white),
      child: TextFormField(
        enabled: widget.isEnabled,
        focusNode: AlwaysDisabledFocusNode(),
        maxLines: 1,
        controller: _controller,
        keyboardType: TextInputType.number,
        textInputAction: TextInputAction.next,
        onChanged: _funOnTextChanged,
        decoration: InputDecoration(
          isCollapsed: true,
          contentPadding: const EdgeInsets.all(10),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(0)),
          hintText: widget.hint,
        ),
        onTap: () {
          if (widget.isEnabled) selectDate();
        },
      ),
    );
               // onTap: selectDate,);
  }

  _funOnTextChanged(String value) {
    widget.data[widget.dataKey] = value;
  }

  get _data => widget.data[widget.dataKey] ?? '';

}

class AlwaysDisabledFocusNode extends FocusNode {
  @override
  bool get hasFocus => false;
}

class DateController {

  final _listener = {};

  addListener(String key, Function() listener) {
    _listener[key] = listener;
  }

  invalidateAll() {
    for(var key in _listener.keys) {
      _listener[key]?.call();
    }
  }

  dispose(String key) => _listener.remove(key);

}