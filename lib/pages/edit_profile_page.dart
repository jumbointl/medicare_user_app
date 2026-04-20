import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../controller/notification_dot_controller.dart';
import '../controller/user_controller.dart';
import '../helpers/route_helper.dart';
import '../model/user_model.dart';
import 'package:get/get.dart';
import '../utilities/api_content.dart';
import '../helpers/date_time_helper.dart';
import '../helpers/theme_helper.dart';
import '../services/user_service.dart';
import '../utilities/colors_constant.dart';
import '../widget/button_widget.dart';
import '../widget/image_box_widget.dart';
import '../widget/loading_Indicator_widget.dart';
import '../widget/text_filed.dart';
import 'package:intl/intl.dart';
import '../widget/toast_message.dart';

class EditProfilePage extends StatefulWidget {
  final int autoCloseSeconds; // 0 = no cerrar automáticamente
  const EditProfilePage({super.key,this.autoCloseSeconds = 0});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  Timer? _autoCloseTimer;
  UserController userController=Get.find(tag: "user");
  final TextEditingController _emailController=TextEditingController();
  final TextEditingController _phoneNumberController=TextEditingController();
  final TextEditingController _fNameController=TextEditingController();
  final TextEditingController _lNameController=TextEditingController();
  final TextEditingController _dobController=TextEditingController();

  String? selectedDate="";
  String? selectedGender;
  UserModel? userModel;
  bool _isLoading=false;

  @override
  void initState() {
    // TODO: implement initState
    getAndSetData();
    super.initState();
  }
  @override
  void dispose() {
    _autoCloseTimer?.cancel();
    super.dispose();
  }
  void _scheduleAutoClose() {
    _autoCloseTimer?.cancel();

    if (widget.autoCloseSeconds <= 0) return;

    _autoCloseTimer = Timer(
      Duration(seconds: widget.autoCloseSeconds),
          () {
        if (!mounted) return;
        Get.back();
      },
    );
  }
  @override
  Widget build(BuildContext context) {
    return
    Scaffold(
      appBar: AppBar(
        leading:
        Transform.scale(
          scale: .8,
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            color: ColorResources.containerBgColor,
            child: IconButton(
              icon:  const Icon(Icons.arrow_back,size: 20.0,
              color: ColorResources.primaryColor,),
              onPressed: () =>  Get.back()
                // Perform Your action here
            ),
          ),
        ),
        elevation: 0,
        centerTitle: true,
        backgroundColor: ColorResources.primaryColor,
        title:  Text("profile".tr,
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w400
          ),
        ),
        actions: [
          Transform.scale(
            scale: .8,
            child: Card(
            color: ColorResources.redColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: IconButton(onPressed: (){
              _openDialogBox();
            }, icon: const Icon(Icons.delete,
            size: 20,
            color: Colors.white,)),
        ),
          )
        ],
      ),
      body: _isLoading?const ILoadingIndicatorWidget():_buildBody()
    );
  }

  _buildUpperSection() {
    return
      Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            height: 80,
            decoration:const BoxDecoration(
              borderRadius:  BorderRadius.only(
                bottomLeft: Radius.circular(30.0),
                bottomRight: Radius.circular(30.0),
              ),
              color: ColorResources.primaryColor,
            ),
          ),
          Positioned(
            left: 0,
              right: 0,
              bottom: -55,
              child:
              Center(
                child:
                CircleAvatar(
                  radius: 60,
                  backgroundColor: ColorResources.containerBgColor,
                  child: Padding(
                    padding: const EdgeInsets.all(3.0),
                    child: ClipOval(
                      child: SizedBox(
                          height: double.infinity,
                          width: double.infinity,
                 child: userModel?.imageUrl==null||userModel?.imageUrl==""?
                      const Icon(Icons.person,size: 70,)
                   : ImageBoxFillWidget(imageUrl: "${ApiContents.imageUrl}/${userModel?.imageUrl??""}"),
                                        )


          ),),
                  ),
                ),
              )
        ],
      );
  }

  _buildBody() {
    return ListView(
      children: [
        _buildUpperSection(),
        const SizedBox(height:70),
         Text("${userModel?.fName??""} ${userModel?.lName??""}",
          textAlign: TextAlign.center,
          style:const  TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 24
          ),),
        const SizedBox(height: 3),
        Text(userModel?.phone??"--",
          textAlign: TextAlign.center,
          style: const TextStyle(
              color: ColorResources.secondaryFontColor,
              fontWeight: FontWeight.w400,
              fontSize: 12
          ),),
        const SizedBox(height: 3),
         Text("member_since_value".trParams({"value":DateTimeHelper.getDataFormat(userModel?.createdAt)}),
          textAlign: TextAlign.center,
          style: const TextStyle(
              color: ColorResources.secondaryFontColor,
              fontWeight: FontWeight.w400,
              fontSize: 12
          ),),
        const SizedBox(height: 10),
        Column(
          children: [
            Card(
              color: ColorResources.primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.0),
              ),
              child:
               Padding(
                padding:const  EdgeInsets.fromLTRB(40, 15, 40, 15),
                child: Text("edit_profile".tr,
                  style:const  TextStyle(
                    fontWeight: FontWeight.w400,
                    color: Colors.white,
                    fontSize: 14,
                  ),),
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(left:15.0,right: 15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              ITextFields.labelText(labelText: "name".tr),
              Container(
                decoration: ThemeHelper().inputBoxDecorationShaddow(),
                child: TextFormField(
                  keyboardType: TextInputType.text,
                  validator: ( item){
                    return item!.length>3?null:"length_must_be_grater_then_5_latter".tr;
                  },
                  controller: _fNameController,
                  decoration: ThemeHelper().textInputDecoration('first_name'.tr),
                ),
              ),
              const SizedBox(height: 10),
              const SizedBox(height: 10),
              ITextFields.labelText(labelText: "last_name".tr),
              Container(
                decoration: ThemeHelper().inputBoxDecorationShaddow(),
                child: TextFormField(
                  keyboardType: TextInputType.text,
                  validator: ( item){
                    return item!.length>3?null:"length_must_be_grater_then_5_latter".tr;
                  },
                  controller: _lNameController,
                  decoration: ThemeHelper().textInputDecoration('last_name'.tr),
                ),
              ),
              const SizedBox(height: 10),
              ITextFields.labelText(labelText: "email".tr),
              Container(
                decoration: ThemeHelper().inputBoxDecorationShaddow(),
                child: TextFormField(
                  keyboardType: TextInputType.emailAddress,
                  validator: (val) {
                    if((val!.isNotEmpty) && !RegExp(r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?)*$").hasMatch(val)){
                      return "enter_a_valid_email_address".tr;
                    }
                    return null;
                  },
                  controller: _emailController,
                  decoration: ThemeHelper().textInputDecoration( 'email'.tr),
                ),

              ),
              const SizedBox(height: 10),
              ITextFields.labelText(labelText: "dob".tr),
              const SizedBox(height: 10),
              Container(
                decoration: ThemeHelper().inputBoxDecorationShaddow(),
                child:
                TextFormField(
                    readOnly: true,
                    onTap: (){
                      _selectDate(context);
                    },
                    validator: null,
                    controller: _dobController,
                    decoration: InputDecoration(
                      hintText: "dob".tr,
                      fillColor: Colors.white,
                      filled: true,
                      contentPadding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0), borderSide: const BorderSide(color: Colors.grey)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0), borderSide: BorderSide(color: Colors.grey.shade400)),
                      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0), borderSide: const BorderSide(color: Colors.red, width: 2.0)),
                      focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0), borderSide:const BorderSide(color: Colors.red, width: 2.0)),
                    )
                ),),
              const SizedBox(height: 10),
              ITextFields.labelText(labelText: "gender".tr),
              const SizedBox(height: 10),
              InputDecorator(
                decoration:  ThemeHelper().textInputDecoration('select_gender*'.tr),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    padding: EdgeInsets.zero,
                    value: selectedGender,
                    hint:  Text('select_gender'.tr,
                        style:const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500
                        )),
                    items: <String>['Male', 'Female', 'Other']
                        .map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value.tr),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedGender = newValue;
                      });
                    },
                    isExpanded: true,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const  EdgeInsets.only(right: 15,left: 15),
          child: SmallButtonsWidget(title: "update".tr, onPressed: (){
            handleUpdateProfile();
          },),
        )
      ],
    );
  }
  _openDialogBox(){
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        // return object of type Dialog
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          title:   Text("delete_profile".tr,
          textAlign:  TextAlign.center,
          style:const  TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18
          ),),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
                Text("delete_profile_desc".tr,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontWeight: FontWeight.w400,
                      fontSize: 12
                  )),
              const SizedBox(height: 10),
              Container(decoration:
              const   BoxDecoration(
                  border: Border(
                    left: BorderSide(width: 5.0, color: ColorResources.redColor),
                  ),
                ),

                child:  ListTile(
                  isThreeLine: true,
                  leading: const Icon(Icons.warning,
                  color: ColorResources.redColor,),
                  title:Text("warning".tr,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16
                      )),
                  subtitle: Text("warning_delete_desc".tr,
                      style: TextStyle(
                          fontWeight: FontWeight.w400,
                          fontSize: 12
                      )),
                ),
              )

            ],
          ),
          actions: <Widget>[
             ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorResources.greyBtnColor,
                ),
                child:  Text("cancel".tr,
                    style: const TextStyle(
                      color: Colors.white,
                        fontWeight: FontWeight.w400,
                        fontSize: 12
                    )),
                onPressed: () {
                  Navigator.of(context).pop();
                }),
            ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorResources.redColor,
                ),
                child:  Text("delete_profile".tr,
                style: TextStyle(
                    color: Colors.white,
                  fontWeight: FontWeight.w400,
                  fontSize: 12
                ),),
                onPressed: () {
                  Navigator.of(context).pop();
                  _handleDelete();
                }),
            // usually buttons at the bottom of the dialog
          ],
        );
      },
    );
  }

  void getAndSetData() async {
    setState(() {
      _isLoading = true;
    });

    final res = await UserService.getDataById();

    if (res != null) {
      userModel = res;
      _emailController.text = userModel?.email ?? "";
      _phoneNumberController.text = userModel?.phone ?? "";
      _fNameController.text = userModel?.fName ?? "";
      _lNameController.text = userModel?.lName ?? "";

      if (userModel!.gender != null && userModel!.gender != "") {
        selectedGender = userModel!.gender.toString();
      }

      if (userModel!.dob != null && userModel!.dob != "") {
        _dobController.text = DateTimeHelper.getDataFormat(userModel!.dob!);
        selectedDate = userModel!.dob;
      }

      _scheduleAutoClose();
    }

    setState(() {
      _isLoading = false;
    });
  }

  void handleUpdateProfile() async{
    setState(() {
      _isLoading=true;
    });
    final res=await UserService.updateProfile(
      lName: _lNameController.text,
      fName: _fNameController.text,
      dob: selectedDate??"",
      email: _emailController.text,
      gender: selectedGender??""
    );
    if(res!=null){
      IToastMsg.showMessage("success".tr);
      getAndSetData();
      userController.getData();
    }
    setState(() {
      _isLoading=false;
    });
  }

  void _handleDelete() async {
    setState(() {
      _isLoading=true;
    });
    final res=await UserService.softDelete();
    if(res!=null){
      IToastMsg.showMessage("successfully_deleted".tr);
      SharedPreferences prefs=await SharedPreferences.getInstance();
      prefs.clear();
      IToastMsg.showMessage("logout".tr);
      final NotificationDotController notificationDotController=Get.find(tag: "notification_dot");
      final   UserController userController0=Get.find(tag: "user");
      userController0.getData();
      notificationDotController.setDotStatus(false);
      Get.offAllNamed(RouteHelper.getHomePageRoute());
    }
  setState(() {
  _isLoading=false;
  });
}

  Future<void> _selectDate(BuildContext context) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        selectedDate=DateFormat('yyyy-MM-dd').format(picked);
        _dobController.text = DateTimeHelper.getDataFormat(selectedDate);
      });
    }
  }
}
