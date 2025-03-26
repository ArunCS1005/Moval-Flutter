
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

class EditText extends StatefulWidget {

  final Map data;
  final String hint;
  final String dataKey;
  final bool obscure;
  final bool number;
  final bool email;
  final bool enableShadow;
  final int  lines;
  final EdgeInsets margin;
  final String icon;
  final Function? onSubmitted;
  final bool isEnable;
  final int limit;
  final bool isCapital;
  final bool isTitleCase;
  final EditTextController? controller;

  const EditText(
      this.hint,
      this.dataKey,
      this.data,
      {
        Key? key,
        this.obscure = false,
        this.number  = false,
        this.email   = false,
        this.enableShadow = false,
        this.lines   = 1,
        this.margin  = const EdgeInsets.only(top: 10),
        this.onSubmitted,
        this.icon = '',
        this.isEnable = true,
        this.limit = 0,
        this.controller,
        this.isCapital = false,
        this.isTitleCase = false,
      }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _State();
  }
}

class _State extends State<EditText> {

  final TextEditingController _controller = TextEditingController();

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
    widget.data.putIfAbsent(widget.dataKey, () => _data);
    await Future.delayed(const Duration(milliseconds: 75));
    _listener();
    widget.controller?.addListener(widget.dataKey, _listener);
  }

  _listener() {
    _controller.text = _data;
    _controller.selection = TextSelection.fromPosition(TextPosition(offset: _controller.text.length));
    _updateUi;
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
      child: TextField(
        maxLength: widget.limit == 0 ? null : widget.limit,
        enabled: widget.isEnable,
        inputFormatters: setInputFormatter(),
        textCapitalization: _funCapitalText(),
        maxLines: widget.lines,
        controller: _controller,
        obscureText: widget.obscure,
        keyboardType: _funTextInputType(),
        textInputAction: _funTextInputAction(),
        onSubmitted: _funOnSubmitted,
        onChanged: _funOnTextChanged,
        decoration: InputDecoration(
            isCollapsed: widget.icon.isEmpty ? true : false,
            contentPadding: const EdgeInsets.all(10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(0)),
            hintText: widget.hint,
            prefixIcon: _funGetPrefixIcon(),
            counterText: '',
        ),
      ),
    );
  }

  _funGetPrefixIcon() {

    if(widget.icon.endsWith('.png')) {
      return Image.asset('assets/images/${widget.icon}');
    } else if(widget.icon.endsWith('.svg')) {
      return Container(width: 40, height: 40, padding: const EdgeInsets.all(13), child: SvgPicture.asset('assets/images/${widget.icon}',),);
    } else {
      return null;
    }

  }

  _funOnSubmitted(String? value){
    widget.onSubmitted?.call();
  }

  _funTextInputType() {
    if (widget.number) {
      return TextInputType.number;
    } else if (widget.email) {
      return TextInputType.emailAddress;
    } else if (widget.lines != 1) {
      return TextInputType.multiline;
    } else {
      return TextInputType.text;
    }
  }

  _funTextInputAction() {
    if(widget.lines != 1) {
      return TextInputAction.newline;
    }else if(widget.onSubmitted == null){
      return TextInputAction.next;
    }else {
      return TextInputAction.done;
    }
  }

  _funOnTextChanged(String value) {
    widget.data[widget.dataKey] = value;
  }

  get _data => widget.data[widget.dataKey] ?? '';

  get _updateUi => setState((){});


  _funCapitalText() {
    if (widget.isCapital) {
      return TextCapitalization.characters;
    } else {
      return TextCapitalization.none;
    }
  }


  setInputFormatter() {
    if (widget.isCapital) {
      return [UpperCaseTextFormatter()];
    } else if (widget.isTitleCase) {
      return [TitleCaseTextFormatter()];
    } else {
      return null;
    }
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}

class TitleCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    return TextEditingValue(
      text: newValue.text.toTitleCase(),
      selection: newValue.selection,
    );
  }
}

extension StringCasingExtension on String {

  String toCapitalized() =>
      length > 0 ? '${this[0].toUpperCase()}${substring(1).toLowerCase()}' : '';

  String toTitleCase() =>
      replaceAll(RegExp(' +'), ' ').split(' ')
          .map((str) => str.toCapitalized())
          .join(' ');

}


class EditTextController {

  final Map _listeners = {};

  addListener(String key, Function listener) {
    _listeners[key] = listener;
  }

  invalidate(String key) {
    _listeners[key]?.call();
  }

  invalidateAll() {
    _listeners.forEach((key, value) => value.call());
  }

  dispose(String key) {
    _listeners.remove(key);
  }

}
