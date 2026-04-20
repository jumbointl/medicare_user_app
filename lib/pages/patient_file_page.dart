import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../controller/patient_file_controller.dart';
import '../helpers/date_time_helper.dart';
import '../model/patient_file_model.dart';
import '../utilities/api_content.dart';
import '../widget/app_bar_widget.dart';
import 'package:get/get.dart';
import '../widget/loading_Indicator_widget.dart';
import '../utilities/colors_constant.dart';
import '../widget/error_widget.dart';
import '../widget/no_data_widgets.dart';
import '../widget/search_box_widget.dart';

class PatientFilePage extends StatefulWidget {
  final String? patientId;
  const PatientFilePage({super.key,this.patientId});

  @override
  State<PatientFilePage> createState() => _PatientFilePageState();
}

class _PatientFilePageState extends State<PatientFilePage> {
  ScrollController scrollController=ScrollController();
  PatientFileController patientFileController=PatientFileController();
  final TextEditingController _searchTextController=TextEditingController();

  @override
  void initState() {
    // TODO: implement initState
    getAndSetData();

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: IAppBar.commonAppBar(title: "files".tr),
      body:  ListView(
        padding: const EdgeInsets.all(8),
        controller: scrollController,
        children: [
          const SizedBox(height: 10),
          ISearchBox.buildSearchBox(textEditingController: _searchTextController,labelText: "search_report".tr,onFieldSubmitted:(){

            patientFileController.getData(_searchTextController.text);
          }

          ),
          const SizedBox(height: 20),
          Obx(() {
            if (!patientFileController.isError.value) { // if no any error
              if (patientFileController.isLoading.value) {
                return const IVerticalListLongLoadingWidget();
              } else if (patientFileController.dataList.isEmpty) {
                return const NoDataWidget();
              }

              else {
                return _buildList(patientFileController.dataList);
              }
            }else {
              return  const IErrorWidget();
            } //Error svg
          }
          ),
        ],
      )
    );
  }

  Widget _buildList(RxList dataList) {
    return ListView.builder(
      padding: EdgeInsets.zero,
        controller: scrollController,
        shrinkWrap: true,
        itemCount:dataList.length ,
        itemBuilder: (context,index){
          PatientFileModel patientFileModel=dataList[index];
          //   print(testimonialModel.image);
          return getCheckToShow(patientFileModel.patientId.toString())?Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            elevation: 0,
            child: ListTile(
              onTap: ()async {
                if(patientFileModel.fileUrl!=null&&patientFileModel.fileUrl!=""){
                  final fileUrl="${ApiContents.imageUrl}/${patientFileModel.fileUrl}";
                    await launchUrl(Uri.parse(fileUrl));
                }

              },
              trailing: const Icon(Icons.download,
              size: 20,
              color: ColorResources.iconColor,
              ),
              subtitle:   Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const SizedBox(height: 3),
                  Text("${patientFileModel.pFName} ${patientFileModel.pLName}",
                    style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14
                    ),),
                  const SizedBox(height: 3),
                  Text(DateTimeHelper.getDataFormat(patientFileModel.createdAt??""),
                    style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14
                    ),),
                ],
              ),
              title:     Text(patientFileModel.fileName??"",
                style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14
                ),)
            ),
          ):Container();
        });
  }

  void getAndSetData() async {

    patientFileController.getData("");

  }

  bool getCheckToShow(String patientId) {
    if(widget.patientId!=null&&widget.patientId!=""){
      if(widget.patientId==patientId){
        return true;
      }else{
        return false;
      }

    }else{
      return true;
    }
  }
}
