import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quick_mart_admin/home.dart'; // Assuming this path is correct

class MyTextfield extends StatelessWidget {
  final TextEditingController controller;
  final String? labelText; // Changed to nullable String for labelText
  final String? hintText; // Added hintText as optional for flexibility
  final bool obscureText;
  final IconData? icon; // Changed to nullable IconData to make icon optional
  final String? Function(String?)? validator;
  final TextInputType keyboardType;
  final double? height; // Added height property
  final double? width; // Added width property

  const MyTextfield({
    Key? key,
    required this.controller,
    this.labelText, // Initialize labelText
    this.hintText, // Initialize hintText
    this.icon, // Initialize icon
    this.obscureText = false,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.height, // Initialize height
    this.width, // Initialize width
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Removed the internal Padding here. The overall form padding will handle spacing.
    return SizedBox(
      height: height,
      width: width,
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(
          prefixIcon: icon != null ? Icon(icon, color: Colors.black54) : null,
          labelText: labelText,
          hintText: labelText == null ? hintText : null,
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.black.withAlpha((255 * 0.6).round())),
            borderRadius: BorderRadius.circular(10),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.black),
            borderRadius: BorderRadius.circular(10),
          ),
          // Added errorBorder for red border when validation fails
          errorBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.red, width: 2.0),
            borderRadius: BorderRadius.circular(10),
          ),
          // Added focusedErrorBorder for red border when focused and validation fails
          focusedErrorBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.red, width: 2.0),
            borderRadius: BorderRadius.circular(10),
          ),
          fillColor: Colors.white,
          filled: true,
          hintStyle: const TextStyle(color: Colors.grey),
          // The error text is automatically displayed by TextFormField if validator returns a non-null string
        ),
      ),
    );
  }
}