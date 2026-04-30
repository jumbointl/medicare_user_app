import 'dart:io';
import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';
import '../controller/vital_controller.dart';
import '../helpers/date_time_helper.dart';
import '../model/chart_data_model.dart';
import '../model/family_members_model.dart';
import '../model/vital_model.dart';
import '../services/family_members_service.dart';
import '../services/vitals_service.dart';
import '../utilities/app_constans.dart';
import '../widget/app_bar_widget.dart';
import '../widget/bottom_button.dart';
import '../widget/input_label_widget.dart';
import '../widget/loading_Indicator_widget.dart';
import '../helpers/theme_helper.dart';
import '../helpers/vital_helper.dart';
import '../utilities/colors_constant.dart';
import '../widget/button_widget.dart';
import '../widget/error_widget.dart';
import '../widget/line_chart.dart';
import '../widget/no_data_widgets.dart';
import '../widget/toast_message.dart';

class VitalsDetailsPage extends StatefulWidget {
  final String? vitalName;

   const VitalsDetailsPage({super.key,this.vitalName});

  @override
  State<VitalsDetailsPage> createState() => _VitalsDetailsPageState();
}

class _VitalsDetailsPageState extends State<VitalsDetailsPage> {
  DateRangePickerSelectionChangedArgs? argsDate;
  bool _isLoading = false;
  List<FamilyMembersModel> familyMembers = [];
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _fNameController = TextEditingController();
  final TextEditingController _lNameController = TextEditingController();
  final TextEditingController _bpSystolicController = TextEditingController();
  final TextEditingController _bpDiastolicController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _spo2Controller = TextEditingController();
  final TextEditingController _tempController = TextEditingController();
  final TextEditingController _sugarRandomController = TextEditingController();
  final TextEditingController _sugarFastingController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();

  ScrollController scrollController = ScrollController();
  FamilyMembersModel? selectedFamilyMemberModel;
  int? selectedFamilyMemberId;
  VitalController vitalController = Get.put(VitalController());
  String? selectedVital;
  final _listVitals = VitalHelper.listVitals;
  List<ChartData> chartData = [];
  String selectedDate = "";
  String selectedTime = "";
  String startDate="";
  String endDate="";
  String phoneCode="+";

  @override
  void initState() {
    phoneCode=AppConstants.defaultCountyCode;
    // TODO: implement initState
    selectedVital = widget.vitalName;
    selectedDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
    TimeOfDay timeOfDay = TimeOfDay.now(); // Initialize with current time
    int hour = timeOfDay.hour; // Get the hour
    int minute = timeOfDay.minute;
    selectedTime = "$hour:$minute";
    _timeController.text = DateFormat('hh:mm a').format(DateTime.now());
    _dateController.text = DateTimeHelper.getDataFormat(selectedDate);
    getAndSetData();
    super.initState();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
        floatingActionButton: FloatingActionButton(
            heroTag: "vitals_add_fab",
            shape: const CircleBorder(),
            backgroundColor: ColorResources.btnColor,
            child: const Icon(Icons.add,
              color: Colors.white,
            ),
            onPressed: () {
              if(selectedFamilyMemberModel==null){
                _openBottomSheetAddPatient();
                return;
              }
              clearVitalsInput();
              switch (selectedVital) {
                case "Blood Pressure":
                  _openBottomSheetAddBP(null);
                  break;
                case "Sugar":
                  _openBottomSheetSugar(null);
                  break;
                case "Weight":
                  _openBottomSheetWeight(null);
                  break;
                case "Temperature":
                  _openBottomSheetTemp(null);
                  break;
                case "SpO2":
                  _openBottomSheetSpo2(null);
                  break;
              }
            }),
        bottomNavigationBar: IBottomNavBarWidget(title: "family_members".tr,
          onPressed: () {
            _openBottomSheetFamilyMember();
          },
        ),
        appBar: IAppBar.commonAppBar(
            title: "$selectedVital ${getParameter(selectedVital)}".tr),
        body: _isLoading ? const ILoadingIndicatorWidget() :
        ListView(
          padding: const EdgeInsets.all(8),
          children: [
            selectedFamilyMemberModel == null ? Container() : Padding(
              padding: const EdgeInsets.only(bottom: 10.0),
              child: Card(
                  color: ColorResources.cardBgColor,
                  elevation: .1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5.0),
                  ),
                  child: ListTile(
                      trailing: IconButton(onPressed: (){
                        _openBottomSheetFamilyMember();
                      }, icon:const  Icon(
                        Icons.arrow_drop_down,
                      size: 30,
                      color: ColorResources.primaryColor,
                      )),
                      title: Text("member_name_value".trParams({"value":"${selectedFamilyMemberModel?.fName ??
                        ""} ${selectedFamilyMemberModel?.lName ?? ""}"}),
                    style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 15
                    ),
                  ))),
            ),
            Card(
                color: ColorResources.cardBgColor,
                elevation: .1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5.0),
                ),
                child: ListTile(
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(onPressed: () {
                          _openSelectSheet();
                        }, icon: const Icon(Icons.date_range,
                          color: ColorResources.btnColor,
                          size: 20,
                        )),
                        IconButton(onPressed: () {
                          argsDate=null;
                          startDate="";
                          endDate="";
                          vitalController.getData(
                              selectedFamilyMemberModel?.id.toString() ?? "",
                              selectedVital ?? "","","");
                          setState(() {
                            
                          });
                        }, icon: const Icon(Icons.clear,
                          color: ColorResources.btnColor,
                          size: 20,
                        ))
                      ],
                    ),
                    title:startDate!=""&&endDate!=""?
                    Text("date_range".trArgs([DateTimeHelper.getDataFormat(startDate), DateTimeHelper.getDataFormat(endDate)]),
                      style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 15
                      ),
                    )
                    :Text("date_value".trParams({"value":" $startDate $endDate"}),
                      style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 15
                      ),
                    ))),
            const SizedBox(height: 10),
            InputDecorator(
              decoration: ThemeHelper().textInputDecoration('select_vital*'.tr),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  padding: EdgeInsets.zero,
                  value: selectedVital,
                  hint:  Text('select_vital'.tr,
                      style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500
                      )),
                  items: _listVitals
                      .map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedVital = newValue;
                    });
                    vitalController.getData(
                        selectedFamilyMemberModel?.id.toString() ?? "",
                        selectedVital ?? "",startDate,endDate);
                  },
                  isExpanded: true,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Obx(() {
              return vitalController.dataList.isNotEmpty ?
              selectedVital == "Blood Pressure" ?
              Column(
                children: [
                   Text("bp_systolic".tr,
                    style:const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500
                    ),
                  ),
                  getDataChart(vitalController.dataList, false),
                  const Divider(),
                   Text("bp_diastolic".tr,
                    style:const  TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500
                    ),
                  ),
                  getDataChart(vitalController.dataList, true)
                ],
              ) :
              selectedVital == "Sugar" ?
              Column(
                children: [
                   Text("random".tr,
                    style:const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500
                    ),
                  ),
                  getDataChart(vitalController.dataList, false),
                  const Divider(),
                   Text("fasting".tr,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500
                    ),
                  ),
                  getDataChart(vitalController.dataList, true)
                ],
              )
                  : getDataChart(vitalController.dataList, false) : Container();
            }
            ),
            _buildBody(),
          ],
        )

    );
  }

  _buildBody() {
    return Obx(() {
      if (!vitalController.isError.value) { // if no any error
        if (vitalController.isLoading.value) {
          return const IVerticalListLongLoadingWidget();
        } else if (vitalController.dataList.isEmpty) {
          return const NoDataWidget();
        }
        else {
          return _buildList(vitalController.dataList);
        }
      } else {
        return const IErrorWidget();
      } //Error svg
    }
    );
  }

  _buildList(dataList) {
    return
      ListView.builder(
          controller: scrollController,
          itemCount: dataList.length,
          shrinkWrap: true,
          itemBuilder: (context, index) {
            VitalModel vitalModel = dataList[index];
            return Card(
              color: ColorResources.cardBgColor,
              elevation: .1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5.0),
              ),
              child: ListTile(
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(onPressed: () {
                      clearVitalsInput();
                      switch (selectedVital) {
                        case "Blood Pressure":
                          _openBottomSheetAddBP(vitalModel);
                          break;
                        case "Sugar":
                          _openBottomSheetSugar(vitalModel);
                          break;
                        case "Weight":
                          _openBottomSheetWeight(vitalModel);
                          break;
                        case "Temperature":
                          _openBottomSheetTemp(vitalModel);
                          break;
                        case "SpO2":
                          _openBottomSheetSpo2(vitalModel);
                          break;
                      }
                    },
                        icon: const Icon(Icons.edit,
                          color: ColorResources.btnColor,
                          size: 20,
                        )),
                    IconButton(onPressed: () {
                      _openDialogBox(vitalModel);
                    },
                        icon: const Icon(Icons.delete,
                          color: Colors.redAccent,
                          size: 20,
                        ))
                  ],
                ),
                title: _buildTitle(selectedVital ?? "", vitalModel),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 5.0),
                  child: Text("${DateTimeHelper.getDataFormat(
                      vitalModel.date)} ${DateTimeHelper.convertTo12HourFormat(
                      vitalModel.time ?? "")}",
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400
                    ),
                  ),
                ),
              ),
            );
          });
  }

  _openBottomSheetFamilyMember() {
    return
      showModalBottomSheet(
        backgroundColor: ColorResources.bgColor,

        isScrollControlled: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
        ),
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(
              builder: (BuildContext context, setState) {
                return Container(
                    height: MediaQuery
                        .of(context)
                        .size
                        .height * 0.9,
                    decoration: const BoxDecoration(
                      color: ColorResources.bgColor,
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(20.0),
                        topLeft: Radius.circular(20.0),
                      ),
                    ),
                    //  height: 260.0,
                    child: Stack(
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
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600
                                  ),),
                                GestureDetector(
                                  onTap: () {
                                    Get.back();
                                    _openBottomSheetAddPatient();
                                  },
                                  child: Card(
                                    color: ColorResources.btnColor,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(5.0),
                                    ),
                                    child:  Padding(
                                      padding:const EdgeInsets.all(8.0),
                                      child: Text("add_new".tr,
                                          style:const  TextStyle(
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
                                    itemCount: familyMembers.length,
                                    itemBuilder: (context, index) {
                                      FamilyMembersModel familyModel = familyMembers[index];
                                      return Card(
                                          color: ColorResources.cardBgColor,
                                          elevation: .1,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                                5.0),
                                          ),
                                          child: ListTile(
                                            onTap: () {
                                              selectedFamilyMemberModel =
                                                  familyModel;
                                              vitalController.getData(
                                                  selectedFamilyMemberModel?.id
                                                      .toString() ?? "",
                                                  selectedVital ?? "",startDate,endDate);

                                              this.setState(() {});
                                              Get.back();
                                            },
                                            trailing: familyModel.id ==
                                                selectedFamilyMemberModel?.id ?
                                            const Icon(Icons.circle,
                                              color: Colors.green,
                                              size: 10,
                                            ) : null,
                                            leading: const Icon(Icons.person),
                                            title: Text("full_name".trArgs([familyModel.fName??"", familyModel.lName??""]),
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w500,
                                                  fontSize: 15
                                              ),
                                            ),
                                            subtitle: Text(
                                              "${familyModel.phone}",
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w400,
                                                  fontSize: 13
                                              ),
                                            ),
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

  void getAndSetData() async {
    setState(() {
      _isLoading = true;
    });
    final res = await FamilyMembersService.getData();
    if (res != null) {
      familyMembers = res;
      if (familyMembers.isNotEmpty) {
        selectedFamilyMemberModel = res[0];
        vitalController.getData(selectedFamilyMemberModel?.id.toString() ?? "",
            selectedVital ?? "",startDate,endDate);
      }
    }
    setState(() {
      _isLoading = false;
    });
  }

  _openBottomSheetAddPatient() {
    return
      showModalBottomSheet(
        backgroundColor: ColorResources.bgColor,
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
                           Text("register_new_family_member".tr,
                            style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 15
                            ),),
                          const SizedBox(height: 20),
                          Container(
                            decoration: ThemeHelper()
                                .inputBoxDecorationShaddow(),
                            child: TextFormField(
                              keyboardType: TextInputType.name,
                              validator: (item) {
                                return item!.length >=2
                                    ? null
                                    : "enter_first_name".tr;
                              },
                              controller: _fNameController,
                              decoration: ThemeHelper().textInputDecoration(
                                  'first_name_label'.tr),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            decoration: ThemeHelper()
                                .inputBoxDecorationShaddow(),
                            child: TextFormField(
                              keyboardType: TextInputType.name,
                              validator: (item) {
                                return item!.length >=2
                                    ? null
                                    : "enter_last_name".tr;
                              },
                              controller: _lNameController,
                              decoration: ThemeHelper().textInputDecoration(
                                  'last_name_label'.tr),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            decoration: ThemeHelper()
                                .inputBoxDecorationShaddow(),
                            child:
                            TextFormField(
                                inputFormatters: <TextInputFormatter>[
                                  FilteringTextInputFormatter.allow(
                                      RegExp(r'[0-9]')),
                                ],
                                keyboardType: Platform.isIOS
                                    ? const TextInputType.numberWithOptions(
                                    decimal: true, signed: true)
                                    : TextInputType.number,
                                validator: (item) {
                                  return item!.length > 5
                                      ? null
                                      : "enter_valid_number".tr;
                                },
                                controller: _mobileController,
                                decoration: InputDecoration(
                                  prefixIcon: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const SizedBox(width: 9),
                                      GestureDetector(child: Padding(
                                        padding: const EdgeInsets.only(
                                            right: 8.0),
                                        child: Text(phoneCode,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.black
                                          ),),

                                      ),
                                        onTap: () {
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
                                  contentPadding: const EdgeInsets.fromLTRB(
                                      20, 10, 20, 10),
                                  focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10.0),
                                      borderSide: const BorderSide(
                                          color: Colors.grey)),
                                  enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10.0),
                                      borderSide: BorderSide(
                                          color: Colors.grey.shade400)),
                                  errorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10.0),
                                      borderSide: const BorderSide(
                                          color: Colors.red, width: 2.0)),
                                  focusedErrorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10.0),
                                      borderSide: const BorderSide(
                                          color: Colors.red, width: 2.0)),
                                )
                            ),
                          ),
                          const SizedBox(height: 20),
                          SmallButtonsWidget(title: "save".tr, onPressed: () {
                            if (_formKey.currentState!.validate()) {
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
      selectedFamilyMemberId = res['id'];
      IToastMsg.showMessage("success".tr);
      clearInitData();
      getFamilyMemberListList();
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void handleAddVital() async {
    setState(() {
      _isLoading = true;
    });

    final res = await VitalsService.addData(
        diastolic: _bpDiastolicController.text,
        familyMemberId: selectedFamilyMemberModel?.id.toString(),
        systolic: _bpSystolicController.text,
        type: selectedVital,
        temperature: _tempController.text,
        spo2: _spo2Controller.text,
        sugarFasting: _sugarFastingController.text,
        sugarRandom: _sugarRandomController.text,
        weight: _weightController.text,
        date: selectedDate,
        time: selectedTime
    );
    if (res != null) {
      IToastMsg.showMessage("success".tr);
      clearVitalsInput();
      vitalController.getData(
          selectedFamilyMemberModel?.id.toString() ?? "", selectedVital ?? "",startDate,endDate);
    }

    setState(() {
      _isLoading = false;
    });
  }

  void handleUpdateVital(id) async {
    setState(() {
      _isLoading = true;
    });

    final res = await VitalsService.updateData(
        id: id,
        diastolic: _bpDiastolicController.text,
        familyMemberId: selectedFamilyMemberModel?.id.toString(),
        systolic: _bpSystolicController.text,
        type: selectedVital,
        temperature: _tempController.text,
        spo2: _spo2Controller.text,
        sugarFasting: _sugarFastingController.text,
        sugarRandom: _sugarRandomController.text,
        weight: _weightController.text,
        date: selectedDate,
        time: selectedTime
    );
    if (res != null) {
      IToastMsg.showMessage("success".tr);
      clearVitalsInput();
      vitalController.getData(
          selectedFamilyMemberModel?.id.toString() ?? "", selectedVital ?? "",startDate,endDate);
    }

    setState(() {
      _isLoading = false;
    });
  }

  void handleDeleteVital(String id) async {
    setState(() {
      _isLoading = true;
    });

    final res = await VitalsService.deleteData(
        id: id
    );
    if (res != null) {
      IToastMsg.showMessage("success".tr);
      clearVitalsInput();
      vitalController.getData(
          selectedFamilyMemberModel?.id.toString() ?? "", selectedVital ?? "",startDate,endDate);
    }

    setState(() {
      _isLoading = false;
    });
  }

  void clearInitData() {
    _fNameController.clear();
    _lNameController.clear();
    _mobileController.clear();
    selectedFamilyMemberModel = null;
  }

  clearVitalsInput() {
    _bpSystolicController.clear();
    _bpDiastolicController.clear();
    _weightController.clear();
    _spo2Controller.clear();
    _tempController.clear();
    _sugarRandomController.clear();
    _sugarFastingController.clear();
  }

  getFamilyMemberListList() async {
    setState(() {
      _isLoading = true;
    });
    final familyList = await FamilyMembersService.getData();
    if (familyList != null && familyList.isNotEmpty) {
      familyMembers = familyList;
      if (selectedFamilyMemberId != null) {
        for (var e in familyMembers) {
          if (e.id == selectedFamilyMemberId) {
            selectedFamilyMemberModel = e;
            vitalController.getData(
                selectedFamilyMemberModel?.id.toString() ?? "",
                selectedVital ?? "",startDate,endDate);
            break;
          }
        }
      }
    }
    setState(() {
      _isLoading = false;
    });
  }

  Widget _buildTitle(String vitalName, var vitalModel) {
    switch (vitalName) {
      case "Blood Pressure":
        return _buildTitleBP(vitalModel);
      case "Sugar":
        return _buildTitleSugar(vitalModel);
      case "Weight":
        return _buildTitleWeight(vitalModel);
      case "Temperature":
        return _buildTitleTemp(vitalModel);
      case "SpO2":
        return _buildTitleSpo2(vitalModel);
      default:
        return Container(); // or any other fallback widget
    }
  }

  _buildTitleBP(VitalModel vitalModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("bp_systolic_value".trParams({"value":vitalModel.bpSystolic.toString()}),
          style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500
          ),),
        const SizedBox(height: 5),
        Text("bp_diastolic_value".trParams({"value":vitalModel.bpDiastolic.toString()}),
          style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500
          ),),
      ],
    );
  }

  _buildTitleSugar(VitalModel vitalModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        vitalModel.sugarRandom == null ? Container() : Text(
          "sugar_random_value".trParams({"value":vitalModel.sugarRandom.toString()}),
          style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500
          ),),
        vitalModel.sugarRandom != null && vitalModel.sugarRandom != null
            ? const SizedBox(height: 5)
            : Container(),
        vitalModel.sugarFasting == null ? Container() : Text(
          "sugar_fasting_value".trParams({"value":vitalModel.sugarFasting.toString()}),
          style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500
          ),),
      ],
    );
  }

  _buildTitleWeight(VitalModel vitalModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("weight_value".trParams({"value":vitalModel.weight.toString()}),
          style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500
          ),),
      ],
    );
  }

  _buildTitleTemp(VitalModel vitalModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("temp_value".trParams({"value":vitalModel.temperature.toString()}),
          style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500
          ),),
      ],
    );
  }

  _buildTitleSpo2(VitalModel vitalModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("spO2_value".trParams({"value":vitalModel.spo2.toString()}),
          style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500
          ),),
      ],
    );
  }

  _openBottomSheetAddBP(VitalModel? vitalModel) {
    selectedDate =
        vitalModel?.date ?? DateFormat('yyyy-MM-dd').format(DateTime.now());
    TimeOfDay timeOfDay = TimeOfDay.now(); // Initialize with current time
    int hour = timeOfDay.hour; // Get the hour
    int minute = timeOfDay.minute;
    selectedTime = vitalModel?.time ?? ("$hour:$minute");
    _timeController.text = DateFormat('hh:mm a').format(DateTime.now());
    _dateController.text = DateTimeHelper.getDataFormat(selectedDate);
    _bpSystolicController.text = vitalModel?.bpSystolic.toString() ?? "";
    _bpDiastolicController.text = vitalModel?.bpDiastolic.toString() ?? "";
    return
      showModalBottomSheet(
        backgroundColor: ColorResources.bgColor,
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                           Text("add_blood_pressure".tr,
                            style:const TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 15
                            ),),
                          const SizedBox(height: 20),
                          Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: InputLabel.buildLabelBox("date".tr),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            decoration: ThemeHelper()
                                .inputBoxDecorationShaddow(),
                            child:
                            TextFormField(
                              readOnly: true,
                              onTap: () {
                                _selectDate(context);
                              },
                              validator: null,
                              controller: _dateController,
                              decoration: ThemeHelper().textInputDecoration(
                                  'date'.tr),
                            ),),
                          const SizedBox(height: 10),
                          Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: InputLabel.buildLabelBox("time".tr),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            decoration: ThemeHelper()
                                .inputBoxDecorationShaddow(),
                            child:
                            TextFormField(
                              readOnly: true,
                              onTap: () {
                                _selectTime(context);
                              },
                              validator: null,
                              controller: _timeController,
                              decoration: ThemeHelper().textInputDecoration(
                                  'time'.tr),
                            ),),
                          const SizedBox(height: 10),
                          Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: InputLabel.buildLabelBox("systolic_(mmHg)".tr),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            decoration: ThemeHelper()
                                .inputBoxDecorationShaddow(),
                            child: TextFormField(
                              inputFormatters: <TextInputFormatter>[
                                FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d+\.?\d{0,2}$')),
                              ],
                              keyboardType: Platform.isIOS ? const TextInputType
                                  .numberWithOptions(
                                  decimal: true, signed: true)
                                  : TextInputType.number,
                              validator: (item) {
                                return item!.isNotEmpty ? null : "enter_value".tr;
                              },
                              controller: _bpSystolicController,
                              decoration: ThemeHelper().textInputDecoration(
                                  '120'),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: InputLabel.buildLabelBox("diastolic_(mmHg)".tr),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            decoration: ThemeHelper()
                                .inputBoxDecorationShaddow(),
                            child: TextFormField(
                              keyboardType: TextInputType.name,
                              validator: (item) {
                                return item!.isNotEmpty ? null : "enter_value".tr;
                              },
                              controller: _bpDiastolicController,
                              decoration: ThemeHelper().textInputDecoration(
                                  '80'),
                            ),
                          ),

                          const SizedBox(height: 20),
                          SmallButtonsWidget(title: "save".tr, onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              Get.back();
                              if (vitalModel == null) {
                                handleAddVital();
                              }
                              else {
                                handleUpdateVital(vitalModel.id.toString());
                              }
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

  _openBottomSheetWeight(VitalModel? vitalModel) {
    selectedDate =
        vitalModel?.date ?? DateFormat('yyyy-MM-dd').format(DateTime.now());
    TimeOfDay timeOfDay = TimeOfDay.now(); // Initialize with current time
    int hour = timeOfDay.hour; // Get the hour
    int minute = timeOfDay.minute;
    selectedTime = vitalModel?.time ?? ("$hour:$minute");
    _timeController.text = DateFormat('hh:mm a').format(DateTime.now());
    _dateController.text = DateTimeHelper.getDataFormat(selectedDate);
    _weightController.text = vitalModel?.weight.toString() ?? "0";
    return
      showModalBottomSheet(
        backgroundColor: ColorResources.bgColor,
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                           Text("add_weight".tr,
                            style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 15
                            ),),
                          const SizedBox(height: 20),
                          Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: InputLabel.buildLabelBox("date".tr),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            decoration: ThemeHelper()
                                .inputBoxDecorationShaddow(),
                            child:
                            TextFormField(
                              readOnly: true,
                              onTap: () {
                                _selectDate(context);
                              },
                              validator: null,
                              controller: _dateController,
                              decoration: ThemeHelper().textInputDecoration(
                                  'date'.tr),
                            ),),
                          const SizedBox(height: 10),
                          Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: InputLabel.buildLabelBox("time".tr),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            decoration: ThemeHelper()
                                .inputBoxDecorationShaddow(),
                            child:
                            TextFormField(
                              readOnly: true,
                              onTap: () {
                                _selectTime(context);
                              },
                              validator: null,
                              controller: _timeController,
                              decoration: ThemeHelper().textInputDecoration(
                                  'time'.tr),
                            ),),
                          const SizedBox(height: 10),
                          Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: InputLabel.buildLabelBox("weight_(KG)".tr),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            decoration: ThemeHelper()
                                .inputBoxDecorationShaddow(),
                            child: TextFormField(
                              inputFormatters: <TextInputFormatter>[
                                FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d+\.?\d{0,2}$')),
                              ],
                              keyboardType: Platform.isIOS ? const TextInputType
                                  .numberWithOptions(
                                  decimal: true, signed: true)
                                  : TextInputType.number,
                              validator: (item) {
                                return item!.isNotEmpty ? null : "enter_value".tr;
                              },
                              controller: _weightController,
                              decoration: ThemeHelper().textInputDecoration(
                                  '60'),
                            ),
                          ),
                          const SizedBox(height: 20),
                          SmallButtonsWidget(title: "save".tr, onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              Get.back();
                              if (vitalModel == null) {
                                handleAddVital();
                              }
                              else {
                                handleUpdateVital(vitalModel.id.toString());
                              }
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

  _openBottomSheetTemp(VitalModel? vitalModel) {
    selectedDate =
        vitalModel?.date ?? DateFormat('yyyy-MM-dd').format(DateTime.now());
    TimeOfDay timeOfDay = TimeOfDay.now(); // Initialize with current time
    int hour = timeOfDay.hour; // Get the hour
    int minute = timeOfDay.minute;
    selectedTime = vitalModel?.time ?? ("$hour:$minute");
    _timeController.text = DateFormat('hh:mm a').format(DateTime.now());
    _dateController.text = DateTimeHelper.getDataFormat(selectedDate);
    _tempController.text = vitalModel?.temperature.toString() ?? "0";
    return
      showModalBottomSheet(
        backgroundColor: ColorResources.bgColor,
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                           Text("add_temperature".tr,
                            style:const TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 15
                            ),),
                          const SizedBox(height: 20),
                          Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: InputLabel.buildLabelBox("date".tr),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            decoration: ThemeHelper()
                                .inputBoxDecorationShaddow(),
                            child:
                            TextFormField(
                              readOnly: true,
                              onTap: () {
                                _selectDate(context);
                              },
                              validator: null,
                              controller: _dateController,
                              decoration: ThemeHelper().textInputDecoration(
                                  'date'.tr),
                            ),),
                          const SizedBox(height: 10),
                          Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: InputLabel.buildLabelBox("time".tr),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            decoration: ThemeHelper()
                                .inputBoxDecorationShaddow(),
                            child:
                            TextFormField(
                              readOnly: true,
                              onTap: () {
                                _selectTime(context);
                              },
                              validator: null,
                              controller: _timeController,
                              decoration: ThemeHelper().textInputDecoration(
                                  'time'.tr),
                            ),),
                          const SizedBox(height: 10),
                          Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: InputLabel.buildLabelBox("temp_(F)".tr),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            decoration: ThemeHelper()
                                .inputBoxDecorationShaddow(),
                            child: TextFormField(
                              inputFormatters: <TextInputFormatter>[
                                FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d+\.?\d{0,2}$')),
                              ],
                              keyboardType: Platform.isIOS ? const TextInputType
                                  .numberWithOptions(
                                  decimal: true, signed: true)
                                  : TextInputType.number,
                              validator: (item) {
                                return item!.isNotEmpty ? null : "enter_value".tr;
                              },
                              controller: _tempController,
                              decoration: ThemeHelper().textInputDecoration(
                                  '97'),
                            ),
                          ),
                          const SizedBox(height: 20),
                          SmallButtonsWidget(title: "save".tr, onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              Get.back();
                              if (vitalModel == null) {
                                handleAddVital();
                              }
                              else {
                                handleUpdateVital(vitalModel.id.toString());
                              }
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

  _openBottomSheetSpo2(VitalModel? vitalModel) {
    selectedDate =
        vitalModel?.date ?? DateFormat('yyyy-MM-dd').format(DateTime.now());
    TimeOfDay timeOfDay = TimeOfDay.now(); // Initialize with current time
    int hour = timeOfDay.hour; // Get the hour
    int minute = timeOfDay.minute;
    selectedTime = vitalModel?.time ?? ("$hour:$minute");
    _timeController.text = DateFormat('hh:mm a').format(DateTime.now());
    _dateController.text = DateTimeHelper.getDataFormat(selectedDate);
    _spo2Controller.text = vitalModel?.spo2.toString() ?? "0";
    return
      showModalBottomSheet(
        backgroundColor: ColorResources.bgColor,
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                           Text("add_SpO2".tr,
                            style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 15
                            ),),
                          const SizedBox(height: 20),
                          Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: InputLabel.buildLabelBox("date".tr),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            decoration: ThemeHelper()
                                .inputBoxDecorationShaddow(),
                            child:
                            TextFormField(
                              readOnly: true,
                              onTap: () {
                                _selectDate(context);
                              },
                              validator: null,
                              controller: _dateController,
                              decoration: ThemeHelper().textInputDecoration(
                                  'date'.tr),
                            ),),
                          const SizedBox(height: 10),
                          Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: InputLabel.buildLabelBox("time".tr),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            decoration: ThemeHelper()
                                .inputBoxDecorationShaddow(),
                            child:
                            TextFormField(
                              readOnly: true,
                              onTap: () {
                                _selectTime(context);
                              },
                              validator: null,
                              controller: _timeController,
                              decoration: ThemeHelper().textInputDecoration(
                                  'time'.tr),
                            ),),
                          const SizedBox(height: 10),
                          Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: InputLabel.buildLabelBox("SpO2_(%)".tr),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            decoration: ThemeHelper()
                                .inputBoxDecorationShaddow(),
                            child: TextFormField(
                              inputFormatters: <TextInputFormatter>[
                                FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d+\.?\d{0,2}$')),
                              ],
                              keyboardType: Platform.isIOS ? const TextInputType
                                  .numberWithOptions(
                                  decimal: true, signed: true)
                                  : TextInputType.number,
                              validator: (item) {
                                return item!.isNotEmpty ? null : "enter_value".tr;
                              },
                              controller: _spo2Controller,
                              decoration: ThemeHelper().textInputDecoration(
                                  '98'),
                            ),
                          ),
                          const SizedBox(height: 20),
                          SmallButtonsWidget(title: "save".tr, onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              Get.back();
                              if (vitalModel == null) {
                                handleAddVital();
                              }
                              else {
                                handleUpdateVital(vitalModel.id.toString());
                              }
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

  _openBottomSheetSugar(VitalModel? vitalModel) {
    selectedDate =
        vitalModel?.date ?? DateFormat('yyyy-MM-dd').format(DateTime.now());
    TimeOfDay timeOfDay = TimeOfDay.now(); // Initialize with current time
    int hour = timeOfDay.hour; // Get the hour
    int minute = timeOfDay.minute;
    selectedTime = vitalModel?.time ?? ("$hour:$minute");
    _timeController.text = DateFormat('hh:mm a').format(DateTime.now());
    _dateController.text = DateTimeHelper.getDataFormat(selectedDate);
    _sugarRandomController.text = vitalModel?.sugarRandom.toString() ?? "0";
    _sugarFastingController.text = vitalModel?.sugarFasting.toString() ?? "0";
    return
      showModalBottomSheet(
        backgroundColor: ColorResources.bgColor,
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                           Text("add_sugar".tr,
                            style: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 15
                            ),),
                          const SizedBox(height: 20),
                          Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: InputLabel.buildLabelBox("date".tr),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            decoration: ThemeHelper()
                                .inputBoxDecorationShaddow(),
                            child:
                            TextFormField(
                              readOnly: true,
                              onTap: () {
                                _selectDate(context);
                              },
                              validator: null,
                              controller: _dateController,
                              decoration: ThemeHelper().textInputDecoration(
                                  'date'.tr),
                            ),),
                          const SizedBox(height: 10),
                          Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: InputLabel.buildLabelBox("time".tr),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            decoration: ThemeHelper()
                                .inputBoxDecorationShaddow(),
                            child:
                            TextFormField(
                              readOnly: true,
                              onTap: () {
                                _selectTime(context);
                              },
                              validator: null,
                              controller: _timeController,
                              decoration: ThemeHelper().textInputDecoration(
                                  'time'.tr),
                            ),),
                          const SizedBox(height: 10),
                          Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: InputLabel.buildLabelBox(
                                "sugar_random_(Mg/dl)".tr),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            decoration: ThemeHelper()
                                .inputBoxDecorationShaddow(),
                            child: TextFormField(
                              inputFormatters: <TextInputFormatter>[
                                FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d+\.?\d{0,2}$')),
                              ],
                              keyboardType: Platform.isIOS ? const TextInputType
                                  .numberWithOptions(
                                  decimal: true, signed: true)
                                  : TextInputType.number,
                              validator: (item) {
                                return null;
                              },
                              controller: _sugarRandomController,
                              decoration: ThemeHelper().textInputDecoration(
                                  '120'),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: InputLabel.buildLabelBox(
                                "sugar_fasting_(Mg/dl)".tr),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            decoration: ThemeHelper()
                                .inputBoxDecorationShaddow(),
                            child: TextFormField(
                              inputFormatters: <TextInputFormatter>[
                                FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d+\.?\d{0,2}$')),
                              ],
                              keyboardType: Platform.isIOS ? const TextInputType
                                  .numberWithOptions(
                                  decimal: true, signed: true)
                                  : TextInputType.number,
                              validator: (item) {
                                return null;
                              },
                              controller: _sugarFastingController,
                              decoration: ThemeHelper().textInputDecoration(
                                  '90'),
                            ),
                          ),

                          const SizedBox(height: 20),
                          SmallButtonsWidget(title: "save".tr, onPressed: () {
                            if (_sugarFastingController.text.isEmpty &&
                                _sugarRandomController.text.isEmpty) {
                              IToastMsg.showMessage(
                                  "fill_at_least_desc".tr);
                            } else {
                              Get.back();
                              if (vitalModel == null) {
                                handleAddVital();
                              }
                              else {
                                handleUpdateVital(vitalModel.id.toString());
                              }
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

  getDataChart(List dataList, bool value2) {
    List<ChartData> dataListReturn = [];

    if (selectedVital == "Weight") {
      for (int i = dataList.length; i > 0; i--) {
        VitalModel vitalModel = dataList[i - 1];
        dataListReturn.add(ChartData(
            DateTime.parse(vitalModel.date ?? ""), vitalModel.weight ?? 0),);
      }
    }
    if (selectedVital == "Temperature") {
      for (int i = dataList.length; i > 0; i--) {
        VitalModel vitalModel = dataList[i - 1];
        dataListReturn.add(ChartData(DateTime.parse(vitalModel.date ?? ""),
            vitalModel.temperature ?? 0),);
      }
    }
    if (selectedVital == "SpO2") {
      for (int i = dataList.length; i > 0; i--) {
        VitalModel vitalModel = dataList[i - 1];
        dataListReturn.add(ChartData(
            DateTime.parse(vitalModel.date ?? ""), vitalModel.spo2 ?? 0),);
      }
    }
    if (selectedVital == "Blood Pressure") {
      if (value2) {
        for (int i = dataList.length; i > 0; i--) {
          VitalModel vitalModel = dataList[i - 1];
          dataListReturn.add(ChartData(DateTime.parse(vitalModel.date ?? ""),
              vitalModel.bpDiastolic ?? 0),);
        }
      } else {
        for (int i = dataList.length; i > 0; i--) {
          VitalModel vitalModel = dataList[i - 1];
          dataListReturn.add(ChartData(DateTime.parse(vitalModel.date ?? ""),
              vitalModel.bpSystolic ?? 0),);
        }
      }
    }
    if (selectedVital == "Sugar") {
      if (value2) {
        for (int i = dataList.length; i > 0; i--) {
          VitalModel vitalModel = dataList[i - 1];
          dataListReturn.add(ChartData(DateTime.parse(vitalModel.date ?? ""),
              vitalModel.sugarFasting ?? 0),);
        }
      } else {
        for (int i = dataList.length; i > 0; i--) {
          VitalModel vitalModel = dataList[i - 1];
          dataListReturn.add(ChartData(DateTime.parse(vitalModel.date ?? ""),
              vitalModel.sugarRandom ?? 0),);
        }
      }
    }
    return dataListReturn.isNotEmpty ? LineChartWidget(
        chartData: dataListReturn) : Container();
  }

  Future<void> _selectDate(BuildContext context) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        selectedDate = DateFormat('yyyy-MM-dd').format(picked);
        _dateController.text = DateTimeHelper.getDataFormat(selectedDate);
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    TimeOfDay? picked = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now()
    );
    if (picked != null) {
      setState(() {
        int hour = picked.hour; // Get the hour
        int minute = picked.minute;
        selectedTime = "$hour:$minute";
        final now = DateTime.now();
        DateTime pickedDateTime = DateTime(
            now.year, now.month, now.day, picked.hour, picked.minute);
        _timeController.text = DateFormat('hh:mm a').format(pickedDateTime);
      });
    }
  }

  String getParameter(String? selectedVital) {
    switch (selectedVital) {
      case "Blood Pressure":
        return "(mmHg)";
      case "Sugar":
        return "(Mg/dl)";
      case "Weight":
        return "(KG)";
      case "Temperature":
        return "(F)";
      case "SpO2":
        return "(%)";
      default:
        return "";
    }
  }

  _openDialogBox(vitalModel) {
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
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
               Text("delete_record_desc".tr,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.w400, fontSize: 12)),
              const SizedBox(height: 10),
              _buildTitle(selectedVital ?? "", vitalModel),
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
                    TextStyle(
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
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w400, fontSize: 12),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  handleDeleteVital(vitalModel.id.toString());
                }),
            // usually buttons at the bottom of the dialog
          ],
        );
      },
    );
  }

  _openSelectSheet() {
    argsDate = null;
    return
      showModalBottomSheet(
        isScrollControlled: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
        ),
        context: context,
        builder: (BuildContext context) {
          return Container(
              height: MediaQuery
                  .of(context)
                  .size
                  .height * 0.7,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(20.0),
                  topLeft: Radius.circular(20.0),
                ),
              ),
              //  height: 260.0,
              child: Stack(
                children: [
                  Positioned(
                      top: 10,
                      right: 20,
                      left: 20,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                           Text("select_date".tr,
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600
                            ),),
                          IconButton(
                              onPressed: () {
                                Get.back();
                              }, icon: const Icon(Icons.close)),
                        ],
                      )),
                  Positioned(
                      top: 60,
                      left: 5,
                      right: 5,
                      bottom: 0,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          SfDateRangePicker(
                            maxDate: DateTime.now(),
                           minDate:DateTime(2020),
                            enablePastDates: true,
                            onSelectionChanged: _onSelectionChanged,
                            selectionMode: DateRangePickerSelectionMode.range,
                            showNavigationArrow: true,
                            initialSelectedRange: PickerDateRange(
                                DateTime.now().subtract(const Duration(days: 3)),
                                DateTime.now()),
                          ),
                          const SizedBox(height: 50),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: SmallButtonsWidget(
                                title: "submit".tr, onPressed: () {
                              if (argsDate == null) {
                                IToastMsg.showMessage("select Date");
                              } else if (argsDate != null) {
                                if (argsDate!.value.startDate != null) {
                                  startDate = DateFormat('yyyy-MM-dd').format(
                                      argsDate!.value.startDate);
                                }
                                if (argsDate!.value.endDate != null) {
                                  endDate = DateFormat('yyyy-MM-dd').format(
                                      argsDate!.value.endDate);
                                }
                                Get.back();
                                vitalController.getData(
                                    selectedFamilyMemberModel?.id.toString() ?? "",
                                    selectedVital ?? "",startDate,endDate);
                                // handleAddData(startDate,endDate);
                              }
                              setState(() {

                              });
                            }),
                          )

                        ],
                      )
                  ),
                ],
              )
          );
        },
      ).whenComplete(() {

      });
  }

  void _onSelectionChanged(DateRangePickerSelectionChangedArgs args) {
    argsDate = args;

    setState(() {});
  }
}
