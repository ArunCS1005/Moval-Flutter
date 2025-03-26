import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomOTPField extends StatefulWidget {
  /// Number of the OTP Fields
  final int length;

  /// Total Width of the OTP Text Field
  final double width;

  /// Width of the single OTP Field
  final double fieldWidth;

  /// margin around the text fields
  final EdgeInsetsGeometry margin;

  /// Manage the type of keyboard that shows up
  final TextInputType keyboardType;

  /// The style to use for the text being edited.
  final TextStyle style;

  /// The style to use for the text being edited.
  final double outlineBorderRadius;

  /// Text Field Alignment
  /// default: MainAxisAlignment.spaceBetween [MainAxisAlignment]
  final MainAxisAlignment textFieldAlignment;

  /// Obscure Text if data is sensitive
  final bool obscureText;

  /// Callback function, called when a change is detected to the pin.
  final ValueChanged<String>? onChanged;

  /// Callback function, called when pin is completed.
  final ValueChanged<String>? onCompleted;

  const CustomOTPField({
    super.key,
    this.length = 4,
    this.width = 10,
    this.fieldWidth = 30,
    this.margin = const EdgeInsets.symmetric(horizontal: 3),
    this.keyboardType = TextInputType.number,
    this.style = const TextStyle(),
    this.outlineBorderRadius = 10,
    this.textFieldAlignment = MainAxisAlignment.spaceBetween,
    this.obscureText = false,
    this.onChanged,
    this.onCompleted,
  }) : assert(length > 1);

  @override
  State<CustomOTPField> createState() => _CustomOTPFieldState();
}

class _CustomOTPFieldState extends State<CustomOTPField> {
  late List<FocusNode?> _focusNodes;
  late List<TextEditingController?> _textControllers;

  late List<Widget> _textFields;
  late List<String> _pin;

  @override
  void initState() {

    super.initState();

    _focusNodes = List<FocusNode?>.filled(widget.length, null, growable: false);
    _textControllers = List<TextEditingController?>.filled(widget.length, null,
        growable: false);

    _pin = List.generate(widget.length, (int i) {
      return '';
    });
    _textFields = List.generate(widget.length, (int i) {
      return buildTextField(context, i);
    });
  }

  @override
  void dispose() {
    for (var controller in _textControllers) {
      controller!.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      child: Row(
        mainAxisAlignment: widget.textFieldAlignment,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: _textFields,
      ),
    );
  }

  /// This function Build and returns individual TextField item.
  ///
  /// * Requires a build context
  /// * Requires Int position of the field
  Widget buildTextField(BuildContext context, int i) {
    if (_focusNodes[i] == null) _focusNodes[i] = FocusNode();

    if (_textControllers[i] == null) {
      _textControllers[i] = TextEditingController();
    }

    return Container(
      width: widget.fieldWidth,
      height: widget.fieldWidth,
      margin: widget.margin,
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(widget.outlineBorderRadius),
          boxShadow: const [
            BoxShadow(
              blurRadius: 4,
              color: Colors.black26,
            )
          ]),
      child: TextField(
        controller: _textControllers[i],
        keyboardType: widget.keyboardType,
        textAlign: TextAlign.center,
        style: widget.style,
        focusNode: _focusNodes[i],
        obscureText: widget.obscureText,
        inputFormatters: [
          LengthLimitingTextInputFormatter(1),
        ],
        decoration: InputDecoration(
            counterText: "",
            border: _getBorder(const Color(0x809f9f9f)),
            focusedBorder: _getBorder(Colors.blueAccent),
        ),
        onChanged: (String str) {
          if (str.length > 1) {
            _handlePaste(str);
            return;
          }

          // Check if the current value at this position is empty
          // If it is move focus to previous text field.
          if (str.isEmpty) {
            if (i == 0) return;
            _focusNodes[i]!.unfocus();
            _focusNodes[i - 1]!.requestFocus();
          }

          // Update the current pin
          setState(() {
            _pin[i] = str;
          });

          // Remove focus
          if (str.isNotEmpty) _focusNodes[i]!.unfocus();
          // Set focus to the next field if available
          if (i + 1 != widget.length && str.isNotEmpty) {
            FocusScope.of(context).requestFocus(_focusNodes[i + 1]);
          }

          String currentPin = _getCurrentPin();

          // if there are no null values that means otp is completed
          // Call the `onCompleted` callback function provided
          if (!_pin.contains(null) &&
              !_pin.contains('') &&
              currentPin.length == widget.length) {
            widget.onCompleted!(currentPin);
          }

          // Call the `onChanged` callback function
          if (widget.onChanged != null) widget.onChanged!(currentPin);
        },
      ),
    );
  }

  InputBorder _getBorder(Color color) {
    return OutlineInputBorder(
        borderSide: BorderSide(color: color, width: 3.0),
        borderRadius: BorderRadius.circular(widget.outlineBorderRadius));
  }

  String _getCurrentPin() {
    String currentPin = "";
    for (var value in _pin) {
      currentPin += value;
    }
    return currentPin;
  }

  void _handlePaste(String str) {
    if (str.length > widget.length) {
      str = str.substring(0, widget.length);
    }

    for (int i = 0; i < str.length; i++) {
      String digit = str.substring(i, i + 1);
      _textControllers[i]!.text = digit;
      _pin[i] = digit;
    }

    FocusScope.of(context).requestFocus(_focusNodes[widget.length - 1]);

    String currentPin = _getCurrentPin();

    // if there are no null values that means otp is completed
    // Call the `onCompleted` callback function provided
    if (!_pin.contains(null) &&
        !_pin.contains('') &&
        currentPin.length == widget.length) {
      widget.onCompleted!(currentPin);
    }

    // Call the `onChanged` callback function
    widget.onChanged!(currentPin);
  }
}