import 'package:flutter/cupertino.dart';

class ITextFields{
  static labelText({required String labelText}){
    return      Padding(
      padding: const EdgeInsets.only(left: 10.0,bottom: 8),
      child: Text(labelText,style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500
      ),),
    );
  }
}