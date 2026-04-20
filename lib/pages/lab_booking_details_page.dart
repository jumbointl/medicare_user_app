
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:medicare_user_app/controller/lab_booking_cancel_req_controller.dart';
import 'package:medicare_user_app/helpers/route_helper.dart';
import 'package:medicare_user_app/pages/lab_cart_check_out_page.dart';
import 'package:medicare_user_app/services/lab_booking_cancellation_service.dart';
import 'package:medicare_user_app/services/lab_cart_service.dart';
import 'package:medicare_user_app/services/pathologist_service.dart';
import 'package:url_launcher/url_launcher.dart';
import '../model/LabAppointmentCancellationReqModel.dart';
import '../model/configuration_model.dart';
import '../model/lab_booking_model.dart';
import '../pages/patient_file_page.dart';
import '../services/lab_booking_service.dart';
import '../services/patient_files_service.dart';
import '../utilities/image_constants.dart';
import '../helpers/date_time_helper.dart';
import '../model/invoice_model.dart';
import '../services/invoice_service.dart';
import '../widget/app_bar_widget.dart';
import '../widget/loading_Indicator_widget.dart';
import 'package:star_rating/star_rating.dart';
import '../helpers/theme_helper.dart';
import '../utilities/api_content.dart';
import '../utilities/colors_constant.dart';
import '../widget/button_widget.dart';
import '../widget/image_box_widget.dart';
import '../widget/toast_message.dart';
import 'package:get/get.dart';
import '../bancard/bancard_lab_booking_payment_provider.dart';
import '../bancard/medicare_client_payment_gateway_page.dart';
import '../services/user_service.dart';
class LabBookingDetailsPage extends StatefulWidget {
  final String? labBookingId;
  const LabBookingDetailsPage({super.key,this.labBookingId});

  @override
  State<LabBookingDetailsPage> createState() => _LabBookingDetailsPageState();
}

class _LabBookingDetailsPageState extends State<LabBookingDetailsPage> {
  bool _isLoading = false;
  LabBookingModel? appointmentModel;
  InvoiceModel? invoiceModel;


  final LabBookingCancelReqController _appointmentCancellationController = LabBookingCancelReqController();
  // final PrescriptionController _prescriptionController = PrescriptionController();
  List<ConfigurationModel> listConfigModel=[];
  final ScrollController _scrollController = ScrollController();
  TextEditingController textEditingController = TextEditingController();
  double _rating = 4;
  String? lat;
  String? lng;
  String? email;
  String? phone;
  String? whatsapp;
  bool patientFileAvailable=false;
  bool _isRetryPaymentLoading = false;
  final BancardLabBookingPaymentProvider bancardLabBookingPaymentProvider =
  BancardLabBookingPaymentProvider();
  @override
  void initState() {
    // TODO: implement initState
    getAndSetData();
    _appointmentCancellationController.getData(
        bookingId: widget.labBookingId ?? "-1");

    super.initState();
  }
  bool get _isBookingPaid {
    final String paymentStatus =
    (appointmentModel?.paymentStatus ?? '').toLowerCase().trim();
    return paymentStatus == 'paid';
  }

  bool get _isBookingPendingPayment {
    final String paymentStatus =
    (appointmentModel?.paymentStatus ?? '').toLowerCase().trim();

    if (paymentStatus == 'paid') return false;
    if (paymentStatus == 'pending') return true;
    if (paymentStatus == 'unpaid') return true;
    if (paymentStatus.isEmpty) return true;

    return true;
  }

  bool get _canRetryPayment {
    if (appointmentModel == null) return false;
    final String status = (appointmentModel?.status ?? '').trim();
    if (status == 'Cancelled' || status == 'Rejected') return false;
    return _isBookingPendingPayment;
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorResources.bgColor,
      appBar: IAppBar.commonAppBar(title: "lab_appointment".tr),
      body: _isLoading || appointmentModel == null
          ? const ILoadingIndicatorWidget()
          : _buildBody(),
    );
  }

  _buildBody() {
    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.all(5),
      children: [
        buildOpDetails(),
        const SizedBox(height: 3),

        patientFileAvailable?  Padding(padding: const EdgeInsets.only(bottom: 10),
          child: _buildFileBox(),
        ):Container(),
        // _buildClinicListTile(),
        // const SizedBox(height: 3),
        _buildPaymentCard(),
        appointmentModel?.status=="Visited"||appointmentModel?.status=="Completed"? _buildReviewBox():Container(),
        const SizedBox(height: 3),
        appointmentModel?.status=="Visited"||appointmentModel?.status=="Completed"?Container(): _buildCancellationBox(),
        const SizedBox(height: 0),
        appointmentModel?.currentCancelReqStatus == null
            ? Container()
            : _buildCancellationReqListBox()
      ],
    );
  }
  _buildCancellationBox() {
    return Card(
      color: ColorResources.cardBgColor,
      elevation: .1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(5.0),
      ),
      child: ListTile(
        onTap: appointmentModel?.currentCancelReqStatus == null
            ? _openDialogBox
            :
        appointmentModel?.currentCancelReqStatus == "Initiated"
            ? _openDialogBoxDeleteReq
            :
        null,
        trailing: const Icon(Icons.arrow_right,
          color: ColorResources.btnColor,),
        title:  Text("booking_cancellation".tr,
          style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500
          ),),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            appointmentModel?.currentCancelReqStatus == null ?  Text(
              "to_create_cancellation_request".tr,
              style: const TextStyle(
                  color: ColorResources.secondaryFontColor,
                  fontSize: 13
              ),) :
            appointmentModel?.currentCancelReqStatus == "Initiated" ?
            Text("to_delete_cancellation_request".tr,
              style:const TextStyle(
                  color: ColorResources.secondaryFontColor,
                  fontSize: 13
              ),)
                : Container(),
            appointmentModel?.currentCancelReqStatus == null
                ? Container()
                : Text(
              "current_status_value".trParams({"value":appointmentModel?.currentCancelReqStatus ??
                  "--"}),
              style: const TextStyle(
                  color: ColorResources.secondaryFontColor,
                  fontSize: 13
              ),),

          ],
        ),
      ),
    );
  }
  _buildCancellationReqListBox() {
    return Card(
      color: ColorResources.cardBgColor,
      elevation: .1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(5.0),
      ),
      child:
      Obx(() {
        if (!_appointmentCancellationController.isError
            .value) { // if no any error
          if (_appointmentCancellationController.isLoading.value) {
            return const ILoadingIndicatorWidget();
          } else {
            return _appointmentCancellationController.dataList.isEmpty
                ? Container()
                : ListTile(
              title:  Text("cancellation_request_history".tr,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500
                ),),
              subtitle: ListView.builder(
                  controller: _scrollController,
                  shrinkWrap: true,
                  itemCount: _appointmentCancellationController.dataList.length,
                  itemBuilder: (context, index) {
                    Labappointmentcancellationreqmodel appointmentCancellationRedModel = _appointmentCancellationController
                        .dataList[index];
                    return ListTile(
                      leading: Icon(Icons.circle,
                        size: 10,
                        color: appointmentCancellationRedModel.status ==
                            "Initiated" ? Colors.yellow :
                        appointmentCancellationRedModel.status == "Rejected"
                            ? Colors.red
                            :
                        appointmentCancellationRedModel.status == "Approved"
                            ? Colors.green
                            :
                        appointmentCancellationRedModel.status == "Processing"
                            ? Colors.orange
                            :
                        Colors.grey,),
                      //'Initiated','Rejected','Approved','Processing'
                      title: Text(
                        (appointmentCancellationRedModel.status ?? "--").tr,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500
                        ),),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          appointmentCancellationRedModel.notes == null
                              ? Container()
                              : Text(
                              appointmentCancellationRedModel.notes ?? "--",
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400
                              )
                          ),
                          Text(DateTimeHelper.getDataFormat(
                              appointmentCancellationRedModel.createdAt ??
                                  "--"),
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400
                              )
                          ),
                          Divider(
                            color: Colors.grey.shade100,
                          )
                        ],
                      ),
                    );
                  }

              ),
            );
          }
        } else {
          return Container();
        } //Error svg

      }),

    );
  }
  void getAndSetData() async {
    setState(() {
      _isLoading = true;
    });
    final appointmentData = await LabBookingService.getDataById(appId: widget.labBookingId);
    appointmentModel = appointmentData;
    lat=appointmentModel?.latitude;
    lng=appointmentModel?.longitude;
    whatsapp=appointmentModel?.whatsapp;
    phone=appointmentModel?.phone;
    email=appointmentModel?.email;

    final patientFile=await PatientFilesService.getDataByPatientId(appointmentModel?.patientId.toString()??"");
    if(patientFile!=null&&patientFile.isNotEmpty){
      patientFileAvailable=true;
    }
    final invoiceData = await InvoiceService.getDataByAppLabId(
        appId: widget.labBookingId);
    invoiceModel = invoiceData;
   // getAndSetQueue();

    setState(() {
      _isLoading = false;
    });
  }
  _openDialogBox() {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        // return object of type Dialog
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          title:  Text(
            "cancel".tr,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
          ),
          content:  Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("cancel_this_appointment_box".tr,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w400, fontSize: 12)),
              SizedBox(height: 10),
            ],
          ),
          actions: <Widget>[
            ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorResources.btnColorGreen,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                        10), // Change this value to adjust the border radius
                  ),
                ),
                child:  Text("no".tr,
                    style:
                    const    TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w400, fontSize: 12)),
                onPressed: () {
                  Navigator.of(context).pop();
                }),
            ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorResources.btnColorRed,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                        10), // Change this value to adjust the border radius
                  ),
                ),
                child:  Text(
                  "yes".tr,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w400, fontSize: 12),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  _handleAppointmentCanReq();
                }),
            // usually buttons at the bottom of the dialog
          ],
        );
      },
    );
  }
  void _handleAppointmentCanReq() async {
    setState(() {
      _isLoading = true;
    });
    final res = await LabBookingCancellationService
        .addAppointmentCancelRequest(
        appointmentId: appointmentModel?.id.toString() ?? "",
        status: "Initiated");
    if (res != null) {
      IToastMsg.showMessage("success".tr);
      _appointmentCancellationController.getData(
          bookingId: widget.labBookingId ?? "-1");
      getAndSetData();
    }
    setState(() {
      _isLoading = false;
    });
  }
  _openDialogBoxDeleteReq() {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        // return object of type Dialog
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          title:  Text(
            "delete".tr,
            textAlign: TextAlign.center,
            style:const  TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
          ),
          content:  Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("delete_the_cancellation_request_box".tr,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w400, fontSize: 12)),
              SizedBox(height: 10),
            ],
          ),
          actions: <Widget>[
            ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorResources.btnColorRed,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                        10), // Change this value to adjust the border radius
                  ),
                ),
                child:  Text("no".tr,
                    style:
                    TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w400, fontSize: 12)),
                onPressed: () {
                  Navigator.of(context).pop();
                }),
            ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorResources.btnColorGreen,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                        10), // Change this value to adjust the border radius
                  ),
                ),
                child:  Text(
                  "yes".tr,
                  style:const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w400, fontSize: 12),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  _handleAppointmentDeleteReq();
                }),
            // usually buttons at the bottom of the dialog
          ],
        );
      },
    );
  }
  void _handleAppointmentDeleteReq() async {
    setState(() {
      _isLoading = true;
    });
    final res = await LabBookingCancellationService.deleteReq(
        appointmentId: appointmentModel?.id.toString() ?? "");
    getAndSetData();
    _appointmentCancellationController.getData(
        bookingId: widget.labBookingId ?? "-1");
    if (res != null) {
      IToastMsg.showMessage("success".tr);
      getAndSetData();
    }
    setState(() {
      _isLoading = false;
    });
  }

  _buildContactCard() {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(5.0),
      ),
      color: ColorResources.cardBgColor,
      elevation: .1,
      child: ListTile(
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 15.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              appointmentModel?.phone==null|| appointmentModel?.phone==""?Container(): _buildTapBox(ImageConstants.telephoneImageBox, "call".tr,()async{
                if( appointmentModel?.phone!=null&& appointmentModel?.phone!=""){
                  await launchUrl(Uri.parse("tel:${ appointmentModel?.phone}"));
                }
              }),
              appointmentModel?.whatsapp==null|| appointmentModel?.whatsapp==""?Container():   Padding(padding: const EdgeInsets.only(left: 20),
                  child:      _buildTapBox(ImageConstants.whatsappImageBox, "whatsapp".tr,()async{
                    if( appointmentModel?.whatsapp!=null&& appointmentModel?.whatsapp!=""){
                      final url = "https://wa.me/${ appointmentModel?.whatsapp}?text=Hello"; //remember country code
                      await launchUrl(Uri.parse(url),
                          mode: LaunchMode.externalApplication
                      );
                    }

                  })
              ),

              appointmentModel?.email==null|| appointmentModel?.email==""?Container():   Padding(padding: const EdgeInsets.only(left: 20),
                child:  _buildTapBox(ImageConstants.emailImageBox, "email".tr,()async{
                  if( appointmentModel?.email!=null&& appointmentModel?.email!=""){
                    await launchUrl(Uri.parse("mailto:${ appointmentModel?.email}"));
                  }

                }),
              ),

              appointmentModel?.longitude==null|| appointmentModel?.latitude==null?Container():  Padding(padding: const EdgeInsets.only(left: 20),
                child:     _buildTapBox(ImageConstants.mapPlaceImageBox, "map".tr,()async{
                  if(appointmentModel?.longitude!=null&&appointmentModel?.latitude!=null){
                    final url="http://maps.google.com/maps?daddr=${appointmentModel?.latitude},${appointmentModel?.longitude}";
                    try{
                      await launchUrl(Uri.parse(url),
                          mode: LaunchMode.externalApplication);
                    }catch(e){
                      if (kDebugMode) {
                        print(e);
                      }
                    }
                  }

                }),
              ),


            ],
          ),
        ),
        title:  Text("contact_us".tr,
          style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500
          ),),
      ),
    );
  }
  _buildTapBox(String imageAsset, String title,GestureTapCallback onTap) {
    return GestureDetector(
      onTap:onTap ,
      child: Column(
        children: [
          SizedBox(
              height: 30,
              child: Image.asset(imageAsset)),
          const SizedBox(height: 5),
          Text(title,
            style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 12
            ),)
        ],
      ),
    );
  }
  _buildProfileSection() {
    return InkWell(
      onTap: (){
        Get.toNamed(RouteHelper.getPathologyPageRoute(pathId: appointmentModel?.pathId.toString()??""));
      },
      child: Card(
        color: ColorResources.cardBgColor,
        elevation: .1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(5.0),
        ),
        child:
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Row(
                children: [
                  Flexible(
                      flex: 2,
                      child: Stack(
                        children: [
                          appointmentModel!.pathThumbImage == null ||
                              appointmentModel!.pathThumbImage == ""
                              ? const CircleAvatar(
                            backgroundColor: Colors.white,
                            radius: 30,
                            child: Icon(Icons.person,
                              size: 40,),
                          )
                              : ClipOval(child:
                          SizedBox(
                            height: 80,
                            width: 80,
                            child: CircleAvatar(child: ImageBoxFillWidget(
                              imageUrl:
                              "${ApiContents.imageUrl}/${appointmentModel!
                                  .pathThumbImage}",
                              boxFit: BoxFit.fill,
                            )),
                          ),
                          ),
      
                          const Positioned(
                            top: 5,
                            right: 0,
                            child: CircleAvatar(
                              backgroundColor: Colors.white, radius: 8,
                              child: CircleAvatar(backgroundColor: Colors.green,
                                  radius: 6),),
                          )
                        ],
                      )),
                  const SizedBox(width: 20),
                  Flexible(
                      flex: 6,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(appointmentModel?.pathName??"",
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16
                            ),),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              StarRating(
                                mainAxisAlignment: MainAxisAlignment.center,
                                length: 5,
                                color: appointmentModel?.averageRating == 0
                                    ? Colors.grey
                                    : Colors.amber,
                                rating: appointmentModel?.averageRating ?? 0,
                                between: 5,
                                starSize: 15,
                                onRaitingTap: (rating) {},
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'rating_review_text'.trParams({
                                  'rating': '${appointmentModel?.averageRating ?? "--"}',
                                  'count': '${appointmentModel?.numberOfReview ?? 0}',
                                }),
                                style: const TextStyle(
                                    color: ColorResources.secondaryFontColor,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 12
                                ),)
                            ],
                          ),
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              const Icon(
                                  Icons.person, color: ColorResources.iconColor,
                                  size: 15),
                              const SizedBox(width: 5),
                              Text(
                                'booking_done'.trParams({
                                  "count": (appointmentModel?.totalBookingDone ?? 0).toString()
                                }),
      
                                style: const TextStyle(
                                    color: ColorResources.greenFontColor,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 12
                                ),)
                            ],
                          ),
                          const SizedBox(height: 5),
                          Text(appointmentModel?.pathAddress ?? "",
                            style: const TextStyle(
                                color: ColorResources.secondaryFontColor,
                                fontWeight: FontWeight.w500,
                                fontSize: 12
                            ),),
                          const SizedBox(height: 5),
      
                        ],))
                ],
              ),
              const SizedBox(height: 10)
            ],
          ),
        ),
      ),
    );
  }

  buildOpDetails() {
    return Card(
      color: ColorResources.cardBgColor,
      elevation: .1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileSection(),
            const SizedBox(height: 10),
            appointmentModel?.isShowContactBox==1?
            Padding(
              padding: EdgeInsets.only(bottom: 20),
            child:  _buildContactCard(),
            ):Container(),

            // appointmentModel?.type != "OPD"
            //     || appointmentModel?.status != "Confirmed"
            //     ? Container() :
            // _queueNumber == null ?
            // GestureDetector(
            //   onTap: () {
            //     openBoxToCheckIn();
            //   },
            //   child: Card(
            //     color: Colors.green,
            //     elevation: .1,
            //     shape: RoundedRectangleBorder(
            //       borderRadius: BorderRadius.circular(5.0),
            //     ),
            //     child:  Padding(
            //       padding:const EdgeInsets.all(8.0),
            //       child: Row(
            //         mainAxisSize: MainAxisSize.min,
            //         children: [
            //           Text("check_in".tr,
            //             style: const TextStyle(
            //                 fontSize: 13,
            //                 fontWeight: FontWeight.w500,
            //                 color: Colors.white
            //             ),
            //           ),
            //           SizedBox(width: 5),
            //           Icon(Icons.login_outlined,
            //             color: Colors.white,
            //           )
            //
            //         ],
            //       ),
            //     ),
            //   ),
            // )
            //
            //     : Padding(
            //   padding: const EdgeInsets.only(bottom: 10.0),
            //   child: _isLoadingQueue
            //       ? const ILoadingIndicatorWidget()
            //       : GestureDetector(
            //     onTap: () {
            //    //   getAndSetQueue();
            //     },
            //     child: Card(
            //       color: Colors.green,
            //       elevation: .1,
            //       shape: RoundedRectangleBorder(
            //         borderRadius: BorderRadius.circular(5.0),
            //       ),
            //       child: Padding(
            //         padding: const EdgeInsets.all(8.0),
            //         child: Row(
            //           mainAxisSize: MainAxisSize.min,
            //           children: [
            //             Text("queue_number_value".trParams({
            //               "number":_queueNumber.toString()
            //             }),
            //               style: const TextStyle(
            //                   fontSize: 13,
            //                   fontWeight: FontWeight.w500,
            //                   color: Colors.white
            //               ),
            //             ),
            //             const SizedBox(width: 5),
            //             const Icon(Icons.refresh,
            //               color: Colors.white,
            //             )
            //
            //           ],
            //         ),
            //       ),
            //     ),
            //   ),
            // ),
            Row(
              children: [
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("date".tr,
                        style:const  TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14
                        ),),
                      GestureDetector(
                        onTap: () {},
                        child: Card(
                            color: ColorResources.cardBgColor,
                            elevation: .1,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5.0),
                            ),
                            child: ListTile(
                              title: Text(DateTimeHelper.getDataFormat(
                                  appointmentModel?.date ?? ""),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w400,
                                      fontSize: 13
                                  )
                              ),
                              trailing: Card(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(5.0),
                                  ),
                                  color: Colors.black,
                                  child:
                                  const Padding(
                                    padding: EdgeInsets.all(3.0),
                                    child: Icon(Icons.calendar_month,
                                      color: Colors.white,
                                      size: 15,),
                                  )),
                            )),
                      )
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("booking_id".trParams({"id":widget.labBookingId ?? "--"}),
                  style: const TextStyle(
                      color: ColorResources.secondaryFontColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w600
                  ),),
                const SizedBox(width: 5),
                Row(
                  children: [
                    Padding(
                        padding: const EdgeInsets.only(left: 5),
                        child: appointmentModel!.status ==
                            "Pending"
                            ? _statusIndicator(Colors.yellowAccent)
                            : appointmentModel!.status ==
                            "Rescheduled"
                            ? _statusIndicator(Colors.orangeAccent)
                            : appointmentModel!.status ==
                            "Rejected"
                            ? _statusIndicator(Colors.red)
                            : appointmentModel!.status ==
                            "Confirmed"
                            ? _statusIndicator(Colors.green)
                            : appointmentModel!.status ==
                            "Completed"
                            ? _statusIndicator(Colors.green)
                            : null),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(5, 0, 10, 0),
                      child: Text((appointmentModel!.status ?? "--").tr,
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
            const SizedBox(height: 10),
            Text(
              "patient_name".trParams({"name":"${appointmentModel!.pFName ?? "--"} ${appointmentModel!.pLName ??
                  "--"} #${appointmentModel?.patientId??"--"}"}),
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600
              ),),
            const SizedBox(height: 5),
            Text(
              "MRN #${appointmentModel?.patientMRN??"--"}",
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600
              ),),
            const SizedBox(height: 10),
            const Divider(),
           Text("test_included_count".trParams ({
             "count":"${appointmentModel?.labTests?.length}"
           }),
           style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600
           ),
           ),
           _buildLatTestItem(),
            const SizedBox(height: 10),
            const SizedBox(height: 20),
            SmallButtonsWidget(title: "rebook".tr, onPressed: () {
              handleRebookButton();
              // if(appointmentModel!.doctorId!=null){
              //   Get.toNamed(RouteHelper.getDoctorsDetailsPageRoute(doctId: appointmentModel!.doctorId!.toString()));
              // }
              // _openBottomSheet();
            }),
            const SizedBox(height: 10),
          ],

        ),
      ),
    );
  }
  Widget _statusIndicator(color) {
    return CircleAvatar(radius: 4, backgroundColor: color);
  }

  _buildPaymentCard() {
    return GestureDetector(
      onTap: () {
        //download invoice
      },
      child: Card(
        color: ColorResources.cardBgColor,
        elevation: .1,
        // elevation: .1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(5.0),
        ),
        child: ListTile(
          onTap: ()async{
            await launchUrl(Uri.parse(
                "${ApiContents.labInvoiceUrl}/${invoiceModel?.id}"),
                mode: LaunchMode.externalApplication
            );
          },
          title: Text(
            "payment_status_value".trParams({"status":invoiceModel == null ? "--" : invoiceModel
                ?.paymentId.toString() ?? "--"}),
            style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14
            ),),
          trailing: Text(
            invoiceModel == null ? "--" : (invoiceModel?.status ?? "--").tr,
            style: const TextStyle(
                color: ColorResources.primaryColor,
                // fontWeight: FontWeight.w500,
                fontSize: 13
            ),),
          subtitle:  Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              SizedBox(height: 5),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text("download_invoice".tr,
                      style:const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w500,
                        fontSize: 14
                        ,
                      )),
                  SizedBox(width: 5),
                  Icon(Icons.download,
                      color: Colors.green,
                      size: 16)
                ],
              )

            ],
          ),
        ),
      ),
    );
  }


  _buildFileBox() {
    return Card(
      color: ColorResources.cardBgColor,
      elevation: .1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(5.0),
      ),
      child:
      ListTile(
          trailing: const Icon(Icons.arrow_right,
            color: ColorResources.iconColor,
            size: 30,),
          onTap: (){
            Get.to(()=>PatientFilePage(patientId: appointmentModel?.patientId.toString(),));
          },
          title:  Text("patient_files".tr,
            style:const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500
            ),),
          subtitle:  Text(
              "click_here_to_check_the_patient_files".tr,
              style:const  TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,

              )
          )
      ),

    );
  }
  _buildLatTestItem() {
    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.only(top:10),
      shrinkWrap: true,
          itemCount: appointmentModel?.labTests?.length,
        itemBuilder:(context, index){
          final labTest = appointmentModel?.labTests?[index];
          return Card(
            color: ColorResources.cardBgColor,
            elevation: .1,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${index + 1}: ${labTest?['title'] ?? "--"}",
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500
                    ),
                  ),
                  Text(
                    "${labTest?['sub_title'] ?? "--"}",
                    style: const TextStyle(
                      color: ColorResources.secondaryFontColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w400
                    ),
                  ),
                  const SizedBox(height: 8),
                  labTest['sub_tests']==null|| labTest['sub_tests']!.isEmpty?Container():
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Divider(),
                        Text("test_included".tr,
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500
                          ),
                        ),
                        const SizedBox(height: 5),
                        ListView.builder(
                          padding: EdgeInsets.only(bottom: 8),
                            controller: _scrollController,
                          shrinkWrap: true,
                          itemCount:  labTest['sub_tests']!.length,
                          itemBuilder: (context,subIndex){
                            final subTest= labTest['sub_tests']![subIndex];
                            return  Padding(
                              padding: const EdgeInsets.only(top:2.0),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.check_circle_outline,
                                    color: Colors.green,
                                    size: 20,
                                  ),
                                  SizedBox(width: 5),
                                  Flexible(
                                    child: Text(subTest['name']??"--",
                                      style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          );
        }

    );
  }
  //
  // void getAndSetQueue() async {
  //   if (appointmentModel == null) return;
  //   setState(() {
  //     _isLoadingQueue = true;
  //   });
  //   final res = await AppointmentCheckinService.getData(
  //       doctId: appointmentModel!.doctorId.toString(),
  //       date: appointmentModel?.date ?? "");
  //   if (res != null) {
  //     for (int i = 0; i < res.length; i++) {
  //       if (res[i].appointmentId == appointmentModel?.id) {
  //         _queueNumber = i + 1;
  //         break;
  //       }
  //     }
  //   } else {
  //     _queueNumber = null;
  //   }
  //   setState(() {
  //     _isLoadingQueue = false;
  //   });
  // }
  //
  // void openBoxToCheckIn() {
  //   showModalBottomSheet(
  //     backgroundColor: ColorResources.bgColor,
  //     isScrollControlled: true,
  //     shape: RoundedRectangleBorder(
  //       borderRadius: BorderRadius.circular(20.0),
  //     ),
  //     context: context,
  //     builder: (BuildContext context) {
  //       return StatefulBuilder(
  //           builder: (BuildContext context, setState) {
  //             return Container(
  //                 height: MediaQuery
  //                     .of(context)
  //                     .size
  //                     .height * 0.8,
  //                 decoration: const BoxDecoration(
  //                   color: ColorResources.bgColor,
  //                   borderRadius: BorderRadius.only(
  //                     topRight: Radius.circular(20.0),
  //                     topLeft: Radius.circular(20.0),
  //                   ),
  //                 ),
  //                 //  height: 260.0,
  //                 child: Stack(
  //                   children: [
  //                     Positioned(
  //                         top: 20,
  //                         left: 5,
  //                         right: 5,
  //                         bottom: 0,
  //                         child: Column(
  //                           crossAxisAlignment: CrossAxisAlignment.center,
  //                           mainAxisAlignment: MainAxisAlignment.center,
  //                           children: [
  //                             Image.asset(ImageConstants.checkImageBox,
  //                               height: 80,
  //                               width: 80,
  //                             ),
  //                             const SizedBox(height: 30),
  //                             Text("appointment_id".trParams({"id":"${widget.labBookingId}"}),
  //                                 style: const TextStyle(
  //                                     fontWeight: FontWeight.w500,
  //                                     fontSize: 14
  //                                 )
  //                             ),
  //                             const SizedBox(height: 5),
  //                             Text("appointment_type".trParams({"type":appointmentModel?.type ??
  //                                 "--"}),
  //                                 style: const TextStyle(
  //                                     fontWeight: FontWeight.w500,
  //                                     fontSize: 14
  //                                 )
  //                             ),
  //                             const SizedBox(height: 5),
  //                             Text("date_checkin".trParams({"date":DateTimeHelper.getDataFormat(
  //                                 appointmentModel?.date ?? "")}),
  //                                 style: const TextStyle(
  //                                     fontWeight: FontWeight.w500,
  //                                     fontSize: 14
  //                                 )
  //                             ),
  //                             const SizedBox(height: 5),
  //                             Text("time_checkin".trParams({"time":DateTimeHelper
  //                                 .convertTo12HourFormat(
  //                                 appointmentModel?.timeSlot ?? "")}),
  //                                 style: const TextStyle(
  //                                     fontWeight: FontWeight.w500,
  //                                     fontSize: 14
  //                                 )
  //                             ),
  //                             const Padding(
  //                               padding: EdgeInsets.all(20),
  //                               child: Divider(),
  //                             ),
  //                             QRCode(
  //                                 size: 300,
  //                                 data: getQrCodeData()
  //
  //                             ),
  //                             Text(
  //                               "checkin_desc".tr,
  //                               textAlign: TextAlign.center,
  //                               style: const TextStyle(
  //                                   fontWeight: FontWeight.w500,
  //                                   fontSize: 14
  //                               ),
  //                             )
  //                           ],
  //                         )
  //                     ),
  //                   ],
  //                 )
  //             );
  //           }
  //       );
  //     },
  //   ).whenComplete(() {
  //
  //   });
  // }
  // String getQrCodeData() {
  //   final qrData = {
  //     "appointment_id": widget.labBookingId,
  //     "date": appointmentModel?.date,
  //     "time": appointmentModel?.timeSlot
  //   };
  //   return jsonEncode(qrData);
  // }
  _buildReviewBox() {
    return Padding(
      padding: const EdgeInsets.only(top:8.0),
      child: Card(
        color: ColorResources.cardBgColor,
        elevation: .1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(5.0),
        ),
        child: ListTile(
          onTap: () {
            _openDialogBoxReview();
          },
          title:  Text("review".tr,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500
            ),),
          subtitle:  Text("click_here_review".tr,
            style:const  TextStyle(
                fontSize: 13,
                color: ColorResources.secondaryFontColor,
                fontWeight: FontWeight.w400
            ),),
        ),
      ),
    );
  }
  _openDialogBoxReview() {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        // return object of type Dialog
        return StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.0),
                ),
                title:  Text(
                  "review".tr,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("give_review_to".trParams({"labName":appointmentModel?.pathologyTitle??""}),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontWeight: FontWeight.w400, fontSize: 12)),
                    const SizedBox(height: 10),
                    StarRating(
                      mainAxisAlignment: MainAxisAlignment.center,
                      length: 5,
                      color: Colors.amber,
                      rating: _rating,
                      between: 5,
                      starSize: 30,
                      onRaitingTap: (rating) {
                        // print('Clicked rating: $rating / $starLength');
                        setState(() {
                          _rating = rating;
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    Container(
                      decoration: ThemeHelper().inputBoxDecorationShaddow(),
                      child: TextFormField(
                        maxLines: 5,
                        keyboardType: TextInputType.multiline,
                        validator: null,
                        controller: textEditingController,
                        decoration: ThemeHelper().textInputDecoration('review'.tr),
                      ),
                    )
                  ],
                ),
                actions: <Widget>[
                  ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorResources.btnColorRed,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                              10), // Change this value to adjust the border radius
                        ),
                      ),
                      child:  Text("cancel".tr,
                          style:
                          TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w400, fontSize: 12)),
                      onPressed: () {
                        Navigator.of(context).pop();
                      }),
                  ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorResources.btnColorGreen,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                              10), // Change this value to adjust the border radius
                        ),
                      ),
                      child:  Text(
                        "submit".tr,
                        style:const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w400, fontSize: 12),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                        _handleToSubmitReview();
                        // _handleAppointmentCanReq();
                      }),
                  // usually buttons at the bottom of the dialog
                ],
              );
            }
        );
      },


    );
  }
  void _handleToSubmitReview() async {
    setState(() {
      _isLoading = true;
    });
    final res = await PathologistService.addPathReView(
      labBookingId: appointmentModel?.id.toString() ?? "",
      description: textEditingController.text,
      points: _rating.toString(),
    );
    if (res != null) {
      IToastMsg.showMessage("success".tr);
      _appointmentCancellationController.getData(
          bookingId: widget.labBookingId ?? "-1");
      getAndSetData();
    }
    setState(() {
      _isLoading = false;
    });
  }

  void handleRebookButton()async {
    setState(() {
      _isLoading=true;
    });
    final idList=appointmentModel?.labTests!=null?appointmentModel!.labTests!.map((e) => e['lab_test_id'].toString()).toList():[];
         final idsList =idList.join(",");
      final res=await LabCartService.deleteAndAddData(idsList:idsList );
      if(res!=null){
        IToastMsg.showMessage("lab_added_to_cart".tr);
        if(appointmentModel?.pathId!=null){
          Get.to(()=>LabCartCheckOutPage(pathId: appointmentModel?.pathId.toString()));
        }
      }
    setState(() {
      _isLoading=false;
    });

  }
}
