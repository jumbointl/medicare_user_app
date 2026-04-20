import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/patient_files_service.dart';
import '../controller/notification_controller.dart';
import '../model/notification_model.dart';
import '../utilities/api_content.dart';
import '../widget/app_bar_widget.dart';
import '../controller/notification_dot_controller.dart';
import '../helpers/date_time_helper.dart';
import '../helpers/route_helper.dart';
import '../services/user_service.dart';
import '../widget/image_box_widget.dart';
import '../widget/loading_Indicator_widget.dart';
import '../widget/no_data_widgets.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  bool _isLoading=false;
  late NotificationController notificationController;

  @override
  void initState() {
    // TODO: implement initState
    getAndSetData();
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
          appBar: IAppBar.commonAppBar(title: "notification".tr),
          body: _isLoading?const ILoadingIndicatorWidget():_buildBody()
      ),
    );
  }
  _buildBody(){
    return        Obx(() {
      if (!notificationController.isError.value) { // if no any error
        if (notificationController.isLoading.value) {
          return const ILoadingIndicatorWidget();
        } else if (notificationController.dataList.isEmpty) {
          return const NoDataWidget();
        } else {
          return
            _buildDataList(notificationController.dataList);
        }
      }else {
        return Container();
      } //Error svg
    }
    );
  }

  void getAndSetData() async{
    setState(() {
      _isLoading=true;
    });

    final res=await UserService.getDataById();
    if(res!=null){
      notificationController=Get.put(NotificationController(date: res.createdAt??""));
    }
    final NotificationDotController notificationDotController=Get.find(tag: "notification_dot");
    notificationDotController.setDotStatus(false);

   await UserService.updateNotificationLastSeen();
    setState(() {
      _isLoading=false;
    });
  }

  _buildDataList(RxList dataList) {
    return ListView.builder(
        padding: const EdgeInsets.all(8),
        shrinkWrap: true,
        itemCount:dataList.length ,
        itemBuilder: (context,index){
          NotificationModel notificationModel=dataList[index];
          return Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            elevation: 0,
            child: ListTile(
              onTap: notificationModel.image==null|| notificationModel.image==""?(){
                if(notificationModel.fileId!=null){
                  Get.toNamed(RouteHelper.getPatientFilePageRoute());
                  openFileUrl(notificationModel.fileId.toString());
                }else  if(notificationModel.prescriptionId!=null) {
                  Get.toNamed(RouteHelper.getPrescriptionListPageRoute());
                  launchUrl(Uri.parse("${ApiContents.prescriptionUrl}/${notificationModel.prescriptionId}"),
                      mode: LaunchMode.externalApplication
                  );
                }
                else  if(notificationModel.txnId!=null) {
                  Get.toNamed(RouteHelper.getWalletPageRoute());
                }
                else  if(notificationModel.appointmentId!=null) {
                  Get.toNamed(RouteHelper.getAppointmentDetailsPageRoute(appId: notificationModel.appointmentId.toString()));
                }
                else  if(notificationModel.labBookingId!=null) {
                  Get.toNamed(RouteHelper.getLabBookingDetailsPageRoute(labBookingId: notificationModel.labBookingId.toString()));
                }


                //print(notificationModel.fileId);
              }
                  :(){
                Get.toNamed(RouteHelper.getNotificationDetailsPageRoute(notificationId: notificationModel.id?.toString()??""));
              },
              isThreeLine: true,
              leading:  notificationModel.image==null|| notificationModel.image==""?
              null:
              SizedBox(
                width: 50,
                child: ImageBoxFillWidget(
                  imageUrl:
                  "${ApiContents.imageUrl}/${notificationModel.image}",
                  boxFit: BoxFit.contain,),
              ),
              title: Text("${notificationModel.title}",
                style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 15
                ),),
              subtitle:  Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(notificationModel.body??"",
                    style: const TextStyle(
                        fontWeight: FontWeight.w400,
                        fontSize: 14
                    ),),
                  Text(DateTimeHelper.getDataFormat(notificationModel.createdAt),
                      style:  const TextStyle(
                          fontWeight: FontWeight.w400,
                          fontSize: 14
                      ))
                ],
              ),
            ),
          );
        });
  }

  void openFileUrl(String id) async{
    setState(() {
      _isLoading=true;
    });
    final res=await PatientFilesService.getDataById(id:id);
    if(res!=null){
      if(res.fileUrl!=null&&res.fileUrl!=""){
        final fileUrl="${ApiContents.imageUrl}/${res.fileUrl}";
        await launchUrl(Uri.parse(fileUrl));
      }
    }
    setState(() {
      _isLoading=false;
    });
  }

}
