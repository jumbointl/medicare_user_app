import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:medicare_user_app/helpers/currency_formatter_helper.dart';
import 'package:medicare_user_app/services/lab_booking_service.dart';
import 'package:medicare_user_app/services/pathologist_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../controller/lab_cart_controller.dart';
import '../model/lab_cart_model.dart';
import '../services/configuration_service.dart';
import '../services/coupon_service.dart';
import '../services/lab_cart_service.dart';
import '../utilities/sharedpreference_constants.dart';
import '../widget/app_bar_widget.dart';
import 'package:get/get.dart';
import '../widget/bottom_button.dart';
import '../helpers/date_time_helper.dart';
import '../helpers/route_helper.dart';
import '../helpers/theme_helper.dart';
import '../model/family_members_model.dart';
import '../model/user_model.dart';
import '../services/family_members_service.dart';
import '../services/user_service.dart';
import '../utilities/api_content.dart';
import '../utilities/colors_constant.dart';
import '../utilities/image_constants.dart';
import '../widget/button_widget.dart';
import '../widget/image_box_widget.dart';
import '../widget/loading_Indicator_widget.dart';
import '../widget/toast_message.dart';
import '../bancard/bancard_lab_booking_payment_provider.dart';
import '../bancard/medicare_client_payment_gateway_page.dart';

class LabCartCheckOutPage extends StatefulWidget {
  final String? pathId;
  const LabCartCheckOutPage({super.key, required this.pathId});

  @override
  State<LabCartCheckOutPage> createState() => _LabCartCheckOutPageState();
}

class _LabCartCheckOutPageState extends State<LabCartCheckOutPage> {
  final BancardLabBookingPaymentProvider bancardLabBookingPaymentProvider =
  BancardLabBookingPaymentProvider();
  String email="";
  bool stopBooking=false;
   final LabCartController _cartController=Get.find(tag: "lab_cart");
  final GlobalKey<FormState> _formKey =  GlobalKey<FormState>();
  final TextEditingController _mobileController=TextEditingController();
  final TextEditingController _fNameController=TextEditingController();
  final TextEditingController _lNameController=TextEditingController();
   bool couponEnable=false;
   final TextEditingController _couponNameController=TextEditingController();
  List<FamilyMembersModel> familyModelList=[];
  String selectedDate = "";
   String? pathName;
  FamilyMembersModel? selectedFamilyMemberModel;
  bool _isLoading=false;
  double totalCartSumAmount=0;
  UserModel? userModel;
  int payNow=1;
  String phoneCode="+";
  double offPrice=0;
  int? couponId;
  double? couponValue;
  // double tax=0;
  // double unitTaxAmount=0;
  double unitTotalAmount=0;
  double totalAmount=0;

  final GlobalKey<FormState> _formKey3 =  GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();

  @override
  void initState() {
    // TODO: implement initState
    getAndSetData();
    selectedDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(bottomNavigationBar:
    _isLoading?null:stopBooking?
    Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.warning_amber_rounded,color: ColorResources.redColor,size: 25),
          SizedBox(width: 5),
          Text("current_not_accepting_booking".tr,
              style:const TextStyle(
                  color: ColorResources.redColor,
                  fontWeight: FontWeight.w500,
                  fontSize: 18

              )),
        ],
      ),
    )
        :_buildBottomButton(),
        appBar: IAppBar.commonAppBar(title: "lab_test".tr),
      body: _isLoading?ILoadingIndicatorWidget():_buildCartList(),
    );
  }
_buildBottomButton(){
    return  Obx(() {
      if (!_cartController.isError.value) { // if no any error
      return IBottomNavBarWidget(onPressed:_cartController.isLoading.value||_cartController.dataList.isEmpty?null: (){
        if(selectedFamilyMemberModel==null){
          _openBottomSheetPatient(setState,true);
        }else{
          amtCalculation();
          openCartBox();
        }
      },title:"total_and_pay".trParams({
        "amt":CurrencyFormatterHelper.format(getTotalAmt(_cartController.dataList))
      }));
      }else {
        return Container();
      } //Error svg
    }
    );
}
  _buildCartList() {
    return  _isLoading?ILoadingIndicatorWidget(): Obx(() {
      if (!_cartController.isError.value) { // if no any error
        if (_cartController.isLoading.value) {
          return const IVerticalListLongLoadingWidget();
        } else if (_cartController.dataList.isEmpty) {
          return  Container();
        } else {
          return _generateList(_cartController.dataList);
        }
      }else {
        return Container();
      } //Error svg
    }
    );
  }
  _generateList(List dataList){
    return  ListView.builder(
        padding: const EdgeInsets.all(0),
        itemCount: dataList.length,
        shrinkWrap: true,
        itemBuilder: (context,index){
          final LabCartModel labCartModel=dataList[index];
          return   Padding(
            padding: const EdgeInsets.only(top:3.0),
            child: Card(
              color:  ColorResources.cardBgColor,
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5),
              ),
              child: Padding(
                  padding: const EdgeInsets.all(0.0),
                  child: Column(
                    children: [
                      ListTile(
                          isThreeLine: true,
                          leading: labCartModel.image==null|| labCartModel.image==""? const SizedBox(
                            width: 70,
                            child: Icon(Icons.image,
                              size: 40,),
                          ):   SizedBox(
                            height: 70,
                            width: 70,
                            child: CircleAvatar(child:ImageBoxFillWidget(
                              imageUrl:
                              "${ApiContents.imageUrl}/${labCartModel.image}",
                              boxFit: BoxFit.fill,
                            )),
                          ),
                          title:  Text(labCartModel.title??"--",
                            style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 14
                            ),),
                          subtitle:   Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 3),
                              Text(labCartModel.subTitle??"",
                                overflow:TextOverflow.ellipsis ,
                                maxLines: 1,
                                style: const TextStyle(
                                    color: ColorResources.secondaryFontColor,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 12
                                ),),
                              const SizedBox(height: 3),
                          Text(CurrencyFormatterHelper.format(labCartModel.amount??0),

                                overflow:TextOverflow.ellipsis ,
                                maxLines: 1,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14
                                ),),
                              const SizedBox(height: 3),
                              Text(labCartModel.pathologistTitle??"",
                                overflow:TextOverflow.ellipsis ,
                                maxLines: 1,
                                style: const TextStyle(
                                    color: ColorResources.secondaryFontColor,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 12
                                ),),
                              const SizedBox(height: 3),
                              TextButton(
                                onPressed: () {
                                  _openDialogSettingBox(labCartModel);
                                },
                                style: TextButton.styleFrom(
                                  side: BorderSide(color: Colors.grey.shade200), // Border color
                                  shape: RoundedRectangleBorder( // Optional: for rounded corners
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding: EdgeInsets.symmetric(horizontal: 5, vertical: 0),
                                ),
                                child: Text(
                                  "remove_x".tr,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.red,
                                  ),
                                ),
                              ),


                            ],
                          )),
                      labCartModel.subtests==null||labCartModel.subtests!.isEmpty?Container():
                      Padding(
                        padding: const EdgeInsets.only(left:8.0,right: 8),
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
                              //  controller: _scrollController,
                              shrinkWrap: true,
                              itemCount: labCartModel.subtests!.length,
                              itemBuilder: (context,subIndex){
                                final subTest=labCartModel.subtests![subIndex];
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
                  )

              ),
            ),
          );
        });
  }
  _openDialogSettingBox(LabCartModel labCartModel) {
    return showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        // return object of type Dialog
        return PopScope(
          canPop: true,
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.0),
            ),
            title:  Text("remove".tr,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 18
              ),),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("remove_from_cart".trParams({"title":labCartModel.title.toString()}),

                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontWeight: FontWeight.w400,
                        fontSize: 12
                    )),
                const SizedBox(height: 10),

              ],
            ),
            actions: <Widget>[
               ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorResources.greenFontColor,
                  ),
                  child:  Text("yes".tr,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w400,
                          fontSize: 12
                      )),
                  onPressed: () {
                    Navigator.of(context).pop();
                    handleRemoveFromCart(labCartModel.id.toString());
                  }) ,
              ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorResources.redColor,
                  ),
                  child:  Text("no".tr,
                    style: TextStyle(
                      color: Colors.white,
                        fontWeight: FontWeight.w400,
                        fontSize: 12
                    ),),
                  onPressed: () async {
                  Get.back();
                  }),
              // usually buttons at the bottom of the dialog
            ],
          ),
        );
      },
    );
  }
  void handleRemoveFromCart(String id)async {
    setState(() {
      _isLoading=true;
    });
      final res=await LabCartService.deleteData(id: id);
    if(res!=null){
     _cartController.getData(widget.pathId??"");
      IToastMsg.showMessage("success".tr);
    }
    setState(() {
      _isLoading=false;
    });
  }

 double getTotalAmt(List data) {
   totalCartSumAmount=0;
    for(var e in data){
      double amount =(e.amount!*(e.qty??1));
      totalCartSumAmount+=amount;
    }
   totalAmount=totalCartSumAmount;
    return double.parse(totalCartSumAmount.toStringAsFixed(2));
  }
  openCartBox() {
    return
      showModalBottomSheet(
        backgroundColor:  ColorResources.cardBgColor,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(20.0),
            topLeft: Radius.circular(20.0),
          ),
        ),
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(
              builder: (BuildContext context, setState) {
                return Padding(
                  padding: MediaQuery
                      .of(context)
                      .viewInsets,
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Form(
                         key: _formKey,
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(height: 20),
                            Image.asset(ImageConstants.appointmentImage,
                              height: 150,
                              width: 150,),
                            const SizedBox(height: 5),
                            Text("only_one_step_away_lab".tr,
                              style:const TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14
                              ),),
                            const  Divider(),
                            const SizedBox(height: 10),
                            _buildFamilyMemberCard(setState),
                            const SizedBox(height: 10),
                            // tax==0?Container(): Padding(
                            //   padding: const EdgeInsets.only(top:10.0),
                            //   child: Row(
                            //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            //     children: [
                            //       Text("tax_value".trParams({"tax":"$tax"}),
                            //         style: const TextStyle(
                            //             fontSize: 14,
                            //             fontWeight: FontWeight.w500
                            //         ),),
                            //       Text("+$unitTaxAmount${AppConstants.appCurrency}",
                            //           style: const TextStyle(
                            //               fontSize: 14,
                            //               fontWeight: FontWeight.w500
                            //           ))
                            //     ],
                            //   ),
                            // ),
                            Card(
                              color: ColorResources.cardBgColor,
                              elevation: .05,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5.0),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(left:10.0),
                                    child: Text("date".tr,
                                      style:const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500
                                      ),),
                                  ),
                                  Row(
                                    children: [
                                      Text(DateTimeHelper.getDataFormat(selectedDate),
                                          style:const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500
                                          )),
                                      IconButton(onPressed: (){
                                        _selectDate(context,setState);
                                      }, icon: Icon(Icons.edit,
                                        color: ColorResources.btnColor,
                                      ))
                                    ],
                                  )

                                ],
                              ),
                            ),
                              const SizedBox(height: 10),
                            Card(
                              color: ColorResources.cardBgColor,
                              elevation: .1,
                              child:  Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(pathName??"--",
                                      style:const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600
                                      ),),
                                    const SizedBox(height: 5),
                                    Text("payment_summary".tr,
                                      style:const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600
                                      ),),
                                    const SizedBox(height: 10),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text("total_amount".tr,
                                          style:const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500
                                          ),),
                                        Text(CurrencyFormatterHelper.format(totalCartSumAmount),
                                            style:const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500
                                            ))
                                      ],
                                    ),
                                    couponValue==null?Container(): Padding(
                                      padding: const EdgeInsets.only(top:10.0),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text("coupon_off".trParams({"value":"$couponValue"}),
                                            style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500
                                            ),),
                                          Text("-${CurrencyFormatterHelper.format(offPrice)}",
                                              style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500
                                              ))
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text("final_total".tr,
                                          style:const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500
                                          ),),
                                        Text(CurrencyFormatterHelper.format(totalAmount),
                                            style:const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500
                                            ))
                                      ],
                                    ),

                                  ],
                                ),
                              ),
                            ),

                            // Padding(
                            //   padding: const EdgeInsets.only(top:8.0),
                            //   child: Container(
                            //     decoration: ThemeHelper().inputBoxDecorationShaddow(),
                            //     child: TextFormField(
                            //       keyboardType: TextInputType.name,
                            //       validator: ( item){
                            //         return null;
                            //       },
                            //       controller: _prescriptionIdController,
                            //       decoration: ThemeHelper().textInputDecoration('Prescription Id'.tr),
                            //     ),
                            //   ),
                            // ),
                        RadioListTile(
                          value: 1,
                          groupValue: payNow,
                              onChanged: (value){
                                clearCoupon();
                                setState((){
                                  payNow=1;
                                });
                              },
                              title: Text("pay_now".tr,
                                style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500
                                ),
                              ),
                            ),
                            payNow==1&&couponEnable?
                            _buildCouponCode(setState)

                                :Container(),

                                RadioListTile(
                                  value: 0,
                                  groupValue: payNow,
                              onChanged: (value){
                                // Get.back();
                                clearCoupon();
                                setState((){
                                  payNow=0;
                                });
                                //    openAppointmentBox();
                              },
                              title:  Text("pay_at_lab".tr,
                                style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500
                                ),
                              ),
                            ),
                            RadioListTile(
                              value: 2,
                              groupValue: payNow,
                              onChanged: ((userModel?.walletAmount??0) >= totalAmount)?(value){
                                clearCoupon();
                                setState((){
                                  payNow=2;
                                });
                              }:
                                  (value){
                                Get.toNamed(RouteHelper.getWalletPageRoute());
                              },
                              title:  Text("pay_from_wallet_av".trParams({
                                "walletAmount":CurrencyFormatterHelper.format(userModel?.walletAmount??0),
                              }),
                                style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500
                                ),
                              ),
                              subtitle:((userModel?.walletAmount??0) >= totalAmount)?Container():
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("insufficient_amount_in_your_wallet".tr,
                                    style: const TextStyle(
                                        color: Colors.redAccent,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500
                                    ),
                                  ),
                                  Text("tap_here_to_recharge_wallet".tr,
                                      style: const  TextStyle(
                                          color: ColorResources.btnColor,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500
                                      )
                                  )
                                ],
                              ),
                            ),
                            SmallButtonsWidget(title:
                           "pay_and_book_amt_lab".trParams(
                               {"totalAmount":CurrencyFormatterHelper.format(totalAmount),
                            }),
                                 onPressed: (){
                              amtCalculation();
                              // print(totalAmount);
                              Get.back();
                              if (payNow == 1) {
                                handleAddLabBookingAndStartPayment();
                              } else {
                                handleAddAppointment();
                              }

                            })

                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }
          );
        },

      ).whenComplete(() {

      });
  }
  void handleAddLabBookingAndStartPayment() async {
    setState(() {
      _isLoading = true;
    });

    final res = await LabBookingService.addBooking(
      familyMemberId: selectedFamilyMemberModel?.id.toString() ?? "",
      patientId: "",
      status: "Confirmed",
      pathId: widget.pathId ?? "",
      paymentStatus: "Unpaid",
      totalAmount: totalAmount.toString(),
      invoiceDescription: "Lab Booking",
      paymentMethod: "Online",
      paymentTransactionId: "",
      isWalletTxn: "0",
      couponId: couponId == null ? "" : couponId.toString(),
      couponOffAmount: offPrice.toString(),
      couponTitle: _couponNameController.text,
      couponValue: couponValue == null ? "" : couponValue.toString(),
      date: selectedDate,
      labTestCartData: _cartController.dataList,
    );

    if (res == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    final dynamic bookingIdRaw = res['id'];
    final int bookingId = int.tryParse(bookingIdRaw.toString()) ?? 0;

    if (bookingId <= 0) {
      setState(() {
        _isLoading = false;
      });
      IToastMsg.showMessage("No se recibió el ID de la reserva.");
      return;
    }

    final userRes = await UserService.getDataById();
    final int userId = int.tryParse(userRes?.id?.toString() ?? '') ?? -1;

    if (userId <= 0) {
      setState(() {
        _isLoading = false;
      });
      IToastMsg.showMessage("No se encontró el usuario.");
      return;
    }

    final startRes =
    await bancardLabBookingPaymentProvider.startLabBookingPayment(
      labBookingId: bookingId,
      userId: userId,
      paymentTypeId: 7500,
      amount: totalAmount,
      currency: 'PYG',
      description: 'Lab booking #$bookingId',
    );

    if (startRes == null) {
      setState(() {
        _isLoading = false;
      });
      IToastMsg.showMessage("No se pudo iniciar el pago.");
      return;
    }

    final Map<String, dynamic> root = startRes;
    final Map<String, dynamic> data =
    root['data'] is Map<String, dynamic>
        ? Map<String, dynamic>.from(root['data'])
        : root['data'] is Map
        ? Map<String, dynamic>.from(root['data'])
        : root;

    final Map<String, dynamic> paymentFlow =
    data['payment_flow'] is Map<String, dynamic>
        ? Map<String, dynamic>.from(data['payment_flow'])
        : data['payment_flow'] is Map
        ? Map<String, dynamic>.from(data['payment_flow'])
        : <String, dynamic>{};

    final String mode = paymentFlow['mode']?.toString() ?? '';

    if (mode == 'manual_validation') {
      setState(() {
        _isLoading = false;
      });
      IToastMsg.showMessage("Pago pendiente de validación manual.");
      Get.offNamedUntil(
        RouteHelper.getLabBookingDetailsPageRoute(labBookingId: bookingId.toString()),
        ModalRoute.withName('/HomePage'),
      );
      return;
    }

    if (mode == 'auto_paid') {
      setState(() {
        _isLoading = false;
      });
      IToastMsg.showMessage("Pago registrado correctamente.");
      Get.offNamedUntil(
        RouteHelper.getLabBookingDetailsPageRoute(labBookingId: bookingId.toString()),
        ModalRoute.withName('/HomePage'),
      );
      return;
    }

    final String? checkoutPageUrl =
    paymentFlow['checkout_page_url']?.toString();
    final String? paymentUrl = paymentFlow['payment_url']?.toString();

    if ((checkoutPageUrl == null || checkoutPageUrl.isEmpty) &&
        (paymentUrl == null || paymentUrl.isEmpty)) {
      setState(() {
        _isLoading = false;
      });
      IToastMsg.showMessage("No se recibió URL de pago.");
      return;
    }

    setState(() {
      _isLoading = false;
    });

    final dynamic result = await Get.to(
          () => MedicareClientPaymentGatewayPage(),
      arguments: {
        'lab_booking_id': bookingId,
        'patient_name':
        '${selectedFamilyMemberModel?.fName ?? "--"} ${selectedFamilyMemberModel?.lName ?? "--"}',
        'payment_amount': totalAmount,
        'checkout_page_url': checkoutPageUrl,
        'payment_url': paymentUrl,
        'payment_id': paymentFlow['payment_id'],
        'payment_type_id': paymentFlow['payment_type_id'],
        'provider': paymentFlow['provider'],
        'provider_reference': paymentFlow['provider_reference'],
        'provider_process_id': paymentFlow['provider_process_id'],
        'flow_type': 'lab_booking',
      },
    );

    if (result is Map) {
      final String status =
          result['payment_gateway_status']?.toString() ?? 'unknown';

      if (status == 'success') {
        IToastMsg.showMessage("success".tr);
      } else if (status == 'canceled') {
        IToastMsg.showMessage("Pago cancelado. La reserva sigue pendiente.");
      } else {
        IToastMsg.showMessage("La reserva sigue pendiente de pago.");
      }
    }

    Get.offNamedUntil(
      RouteHelper.getLabBookingHistoryPageRoute(),
      ModalRoute.withName('/HomePage'),
    );
  }

  _buildFamilyMemberCard(setState) {
    return Card(
      color: ColorResources.cardBgColor,
      elevation: .05,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(5.0),
      ),
      child:  ListTile(
        leading:const  Icon(Icons.person,
          size: 20,),
        trailing:
        GestureDetector(
          onTap: (){

              _openBottomSheetPatient(setState,false);

          },
          child: Container(
            height: 25,
            width: 25,
            decoration: const BoxDecoration(
                shape: BoxShape.circle, // This makes the container circular
                color: ColorResources.btnColor // Background color of the button
            ),
            child: const Icon(
              Icons.add,
              size: 15,
              color: Colors.white, // Color of the icon
            ),

          ),
        ),
        title: Text("patient".tr,
          style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500
          ),),
        subtitle: selectedFamilyMemberModel==null?null:Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 3),
            Text("${selectedFamilyMemberModel?.fName??"--"} ${selectedFamilyMemberModel?.lName??"--"}",
              style: const TextStyle(
                  fontWeight: FontWeight.w400,
                  fontSize: 14
              ),),
            const SizedBox(height: 3),
            Text(selectedFamilyMemberModel?.phone??"--",
              style: const TextStyle(
                  fontWeight: FontWeight.w400,
                  fontSize: 14
              ),)
          ],
        ),
      ),

    );
  }

  void getAndSetData() async{
    setState(() {
      _isLoading=true;
    });
    final userRes=await UserService.getDataById();
    if(userRes!=null){
      userModel=userRes;
      email=userRes.email??"";
    }
    final  familyMemberList=await FamilyMembersService.getData();
    if(familyMemberList!=null&&familyMemberList.isNotEmpty){
      familyModelList=familyMemberList;
    }
    _cartController.getData(widget.pathId??"");

    final  pathData=await PathologistService.getDataById(pathId: widget.pathId);
    if(pathData!=null){
      pathName=pathData.title;
      couponEnable=pathData.couponEnable==1?true:false;
      stopBooking=pathData.stopBooking==1?true:false;
      if(stopBooking==false){
        stopBooking=pathData.active==1?false:true;
      }
    }
    final resConfig=await ConfigurationService.getDataById(idName: "stop_booking_pathology");
    if(resConfig!=null){
      if(resConfig.value=="true"){
        stopBooking=true;
      }
    }

    setState(() {
      _isLoading=false;
    });

  }
  _openBottomSheetAddPatient(){
    return
      showModalBottomSheet(
        backgroundColor:  ColorResources.bgColor,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(20.0),
            topLeft: Radius.circular(20.0),
          ),
        ),
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(
              builder: (BuildContext context, setState) {
                return Padding(
                  padding: MediaQuery
                      .of(context)
                      .viewInsets,
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text("register_new_member".tr,
                            style: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize:15
                            ),),
                          const SizedBox(height: 20),
                          Container(
                            decoration: ThemeHelper().inputBoxDecorationShaddow(),
                            child: TextFormField(
                              keyboardType: TextInputType.name,
                              validator: ( item){
                                return item!.length>=2?null:"enter_first_name".tr;
                              },
                              controller: _fNameController,
                              decoration: ThemeHelper().textInputDecoration('first_name_label'.tr),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            decoration: ThemeHelper().inputBoxDecorationShaddow(),
                            child: TextFormField(
                              keyboardType: TextInputType.name,
                              validator: ( item){
                                return item!.length>=2?null:"enter_last_name".tr;
                              },
                              controller: _lNameController,
                              decoration: ThemeHelper().textInputDecoration('last_name_label'.tr),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            decoration: ThemeHelper().inputBoxDecorationShaddow(),
                            child:
                            TextFormField(
                                inputFormatters: <TextInputFormatter>[
                                  FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                                ],
                                keyboardType:Platform.isIOS? const TextInputType.numberWithOptions(decimal: true, signed: true)
                                    : TextInputType.number,
                                validator: (item) {
                                  return item!.length > 5 ? null : "enter_valid_number".tr;
                                },
                                controller: _mobileController,
                                decoration: InputDecoration(
                                  prefixIcon: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const SizedBox(width: 9),
                                      GestureDetector(child: Padding(
                                        padding: const EdgeInsets.only(right:8.0),
                                        child:  Text(phoneCode,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.black
                                          ),),

                                      ),
                                        onTap: (){
                                          showCountryPicker(
                                            context: context,
                                            showPhoneCode: true, // optional. Shows phone code before the country name.
                                            onSelect: (Country country) {
                                              phoneCode="+${country.phoneCode}";
                                              setState((){});
                                            },
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                  hintText: "1234567890",
                                  fillColor: Colors.white,
                                  filled: true,
                                  contentPadding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0), borderSide: const BorderSide(color: Colors.grey)),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0), borderSide: BorderSide(color: Colors.grey.shade400)),
                                  errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0), borderSide: const BorderSide(color: Colors.red, width: 2.0)),
                                  focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0), borderSide:const BorderSide(color: Colors.red, width: 2.0)),
                                )
                            ),
                          ),
                          const SizedBox(height: 20),
                          SmallButtonsWidget(title: "save".tr, onPressed: (){
                            if(_formKey.currentState!.validate()){
                              Get.back();
                              handleAddFamilyMemberData();
                              //  handleAddData();
                            }


                          }),
                        ],
                      ),
                    ),
                  ),
                );
              }
          );
        },

      ).whenComplete(() {

      });
  }
  _openBottomSheetPatient(setStateCart, isOpenCart){
    return
      showModalBottomSheet(
        backgroundColor:  ColorResources.bgColor,
        isScrollControlled: true,
        shape:  RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
        ),
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(
              builder: (BuildContext context, setState) {
                return Container(
                    height: MediaQuery.of(context).size.height * 0.9,
                    decoration: const BoxDecoration(
                      color: ColorResources.bgColor,
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(20.0),
                        topLeft: Radius.circular(20.0),
                      ),
                    ),
                    //  height: 260.0,
                    child:Stack(
                      children: [
                        Positioned(
                            top: 10,
                            right: 20,
                            left: 20,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text("add_select_family_member".tr,
                                  style:const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600
                                  ),),
                                GestureDetector(
                                  onTap: (){
                                    Get.back();
                                    if(!isOpenCart){
                                      Get.back();
                                    }
                                    _openBottomSheetAddPatient();
                                  },
                                  child: Card(
                                    color: ColorResources.btnColor,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(5.0),
                                    ),
                                    child:  Padding(
                                      padding:const  EdgeInsets.all(8.0),
                                      child: Text("add_new".tr,
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w500
                                          )),
                                    ),
                                  ),
                                )
                              ],
                            )),

                        Positioned(
                            top: 60,
                            left: 5,
                            right: 5,
                            bottom: 0,
                            child: ListView(
                              children: [
                                ListView.builder(
                                    shrinkWrap: true,
                                    itemCount: familyModelList.length,
                                    itemBuilder: (context,index){
                                      FamilyMembersModel familyModel = familyModelList[index];
                                      return Card(
                                          color: ColorResources.cardBgColor,
                                          elevation: .1,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(5.0),
                                          ),
                                          child: ListTile(
                                            onTap: (){
                                              selectedFamilyMemberModel=familyModel;
                                              setStateCart((){});
                                              Get.back();
                                              if(isOpenCart){openCartBox();}
                                            },
                                            leading:const  Icon(Icons.person),
                                            title: Text("${familyModel.fName} ${familyModel.lName}",
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w500,
                                                  fontSize: 15
                                              ),
                                            ),
                                            subtitle:Text("${familyModel.phone}",
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w400,
                                                  fontSize: 13
                                              ),
                                            ) ,
                                          ));
                                    }),


                              ],
                            )
                        ),
                      ],
                    )
                );
              }
          );
        },
      ).whenComplete(() {

      });
  }
  void handleAddFamilyMemberData() async {
    setState(() {
      _isLoading = true;
    });
    final res = await FamilyMembersService.addUser(
        fName: _fNameController.text,
        lName: _lNameController.text,
        isdCode: phoneCode,
        phone: _mobileController.text,
        dob: "",
        gender: "");
    if (res != null) {
      IToastMsg.showMessage("success".tr);
      clearInitData();
      getFamilyMemberListList();

    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }
    void clearInitData() {
      _fNameController.clear();
      _lNameController.clear();
      _mobileController.clear();

    }
    getFamilyMemberListList()async{
      setState(() {
        _isLoading = true;
      });
      final  familyList=await FamilyMembersService.getData();
      if(familyList!=null&&familyList.isNotEmpty){
        familyModelList=familyList;
        selectedFamilyMemberModel=familyList[0];
        openCartBox();

        }

      setState(() {
        _isLoading = false;
      });
    }
  void amtCalculation(){
    unitTotalAmount=totalCartSumAmount;
    if(totalCartSumAmount==0){return;}
    if(couponValue!=null){
      offPrice=(totalCartSumAmount*couponValue!)/100;
    }else{
      offPrice=0;
    }
    // totalAmount=appointmentFee-offPrice;
    // if(tax!=0){
    //   unitTaxAmount=(totalCartSumAmount*tax)/100;
    //   unitTotalAmount=totalCartSumAmount+unitTaxAmount;
    // }
    totalAmount=totalCartSumAmount-offPrice;
    setState(() {
    });
  }

  Future<void> _selectDate(BuildContext context,setStateCart) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate:  DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 7)),
    );
    if (picked != null) {
      setStateCart(() {
        selectedDate = DateFormat('yyyy-MM-dd').format(picked);
    //   DateTimeHelper.getDataFormat(selectedDate);
      });
    }
  }

   void handleAddAppointment() async {
     setState(() {
       _isLoading=true;
     });

     final res=await LabBookingService.addBooking(
         familyMemberId:selectedFamilyMemberModel?.id.toString()??"",
         patientId: "",
         status: "Confirmed",
          pathId: widget.pathId??"",
         paymentStatus:payNow==1||payNow==2?"Paid":"Unpaid",
         totalAmount:  totalAmount.toString(),
         invoiceDescription:"Lab Booking",
         paymentMethod: "Online",
         paymentTransactionId: payNow==1?"hywv387492":payNow==2?"Wallet":"",
         isWalletTxn:  payNow==2?"1":"0",
         couponId:couponId==null?"":couponId.toString(),
         couponOffAmount:offPrice.toString() ,
       couponTitle: _couponNameController.text,
         couponValue: couponValue==null?"":couponValue.toString(),
          date: selectedDate,
       labTestCartData: _cartController.dataList,

     );
     if(res!=null){
       IToastMsg.showMessage("success".tr);
       setState(() {
         _isLoading=false;
       });
       Get.offNamedUntil(RouteHelper.getLabBookingHistoryPageRoute(), ModalRoute.withName('/HomePage'));
     }else{
       setState(() {
         _isLoading=false;
       });
     }
   }
   void clearCoupon() {
     couponValue=null;
     couponId=null;
     _couponNameController.clear();
     amtCalculation();
     setState(() {
     });

   }
   _buildCouponCode(setstate) {
     return    Row(
       children: [
         Flexible(
           flex: 4,
           child: Container(
               decoration: ThemeHelper().inputBoxDecorationShaddow(),
               child: TextFormField(
                 keyboardType: TextInputType.name,
                 validator: ( item){
                   return item!.length>2?null:"enter_coupon_code_if_any".tr;
                 },
                 controller: _couponNameController,
                 decoration: ThemeHelper().textInputDecoration('coupon_code'.tr),
               )),
         ),
         Flexible(
           flex: 2,
           child: Padding(
             padding: const EdgeInsets.only(left:8.0,right: 8),
             child: SmallButtonsWidget(title: couponValue==null?"apply".tr:"remove".tr, onPressed:
             couponValue==null?  ()async{
               if(_formKey.currentState!.validate()){
                 Get.back();
                 handelCheckCoupon();
               }
             }:(){
               clearCoupon();
               setState(() {
               });
               Get.back();
               openCartBox();
               IToastMsg.showMessage("coupon_removed".tr);
             }

             ),
           ),

         )
       ],
     );
   }
   void handelCheckCoupon()async {
     setState(() {
       _isLoading=true;
     });

     final res=await CouponService.getValidateDataLab(
         title:_couponNameController.text.toUpperCase(),
         labId:widget.pathId

     );
     if(res!=null&&res['status']==true){
       IToastMsg.showMessage(res['msg']);
       final value=res['data']['value'];
       final couponIdGet= res['data']['id'];
       couponValue=value!=null?double.parse(value.toString()):null;
       couponId=couponIdGet!=null?int.parse(couponIdGet.toString()):null;
       amtCalculation();
     } else{
       IToastMsg.showMessage(res['msg']??"");
       clearCoupon();
     }
     setState(() {
       _isLoading=false;
     });
     openCartBox();
   }


   successPayment(){
     IToastMsg.showMessage("success".tr);
     setState(() {
       _isLoading=false;
     });
     Get.offNamedUntil(RouteHelper.getLabBookingHistoryPageRoute(), ModalRoute.withName('/HomePage'));
   }

}
