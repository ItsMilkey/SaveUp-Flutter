import 'package:flutter/material.dart';

/// Campo de texto neo-brutalista (la decoración vive en el tema).
class NeoInput extends StatelessWidget {
  const NeoInput({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.error,
    this.helper,
    this.prefixIcon,
    this.suffixIcon,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.obscureText = false,
    this.autocorrect = true,
    this.enableSuggestions = true,
    this.onChanged,
    this.validator,
    this.enabled = true,
    this.autofocus = false,
    this.errorMaxLines,
  });

  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final String? error;
  final String? helper;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final bool obscureText;
  final bool autocorrect;
  final bool enableSuggestions;
  final ValueChanged<String>? onChanged;
  final String? Function(String?)? validator;
  final bool enabled;
  final bool autofocus;
  final int? errorMaxLines;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      autofillHints: autofillHints,
      obscureText: obscureText,
      autocorrect: autocorrect,
      enableSuggestions: enableSuggestions,
      onChanged: onChanged,
      validator: validator,
      enabled: enabled,
      autofocus: autofocus,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        errorText: error,
        helperText: helper,
        prefixIcon: prefixIcon == null ? null : Icon(prefixIcon),
        suffixIcon: suffixIcon,
        errorMaxLines: errorMaxLines,
      ),
    );
  }
}
