import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../controller/family_members_controller.dart';
import '../helpers/date_time_helper.dart';
import '../model/family_members_model.dart';
import '../services/family_members_service.dart';
import '../utilities/app_constans.dart';
import '../widget/app_bar_widget.dart';
import 'package:get/get.dart';
import '../helpers/theme_helper.dart';
import '../utilities/colors_constant.dart';
import '../widget/button_widget.dart';
import '../widget/loading_Indicator_widget.dart';
import 'package:country_picker/country_picker.dart';
import 'package:intl/intl.dart';
import '../widget/toast_message.dart';

class FamilyMemberListPage extends StatefulWidget {
  const FamilyMemberListPage({super.key});

  @override
  State<FamilyMemberListPage> createState() => _FamilyMemberListPageState();
}

class _FamilyMemberListPageState extends State<FamilyMemberListPage> {
  final FamilyMembersController _familyMembersController=FamilyMembersController();
  final TextEditingController _mobileController=TextEditingController();
  final TextEditingController _fNameController=TextEditingController();
  final TextEditingController _lNameController=TextEditingController();
  final TextEditingController _dobController=TextEditingController();
  bool _isLoading=false;
  String? selectedDate="";
  String? selectedFamilyMemberId="";
  String? selectedGender;
  final _formKey = GlobalKey<FormState>();
  String phoneCode="+";

  @override
  void initState() {
    phoneCode=AppConstants.defaultCountyCode;
    // TODO: implement initState
    _familyMembersController.getData();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        heroTag: "family_member_fab",
        backgroundColor: ColorResources.btnColor,
        onPressed: () {
          // Add your onPressed code here!
          clearData();
          _openBottomSheetAddFamilyMember(true);
        },
        shape:  const CircleBorder(),
        child:  const Icon(Icons.add,
        color: Colors.white,),
      ),
      appBar: IAppBar.commonAppBar(title: "family_members".tr),
      body:_isLoading?const ILoadingIndicatorWidget(): _buildBody(),
    );
  }

  _buildBody() {
    return
      Obx(() {
        if (!_familyMembersController.isError.value&&!_familyMembersController.isError.value) { // if no any error
          if (_familyMembersController.isLoading.value||_familyMembersController.isLoading.value) {
            return const ILoadingIndicatorWidget();
          } else if (_familyMembersController.dataList.isEmpty) {
            return  Padding(
              padding: const EdgeInsets.all(10.0),
              child: Text("no_family_member_found_des".tr,
                style:const  TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.black
                ),),
            );
          }
          else {
            return
              _buildMembersList (_familyMembersController.dataList);
          }
        }else {
          return   Text("something_went_wrong".tr);
        } //Error svg
      }
      );


  }

  _buildMembersList(List dataList){
    return  ListView.builder(
        shrinkWrap: true,
        itemCount: dataList.length,
        itemBuilder: (context,index){
          FamilyMembersModel familyMembersModel=dataList[index];
          return Card(
            color:  ColorResources.cardBgColor,
            elevation: .1,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5.0)),
            child: ListTile(
              onTap: ()async {
                _fNameController.text=familyMembersModel.fName??"";
                _lNameController.text=familyMembersModel.lName??"";
                _mobileController.text=familyMembersModel.phone??"";
                if(familyMembersModel.dob!=null&&familyMembersModel.dob!=""){
                  _dobController.text=DateTimeHelper.getDataFormat(familyMembersModel.dob);
                  selectedDate=familyMembersModel.dob;
                }
                if(familyMembersModel.isdCode!=null&&familyMembersModel.isdCode!=""){
                  phoneCode=familyMembersModel.isdCode!;
                }
                if(familyMembersModel.gender!=null&&familyMembersModel.gender!=""){
                  selectedGender=familyMembersModel.gender.toString();
                }
                selectedFamilyMemberId=familyMembersModel.id?.toString()??"";
                _openBottomSheetAddFamilyMember(false);
              },
              trailing: IconButton(
                icon: const Icon(Icons.delete,
                color: Colors.redAccent,
                size: 20,
                ), onPressed: () {
                _openDialogBox(familyMembersModel);
              },
              ),
              title: Text("full_name".trArgs([familyMembersModel.fName??"", familyMembersModel.lName??""]),
                style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 15
                ),
              ),
              subtitle:  Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      familyMembersModel.gender==null||familyMembersModel.gender==""? Container():  Row(
                        children: [
                       const    Icon(Icons.person,
                            size: 18,
                            color:ColorResources.greyBtnColor,
                          ),
                          const SizedBox(width: 3),
                          Text(familyMembersModel.gender??"--".tr,
                            style: const TextStyle(
                                fontWeight: FontWeight.w400,
                                fontSize: 13
                            ),
                          ),
                        ],
                      ),
                      familyMembersModel.gender==null||familyMembersModel.gender==""? Container():const SizedBox(width: 5),
                      familyMembersModel.dob==null||familyMembersModel.dob==""?Container():  Row(
                        children: [
                          const Icon(Icons.calendar_month,
                          size: 18,
                          color:ColorResources.greyBtnColor,),
                          const SizedBox(width: 3),
                          Text(DateTimeHelper.getDataFormat(familyMembersModel.dob),
                            style: const TextStyle(
                                fontWeight: FontWeight.w400,
                                fontSize: 13
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.phone,
                        size: 18,
                        color:ColorResources.greyBtnColor,),
                      const SizedBox(width: 3),
                      Text("${familyMembersModel.isdCode??"--"}${familyMembersModel.phone??"--"}",
                        style: const TextStyle(
                            fontWeight: FontWeight.w400,
                            fontSize: 13
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        });
  }

  _openBottomSheetAddFamilyMember(bool isForAdding){
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
                            Text(("${isForAdding?"add":"update"}_new_family_member").tr,
                            style:const TextStyle(
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
                                              //  print('Select country: ${country.phoneCode}');
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
                          InputDecorator(
                            decoration:  ThemeHelper().textInputDecoration('select_gender*'.tr),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                padding: EdgeInsets.zero,
                                value: selectedGender,
                                hint:  Text('select_gender'.tr,
                                style: TextStyle(
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
                          const SizedBox(height: 20),
                          SmallButtonsWidget(title: "save".tr, onPressed: (){
                            if(_formKey.currentState!.validate()){
                              Get.back();
                              if(isForAdding){
                                handleAddUserDataData();
                              }
                             else if(!isForAdding) {
                                handleUpdateUserDataData();
                              }
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
  void handleUpdateUserDataData() async{
    setState(() {
      _isLoading=true;
    });

    final res=await FamilyMembersService.updateUser(
      id: selectedFamilyMemberId,
        dob: selectedDate??"",
        gender: selectedGender??"",
        fName: _fNameController.text,
        lName: _lNameController.text,
        isdCode: phoneCode,
        phone: _mobileController.text);
    if(res!=null){
      IToastMsg.showMessage("success".tr);
      _familyMembersController.getData();
      clearData();
      setState(() {
        _isLoading=false;
      });
    }else{
      setState(() {
        _isLoading=false;
      });
    }

  }
  void handleAddUserDataData() async{
    setState(() {
      _isLoading=true;
    });

    final res=await FamilyMembersService.addUser(
      dob: selectedDate??"",
        gender: selectedGender??"",
        fName: _fNameController.text,
        lName: _lNameController.text,
        isdCode: phoneCode,
        phone: _mobileController.text);
    if(res!=null){
      IToastMsg.showMessage("success".tr);
      _familyMembersController.getData();
      clearData();
      setState(() {
        _isLoading=false;
      });
    }else{
      setState(() {
        _isLoading=false;
      });
    }

  }
  void handleDeleteDataData(String id) async{
    setState(() {
      _isLoading=true;
    });

    final res=await FamilyMembersService.deleteData(
        id: id);
    if(res!=null){
      IToastMsg.showMessage("success".tr);
      _familyMembersController.getData();
    }else{
      setState(() {
        _isLoading=false;
      });
    }

  }
  _openDialogBox(FamilyMembersModel familyMembersModel){
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        // return object of type Dialog
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          title:   Text("delete".tr,
            textAlign: TextAlign.center,
            style:const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w600,
                fontSize: 18
            ),),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("sure_delete_fm".trParams({"name":"${familyMembersModel.fName??""} ${familyMembersModel.lName}"}),
                  textAlign: TextAlign.center,
                  style:const  TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w400,
                      fontSize: 12
                  )),
              const SizedBox(height: 10),
            ],
          ),
          actions: <Widget>[
            ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorResources.greyBtnColor,
                ),
                child:  Text("no".tr,
                    style:const  TextStyle(
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
                child:  Text("yes".tr,
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w400,
                      fontSize: 12
                  ),),
                onPressed: () {
                  Navigator.of(context).pop();
                  handleDeleteDataData(familyMembersModel.id.toString());
                }),
            // usually buttons at the bottom of the dialog
          ],
        );
      },
    );
  }

  void clearData() {
    _fNameController.clear();
    _lNameController.clear();
    _dobController.clear();
    _mobileController.clear();
     selectedGender=null;
     selectedDate="";
    selectedFamilyMemberId="";
  }
}
