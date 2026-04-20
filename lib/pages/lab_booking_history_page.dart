import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/lab_booking_controller.dart';
import '../model/lab_booking_model.dart';
import '../widget/loading_Indicator_widget.dart';
import '../helpers/route_helper.dart';
import '../utilities/colors_constant.dart';
import '../widget/error_widget.dart';
import '../widget/no_data_widgets.dart';

class LabBookingHistoryPage extends StatefulWidget {
  const LabBookingHistoryPage({super.key});

  @override
  State<LabBookingHistoryPage> createState() => _LabBookingHistoryPageState();
}

class _LabBookingHistoryPageState extends State<LabBookingHistoryPage> {

  String  serviceName ="Offline";
  LabBookingController labBookingController =Get.put(LabBookingController());

  @override
  void initState() {
    // TODO: implement initState
    labBookingController.getData();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
          backgroundColor:ColorResources.bgColor,
          //Color(0xFFF7F8FA),
          appBar: AppBar(
            centerTitle: true,
            iconTheme: const IconThemeData(
              color: Colors.white, //change your color here
            ),
            elevation: 0,
            backgroundColor:ColorResources.appBarColor ,
            title:  Text("lab_booking".tr,
              style:  const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w400
              ),),
            bottom:  TabBar(
              indicatorWeight: 3,
              indicatorColor: ColorResources.primaryColor,
              labelPadding: EdgeInsets.all(8),
              tabs: [
                Text(
                  "upcoming".tr,
                  style:const  TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w400
                  ),
                ),
                Text(
                  "closed".tr,
                  style: const  TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w400
                  ),
                ),
              ],
            ),
          ),
          body:
          Obx(() {
            if (!labBookingController.isError.value) { // if no any error
              if (labBookingController.isLoading.value) {
                return const IVerticalListLongLoadingWidget();
              } else if (labBookingController.dataList.isEmpty) {
                return const NoDataWidget();
              }
              else {
                return
                  TabBarView(
                    children: [
                      _upcomingAppointmentList(labBookingController.dataList),
                      _pastAppointmentList(labBookingController.dataList)
                    ],
                  );

              }
            }else {
              return  const IErrorWidget();
            } //Error svg
          }
          )
      ),
    );
  }

  _upcomingAppointmentList(List dataList) {
    return ListView.builder(
        padding: const EdgeInsets.all(2.0),
        shrinkWrap: true,
        itemCount: dataList.length,
        itemBuilder: (BuildContext ctxt, int index) {
          return dataList[index].status=="Pending"||dataList[index].status=="Confirmed"||dataList[index].status=="Rescheduled"?
          _card( dataList[index]):Container();
        });
  }

  _pastAppointmentList(List dataList) {
    return ListView.builder(
        padding: const EdgeInsets.all(2.0),
        shrinkWrap: true,
        itemCount: dataList.length,
        itemBuilder: (BuildContext ctxt, int index) {
          return dataList[index].status=="Completed"||dataList[index].status=="Visited"||dataList[index].status=="Rejected"||dataList[index].status=="Cancelled"? _card( dataList[index]):Container();//_card( true);
        });
  }
  Widget _card(LabBookingModel appointmentModel) {
    return GestureDetector(
      onTap: () async{
        Get.toNamed(RouteHelper.getLabBookingDetailsPageRoute(labBookingId:appointmentModel.id.toString() ));
      },
      child: Card(
        color:ColorResources.cardBgColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        elevation: .1,
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              Text(
                  " ${appointmentModel.pFName??""} ${appointmentModel.pLName??""} #${appointmentModel.id}" ,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  )),
            const   SizedBox(height: 5),
              Text(
                 _appointmentDate(appointmentModel.date),
                  style: const TextStyle(
                    color: ColorResources.primaryColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  )),
              const   SizedBox(height: 5),
              Text(
                  appointmentModel.pathologyTitle??"--",
                  style: const TextStyle(
                    color: ColorResources.secondaryFontColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  )),

              Row(
                children: [
                  Expanded(
                      child: Container(
                          height: 1, color: Colors.grey[300])),
                  Padding(
                      padding: const EdgeInsets.only(left: 5),
                      child: appointmentModel.status ==
                          "Pending"
                          ? _statusIndicator(Colors.yellowAccent)
                          : appointmentModel.status ==
                          "Rescheduled"
                          ? _statusIndicator(Colors.orangeAccent)
                          : appointmentModel.status ==
                          "Rejected"
                          ? _statusIndicator(Colors.red)
                          : appointmentModel.status ==
                          "Confirmed"
                          ? _statusIndicator(Colors.green)
                          : appointmentModel.status ==
                          "Completed"
                          ? _statusIndicator(Colors.green)
                          :appointmentModel.status ==
                          "Cancelled"
                          ? _statusIndicator(Colors.red)
                          :appointmentModel.status ==
                          "Visited"
                          ? _statusIndicator(Colors.green)
                          :null),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(5, 0, 10, 0),
                    child: Text(
                      (appointmentModel.status??"--").tr,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  )
                ],
              ),

            ],
          ),
        ),
      ),
    );
  }
  String _appointmentDate(date) {
    //  print(date);
    var appointmentDate = date.split("-");
    String appointmentMonth="";
    switch (int.parse(appointmentDate[1])) {
      case 1:
        appointmentMonth = "month_jan";
        break;
      case 2:
        appointmentMonth = "month_feb";
        break;
      case 3:
        appointmentMonth = "month_mar";
        break;
      case 4:
        appointmentMonth = "month_apr";
        break;
      case 5:
        appointmentMonth = "month_may";
        break;
      case 6:
        appointmentMonth = "month_jun";
        break;
      case 7:
        appointmentMonth = "month_jul";
        break;
      case 8:
        appointmentMonth = "month_aug";
        break;
      case 9:
        appointmentMonth = "month_sep";
        break;
      case 10:
        appointmentMonth = "month_oct";
        break;
      case 11:
        appointmentMonth = "month_nov";
        break;
      case 12:
        appointmentMonth = "month_dec";
        break;
    }
    return "${appointmentDate[2]}-${appointmentMonth.tr}-${appointmentDate[0]}";


  }

  Widget _statusIndicator(color) {
    return CircleAvatar(radius: 4, backgroundColor: color);
  }
}
