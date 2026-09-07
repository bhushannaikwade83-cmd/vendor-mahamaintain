import 'package:flutter/material.dart';
import '../config/app_theme.dart';

/// A row of individual digit boxes for OTP/M-PIN entry - auto-advances
/// focus as digits are typed, auto-retreats on backspace.
class PinBoxRow extends StatefulWidget {
  final int length;
  final bool obscure;
  final ValueChanged<String> onChanged;
  final bool small;

  const PinBoxRow({
    required this.length,
    required this.onChanged,
    this.obscure = true,
    this.small = false,
    Key? key,
  }) : super(key: key);

  @override
  State<PinBoxRow> createState() => PinBoxRowState();
}

class PinBoxRowState extends State<PinBoxRow> {
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;

  String get value => _controllers.map((c) => c.text).join();

  void clear() {
    for (final controller in _controllers) {
      controller.clear();
    }
    if (_focusNodes.isNotEmpty) _focusNodes.first.requestFocus();
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(widget.length, (_) => TextEditingController());
    _focusNodes = List.generate(widget.length, (_) => FocusNode());
    for (final focusNode in _focusNodes) {
      focusNode.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  void _onDigitChanged(int index, String digit) {
    if (digit.isNotEmpty && index < widget.length - 1) {
      _focusNodes[index + 1].requestFocus();
    }
    if (digit.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
    setState(() {});
    widget.onChanged(value);
    if (value.length == widget.length) {
      FocusScope.of(context).unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final boxSize = widget.small ? 52.0 : 64.0;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(widget.length, (index) {
        final focused = _focusNodes[index].hasFocus;
        return SizedBox(
          width: boxSize,
          height: boxSize,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(
                color: focused ? AppTheme.saffron : Colors.grey.shade200,
                width: focused ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: focused
                  ? [
                      BoxShadow(
                        color: AppTheme.saffron.withOpacity(0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : [],
            ),
            child: TextField(
              controller: _controllers[index],
              focusNode: _focusNodes[index],
              keyboardType: TextInputType.number,
              maxLength: 1,
              obscureText: widget.obscure,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: widget.small ? 20 : 24,
                fontWeight: FontWeight.bold,
              ),
              decoration: const InputDecoration(
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                counterText: '',
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: (v) => _onDigitChanged(index, v),
            ),
          ),
        );
      }),
    );
  }
}
