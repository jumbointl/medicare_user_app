import 'package:flutter/material.dart';
import '../helpers/theme_helper.dart';

class ISearchBox{
  static buildSearchBox({required TextEditingController? textEditingController,String? labelText,onFieldSubmitted, onChanged,suffixIcon})
  {
   return  Container(
      decoration: ThemeHelper().inputBoxDecorationShaddow(),
      child: TextFormField(
        onFieldSubmitted: (value){onFieldSubmitted();},
        onChanged: (value){onChanged();},
        keyboardType: TextInputType.name,
        controller: textEditingController,
        decoration: ThemeHelper().textInputDecoration(labelText??"",const Icon(Icons.search),suffixIcon),
      ),
    );
  }
  static buildSearchBoxOnTap({required TextEditingController? textEditingController,String? labelText,onTap,suffixIcon}){
    return  Container(
      decoration: ThemeHelper().inputBoxDecorationShaddow(),
      child: TextFormField(
        readOnly: true,
        onTap:(){ onTap();},
        keyboardType: TextInputType.name,
        controller: textEditingController,
        decoration: ThemeHelper().textInputDecoration(labelText??"",const Icon(Icons.search),suffixIcon),
      ),
    );
  }
  static buildSearchBoxMap({required TextEditingController? textEditingController,String? labelText,Function()?onTap,
    bool? disabled}){
    return  Container(
      decoration: ThemeHelper().inputBoxDecorationShaddow(),
      child: TextFormField(
        onTap:onTap ,
        keyboardType: TextInputType.name,
        controller: textEditingController,
        decoration: ThemeHelper().textInputDecoration(labelText??"",const Icon(Icons.search)),
        readOnly: disabled??false,
      ),
    );
  }
}

