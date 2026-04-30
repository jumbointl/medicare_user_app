import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../controller/prescription_controller.dart';
import '../helpers/date_time_helper.dart';
import '../utilities/api_content.dart';
import '../utilities/colors_constant.dart';
import '../widget/app_bar_widget.dart';
import '../model/prescription_model.dart';
import '../widget/loading_Indicator_widget.dart';
import '../widget/no_data_widgets.dart';

class PrescriptionListPage extends StatefulWidget {
  const PrescriptionListPage({super.key});

  @override
  State<PrescriptionListPage> createState() => _PrescriptionListPageState();
}

class _PrescriptionListPageState extends State<PrescriptionListPage> {
  PrescriptionController prescriptionController=Get.put(PrescriptionController());

  @override
  void initState() {
    // TODO: implement initState
    prescriptionController.getDataBYUid();
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: IAppBar.commonAppBar(title: "prescription".tr),
      body: _buildBody(),
    );
  }

  _buildBody() {
    return  Obx(()
    {
      if (!prescriptionController.isError.value) { // if no any error
        if (prescriptionController.isLoading.value) {
          return const  ILoadingIndicatorWidget();
        } else {
          return prescriptionController.dataList.isEmpty?const NoDataWidget():
          ListView.builder(
              shrinkWrap: true,
              itemCount:prescriptionController.dataList.length ,
              itemBuilder: (context, index){
                PrescriptionModel prescriptionModel=prescriptionController.dataList[index];
                return Card(
                  elevation: .1,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: ListTile(
                    trailing:      IconButton(onPressed: ()async{
                      if(prescriptionModel.pdfFileUrl!=null&&prescriptionModel.pdfFileUrl!="")
                      {
                        await launchUrl(Uri.parse(
                            "${ApiContents.imageUrl}/${prescriptionModel
                                .pdfFileUrl}"),
                        mode: LaunchMode.externalApplication
                        );
                      }
                      else{
                        await launchUrl(Uri.parse(
                            "${ApiContents.prescriptionUrl}/${prescriptionModel
                                .id}"),
                        mode: LaunchMode.externalApplication
                        );
                      }
                    }, icon: const Icon(Icons.download,
                      color: ColorResources.btnColor,
                    )),
                    title: Text("name_with_id".trArgs([prescriptionModel.doctorFName??"", prescriptionModel.doctorLName??"", "${prescriptionModel.id??"--"}"]),
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500
                      ),),
                    subtitle:   Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("full_name".trArgs([prescriptionModel.patientFName??"", prescriptionModel.patientLName??""]),
                            style:const   TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w400
                            )
                        ),
                        Text("${DateTimeHelper.getDataFormatWithTime(prescriptionModel.createdAt)}",
                            style:const   TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w400
                            )
                        ),
                      ],
                    ),
                  ),
                );
              }

          );

        }
      }else {
        return Container();
      } //Error svg

    });
  }
}
