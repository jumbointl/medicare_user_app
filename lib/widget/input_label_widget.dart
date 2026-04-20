import 'package:flutter/material.dart';

class InputLabel{

  static Widget  buildLabelBox(String labelText){
    return Text(labelText,
    style: const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500
    ),
    );
  }
}