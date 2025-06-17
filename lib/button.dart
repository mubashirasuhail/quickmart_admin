import 'package:flutter/material.dart';

class Mybutton extends StatelessWidget {
  final Function()? onTap;
  final String buttonText;
  final double? height; // Added height for consistency
  final double? width; // Added width for consistency

  const Mybutton({
    super.key,
    required this.onTap,
    required this.buttonText,
    this.height, // Initialize height
    this.width, // Initialize width
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height ?? 60, // Use provided height or default to 60
        width: width ?? double.infinity, // Use provided width or default to full width
        padding: const EdgeInsets.all(20),
        // Removed the horizontal margin here to align with MyTextfield's new layout
        decoration: BoxDecoration(
            color:Theme.of(context).primaryColor,  borderRadius: BorderRadius.circular(10)),
        child: Center(
          child: Text(
            buttonText,
            style: const TextStyle(
                 color: Colors.white ,
              fontSize: 16, // Adjust the size as needed
              //fontWeight: FontWeight.bold
            ),
          ),
        ),
      ),
    );
  }
}