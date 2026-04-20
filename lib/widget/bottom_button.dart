import 'package:flutter/material.dart';
import '../utilities/colors_constant.dart';

class IBottomNavBarWidget extends StatelessWidget {
  final String? title;
  final  Function()? onPressed;
  const IBottomNavBarWidget({super.key, this.title, this.onPressed});
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
          padding: const EdgeInsets.only(
              left: 20.0, right: 20, top: 8.0, bottom: 8.0),
          child: SizedBox(
            height: 35,
            width: MediaQuery.of(context).size.width,
            child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorResources.btnColor,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5.0)),
                ),
                onPressed:  onPressed,
                child: Center(
                    child: Text(title??"",
                        style: const TextStyle(
                          color: Colors.white,
                        )))
            ),
          )
      ),
    );
  }
}