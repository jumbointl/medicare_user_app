import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../model/notification_model.dart';
import '../utilities/api_content.dart';
import '../helpers/date_time_helper.dart';
import '../services/notification_service.dart';
import '../widget/app_bar_widget.dart';
import '../widget/image_box_widget.dart';
import '../widget/loading_Indicator_widget.dart';

class NotificationDetailsPage extends StatefulWidget {
 final  String? notificationId;
  const  NotificationDetailsPage({super.key,this.notificationId});

  @override
  State<NotificationDetailsPage> createState() => _NotificationDetailsPageState();
}

class _NotificationDetailsPageState extends State<NotificationDetailsPage> {
  bool _isLoading=false;
  NotificationModel? notificationModel;
  @override
  void initState() {
    // TODO: implement initState
    getAndSetData();
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: IAppBar.commonAppBar(title: "notification".tr),
      body: _isLoading?const ILoadingIndicatorWidget():_buildCatList(),
    );
  }


  void getAndSetData() async{
    setState(() {
      _isLoading=true;
    });

    final res=await NotificationService.getDataById(nId: widget.notificationId);
    notificationModel=res;

    setState(() {
      _isLoading=false;
    });
  }

  _buildCatList() {
    return ListView(
      children:[
     notificationModel?.image==null|| notificationModel?.image==""?
        Container():
    SizedBox(
      height: 400,
    // width: 200,
    child: ImageBoxFillWidget(
    imageUrl:
    "${ApiContents.imageUrl}/${notificationModel!.image}",
    boxFit: BoxFit.contain,),
    ),
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          elevation: .1,
          child: ListTile(
            isThreeLine: true,

            title: Text(notificationModel?.title??"",
              style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 15
              ),),
            subtitle:  Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(notificationModel?.body??"",
                  style: const TextStyle(
                      fontWeight: FontWeight.w400,
                      fontSize: 14
                  ),),
                Text(DateTimeHelper.getDataFormat(notificationModel?.createdAt),
                    style:  const TextStyle(
                        fontWeight: FontWeight.w400,
                        fontSize: 14
                    ))
              ],
            ),
          ),
        ),
      ],
    );
  }
}
