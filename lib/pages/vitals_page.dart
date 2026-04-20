import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../helpers/route_helper.dart';
import '../helpers/vital_helper.dart';
import '../widget/app_bar_widget.dart';
import '../utilities/colors_constant.dart';

class VitalsPage extends StatefulWidget {
  const VitalsPage({super.key});

  @override
  State<VitalsPage> createState() => _VitalsPageState();
}

class _VitalsPageState extends State<VitalsPage> {
  final _listVitals=VitalHelper.listVitals;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: IAppBar.commonAppBar(title: "vitals".tr),
      body: buildList(),
    );
  }

  buildList() {
    return ListView.builder(
        itemCount:_listVitals.length ,
        shrinkWrap: true,
        itemBuilder: (context,index){
            return Card(
              color:  ColorResources.cardBgColor,
              elevation: .1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5.0),
              ),
              child: ListTile(
                onTap: (){
                  Get.toNamed(RouteHelper.getVitalsDetailsPageRoute(notificationId: _listVitals[index]));
                },
                trailing:const Icon(Icons.arrow_right,),
                title:Text(_listVitals[index].tr,
              style:const  TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500
              ),),
                        ),
            );
        });
  }
}
