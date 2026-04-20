import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import '../utilities/image_constants.dart';

class NoDataWidget extends StatelessWidget {
  const NoDataWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            height: 250,
            width: 250,
            child:
            //Container(color: Colors.red,)
            SvgPicture.asset(ImageConstants.noDataImage,
                semanticsLabel: 'Acme Logo'
            ),
          ),
          const SizedBox(height: 20),
          Text("no_data_found!".tr,style: const TextStyle(
            fontFamily: "Arial",fontWeight:FontWeight.bold,
            fontSize: 14,
          )),
        ],
      ),
    );
  }
}


