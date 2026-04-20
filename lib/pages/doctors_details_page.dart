import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:medicare_user_app/helpers/currency_formatter_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:star_rating/star_rating.dart';
import 'package:url_launcher/url_launcher.dart';

import '../bancard/bancard_appointment_payment_provider.dart';
import '../bancard/medicare_client_payment_gateway_page.dart';
import '../controller/boked_time_slot_controller.dart';
import '../controller/time_slots_controller.dart';
import '../helpers/date_time_helper.dart';
import '../helpers/payment_type_helper.dart';
import '../helpers/route_helper.dart';
import '../helpers/theme_helper.dart';
import '../model/booked_time_slot_mdel.dart';
import '../model/doctors_model.dart';
import '../model/doctors_review_model.dart';
import '../model/family_members_model.dart';
import '../model/time_slots_model.dart';
import '../model/user_model.dart';
import '../pages/full_screen_image_viewer_page.dart';
import '../services/appointment_service.dart';
import '../services/coupon_service.dart';
import '../services/doctor_service.dart';
import '../services/family_members_service.dart';
import '../services/payment_gateway_service.dart';
import '../services/user_service.dart';
import '../utilities/api_content.dart';
import '../utilities/app_constans.dart';
import '../utilities/colors_constant.dart';
import '../utilities/image_constants.dart';
import '../utilities/sharedpreference_constants.dart';
import '../widget/app_bar_widget.dart';
import '../widget/button_widget.dart';
import '../widget/image_box_widget.dart';
import '../widget/loading_Indicator_widget.dart';
import '../widget/toast_message.dart';
import 'package:date_picker_timeline/date_picker_timeline.dart';
import 'package:intl/intl.dart';
import 'package:country_picker/country_picker.dart';

class DoctorsDetailsPage extends StatefulWidget {
  final String? doctId;
  const DoctorsDetailsPage({super.key, required this.doctId});

  @override
  State<DoctorsDetailsPage> createState() => _DoctorsDetailsPageState();
}

class _DoctorsDetailsPageState extends State<DoctorsDetailsPage> {
  UserModel? userModel;
  ScrollController scrollController = ScrollController();

  String _selectedDate = "";
  String _setTime = "";
  String _endTime = "";
  String phoneCode = "+";

  DoctorsModel? _doctorsModel;
  String _selectedAppointmentType = "0";

  List<FamilyMembersModel> familyModelList = [];
  FamilyMembersModel? selectedFamilyMemberModel;

  int selectedPaymentTypeId = 1100;

  bool couponEnable = false;
  double appointmentFee = 0;
  double totalAmount = 0;
  double offPrice = 0;
  int? couponId;
  double? couponValue;
  double unitTotalAmount = 0;

  List<DoctorsReviewModel> doctorReviewModel = [];

  final GlobalKey<FormState> _formKey3 = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  String? activePaymentGatewayName;
  String email = "";

  final List _gridData = [
    {
      "title": "OPD",
      "icon": Icons.handshake,
      "id": "1",
    },
    {
      "title": "Video Consultant",
      "icon": Icons.videocam_rounded,
      "id": "2",
    },
    {
      "title": "Emergency",
      "icon": Icons.emergency,
      "id": "3",
    }
  ];

  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _fNameController = TextEditingController();
  final TextEditingController _lNameController = TextEditingController();
  final TextEditingController _couponNameController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  final DateTime _todayDayTime = DateTime.now();
  final TimeSlotsController _timeSlotsController = Get.put(TimeSlotsController());
  final BookedTimeSlotsController _bookedTimeSlotsController =
  Get.put(BookedTimeSlotsController());

  double? clinicVisitFee;
  double? videoFee;
  double? emergencyFee;
  bool stopBooking = false;

  final BancardAppointmentPaymentProvider bancardAppointmentPaymentProvider =
  BancardAppointmentPaymentProvider();

  bool get isPayInClinic => PaymentTypeHelper.isPayInClinic(selectedPaymentTypeId);

  bool get isOnlinePayment => PaymentTypeHelper.isOnlinePayment(selectedPaymentTypeId);

  @override
  void initState() {
    phoneCode = AppConstants.defaultCountyCode;
    getAndSetData();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorResources.bgColor,
      appBar: IAppBar.commonAppBar(title: "book_appointment".tr),
      body: _doctorsModel == null || _isLoading
          ? const ILoadingIndicatorWidget()
          : _buildBody(_doctorsModel!),
    );
  }

  Widget _buildBody(DoctorsModel doctorsModel) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(8),
        children: [
          _buildProfileSection(),
          _buildClinicInfo(),
          _doctorsModel == null ||
              _doctorsModel?.clinicImage == null ||
              _doctorsModel!.clinicImage!.isEmpty
              ? Container()
              : _buildImageClinic(_doctorsModel?.clinicImage ?? []),
          const SizedBox(height: 10),
          _buildFamilyMemberCard(),
          const SizedBox(height: 10),
          ListTile(
            title: Text(
              "appointment".tr,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
          buildOpBtn(doctorsModel),
          _selectedAppointmentType == "0" ? Container() : buildOpDetails(),
          doctorReviewModel.isEmpty ? Container() : _buildRatingReviewBox(),
          const SizedBox(height: 10),
          doctorsModel.desc == null
              ? Container()
              : buildTitleAndDesBox("about".tr, doctorsModel.desc ?? ""),
        ],
      ),
    );
  }

  Widget _buildProfileSection() {
    return Card(
      color: ColorResources.cardBgColor,
      elevation: .1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(5.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Row(
              children: [
                Flexible(
                  flex: 2,
                  child: Stack(
                    children: [
                      _doctorsModel!.image == null || _doctorsModel!.image == ""
                          ? const CircleAvatar(
                        backgroundColor: Colors.white,
                        radius: 30,
                        child: Icon(Icons.person, size: 40),
                      )
                          : ClipOval(
                        child: SizedBox(
                          height: 80,
                          width: 80,
                          child: CircleAvatar(
                            child: ImageBoxFillWidget(
                              imageUrl:
                              "${ApiContents.imageUrl}/${_doctorsModel!.image}",
                              boxFit: BoxFit.fill,
                            ),
                          ),
                        ),
                      ),
                      const Positioned(
                        top: 5,
                        right: 0,
                        child: CircleAvatar(
                          backgroundColor: Colors.white,
                          radius: 8,
                          child: CircleAvatar(
                            backgroundColor: Colors.green,
                            radius: 6,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                Flexible(
                  flex: 6,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${_doctorsModel?.fName ?? "--"} ${_doctorsModel?.lName ?? "--"}",
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        _doctorsModel?.specialization ?? "",
                        style: const TextStyle(
                          color: ColorResources.secondaryFontColor,
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          StarRating(
                            mainAxisAlignment: MainAxisAlignment.center,
                            length: 5,
                            color: _doctorsModel?.averageRating == 0
                                ? Colors.grey
                                : Colors.amber,
                            rating: _doctorsModel?.averageRating ?? 0,
                            between: 5,
                            starSize: 15,
                            onRaitingTap: (rating) {},
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'rating_review_text'.trParams({
                              'rating': '${_doctorsModel?.averageRating ?? "--"}',
                              'count': '${_doctorsModel?.numberOfReview ?? 0}',
                            }),
                            style: const TextStyle(
                              color: ColorResources.secondaryFontColor,
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            FontAwesomeIcons.briefcase,
                            color: ColorResources.iconColor,
                            size: 15,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            "experience_year".trParams({
                              'count': "${_doctorsModel?.exYear ?? "--"}",
                            }),
                            style: const TextStyle(
                              color: ColorResources.secondaryFontColor,
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            FontAwesomeIcons.circleCheck,
                            color: ColorResources.btnColorGreen,
                            size: 15,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'appointments_done'.trParams({
                              'count':
                              '${_doctorsModel?.totalAppointmentDone ?? 0}',
                            }),
                            style: const TextStyle(
                              color: ColorResources.secondaryFontColor,
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      _buildSocialMediaSection(),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget buildTitleAndDesBox(String title, String subTitle) {
    return ListTile(
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      ),
      subtitle: Text(
        subTitle,
        style: const TextStyle(
          color: ColorResources.secondaryFontColor,
          fontWeight: FontWeight.w400,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget buildOpBtn(DoctorsModel doctorsModel) {
    return GridView.builder(
      controller: scrollController,
      padding: const EdgeInsets.all(0),
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1,
        crossAxisSpacing: 5,
        mainAxisSpacing: 20,
      ),
      itemCount: 3,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: getCheckVisibility(doctorsModel, _gridData[index]['id'])
              ? () {
            _selectedAppointmentType = _gridData[index]['id'];
            appointmentFee = getFeeFilter(_gridData[index]['id']);
            amtCalculation();
            _setTime = "";
            _endTime = "";
            setState(() {});
          }
              : null,
          child: Card(
            elevation:
            getCheckVisibility(doctorsModel, _gridData[index]['id']) ? 1 : 0,
            color: _selectedAppointmentType == _gridData[index]['id']
                ? ColorResources.primaryColor
                : ColorResources.cardBgColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    _gridData[index]['icon'],
                    size: 40,
                    color: !getCheckVisibility(doctorsModel, _gridData[index]['id'])
                        ? Colors.grey
                        : _selectedAppointmentType == _gridData[index]['id']
                        ? Colors.white
                        : ColorResources.primaryColor,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _gridData[index]['title'] == "Video Consultant"
                        ? "Video Call".tr
                        : "${_gridData[index]['title']}".tr,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: !getCheckVisibility(
                          doctorsModel, _gridData[index]['id'])
                          ? Colors.grey
                          : _selectedAppointmentType == _gridData[index]['id']
                          ? Colors.white
                          : ColorResources.primaryFontColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  Text(
                    "fee_amt".trParams({
                      "fee": CurrencyFormatterHelper.format(
                        getFeeFilter(_gridData[index]['id']),
                      ),
                    }),
                    style: TextStyle(
                      color: !getCheckVisibility(
                          doctorsModel, _gridData[index]['id'])
                          ? Colors.grey
                          : _selectedAppointmentType == _gridData[index]['id']
                          ? Colors.white
                          : ColorResources.primaryFontColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget buildOpDetails() {
    return Padding(
      padding: const EdgeInsets.only(top: 10.0),
      child: Card(
        color: ColorResources.cardBgColor,
        elevation: .1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.0),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    getAppTypeName(_selectedAppointmentType).tr,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Divider(),
              const SizedBox(height: 10),
              Row(
                children: [
                  _selectedAppointmentType == "3"
                      ? Container()
                      : Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "date".tr,
                          style: const TextStyle(
                            fontWeight: FontWeight.w400,
                            fontSize: 12,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            _timeSlotsController.getData(
                              widget.doctId ?? "",
                              DateTimeHelper.getDayName(
                                _todayDayTime.weekday,
                              ),
                              _selectedAppointmentType,
                            );
                            _bookedTimeSlotsController.getData(
                              widget.doctId ?? "",
                              DateTimeHelper.getYYYMMDDFormatDate(
                                _todayDayTime.toString(),
                              ),
                              getAppTypeName(_selectedAppointmentType),
                            );
                            _openBottomSheet();
                          },
                          child: Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5.0),
                            ),
                            color: ColorResources.cardBgColor,
                            elevation: .1,
                            child: ListTile(
                              title: Text(
                                _selectedDate == ""
                                    ? "--"
                                    : DateTimeHelper.getDataFormat(
                                  _selectedDate,
                                ),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w400,
                                  fontSize: 13,
                                ),
                              ),
                              trailing: Card(
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                  BorderRadius.circular(5.0),
                                ),
                                color: Colors.black,
                                child: const Padding(
                                  padding: EdgeInsets.all(3.0),
                                  child: Icon(
                                    Icons.calendar_month,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _selectedAppointmentType == "3"
                      ? Container()
                      : Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "time".tr,
                          style: const TextStyle(
                            fontWeight: FontWeight.w400,
                            fontSize: 12,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            _timeSlotsController.getData(
                              widget.doctId ?? "",
                              DateTimeHelper.getDayName(
                                _todayDayTime.weekday,
                              ),
                              _selectedAppointmentType,
                            );
                            _bookedTimeSlotsController.getData(
                              widget.doctId ?? "",
                              DateTimeHelper.getYYYMMDDFormatDate(
                                _todayDayTime.toString(),
                              ),
                              getAppTypeName(_selectedAppointmentType),
                            );
                            _openBottomSheet();
                          },
                          child: Card(
                            shape: RoundedRectangleBorder(
                              borderRadius:
                              BorderRadius.circular(5.0),
                            ),
                            color: ColorResources.cardBgColor,
                            elevation: .1,
                            child: ListTile(
                              title: Text(
                                _setTime == ""
                                    ? "--"
                                    : DateTimeHelper.convertTo12HourFormat(
                                  _setTime,
                                ),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w400,
                                  fontSize: 13,
                                ),
                              ),
                              trailing: Card(
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                  BorderRadius.circular(5.0),
                                ),
                                color: Colors.black,
                                child: const Padding(
                                  padding: EdgeInsets.all(3.0),
                                  child: Icon(
                                    Icons.watch_later,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _doctorsModel?.stopBooking == 1 || stopBooking
                  ? Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: Colors.red,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        "not_accepting_appointment".tr,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              )
                  : Container(),
              SmallButtonsWidget(
                title: "book_now".tr,
                onPressed: _doctorsModel?.stopBooking == 1 || stopBooking
                    ? null
                    : () {
                  if (_selectedAppointmentType == "3") {
                    if (selectedFamilyMemberModel != null) {
                      openAppointmentBox();
                    } else {
                      if (familyModelList.isEmpty) {
                        _openBottomSheetAddPatient();
                      } else {
                        _openBottomSheetPatient();
                      }
                    }
                  } else {
                    if (_selectedDate == "" || _setTime == "") {
                      _timeSlotsController.getData(
                        widget.doctId ?? "",
                        DateTimeHelper.getDayName(
                          _todayDayTime.weekday,
                        ),
                        _selectedAppointmentType,
                      );
                      _bookedTimeSlotsController.getData(
                        widget.doctId ?? "",
                        DateTimeHelper.getYYYMMDDFormatDate(
                          _todayDayTime.toString(),
                        ),
                        getAppTypeName(_selectedAppointmentType),
                      );
                      _openBottomSheet();
                      return;
                    } else if (_selectedDate != "" && _setTime != "") {
                      if (selectedFamilyMemberModel != null) {
                        openAppointmentBox();
                      } else {
                        if (familyModelList.isEmpty) {
                          _openBottomSheetAddPatient();
                        } else {
                          _openBottomSheetPatient();
                        }
                      }
                    }
                  }
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  void _openBottomSheetPatient() {
    showModalBottomSheet(
      backgroundColor: ColorResources.bgColor,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
      ),
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, setStateModal) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.9,
              decoration: const BoxDecoration(
                color: ColorResources.bgColor,
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(20.0),
                  topLeft: Radius.circular(20.0),
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: 10,
                    right: 20,
                    left: 20,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "add_select_family_member".tr,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
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
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                "add_new".tr,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
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
                          itemBuilder: (context, index) {
                            FamilyMembersModel familyModel =
                            familyModelList[index];
                            return Card(
                              color: ColorResources.cardBgColor,
                              elevation: .1,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5.0),
                              ),
                              child: ListTile(
                                onTap: () {
                                  selectedFamilyMemberModel = familyModel;
                                  setState(() {});
                                  Get.back();

                                  if (_selectedAppointmentType == "3") {
                                    if (selectedFamilyMemberModel != null) {
                                      openAppointmentBox();
                                    }
                                  } else {
                                    if (_selectedDate == "" || _setTime == "") {
                                      _timeSlotsController.getData(
                                        widget.doctId ?? "",
                                        DateTimeHelper.getDayName(
                                          _todayDayTime.weekday,
                                        ),
                                        _selectedAppointmentType,
                                      );
                                      _bookedTimeSlotsController.getData(
                                        widget.doctId ?? "",
                                        DateTimeHelper.getYYYMMDDFormatDate(
                                          _todayDayTime.toString(),
                                        ),
                                        getAppTypeName(
                                          _selectedAppointmentType,
                                        ),
                                      );
                                      _openBottomSheet();
                                      return;
                                    } else if (_selectedDate != "" &&
                                        _setTime != "") {
                                      if (selectedFamilyMemberModel != null) {
                                        openAppointmentBox();
                                      }
                                    }
                                  }
                                },
                                leading: const Icon(Icons.person),
                                title: Text(
                                  "${familyModel.fName} ${familyModel.lName}",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 15,
                                  ),
                                ),
                                subtitle: Text(
                                  "${familyModel.phone}",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w400,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _openBottomSheet() {
    showModalBottomSheet(
      backgroundColor: ColorResources.bgColor,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
      ),
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, setStateModal) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.9,
              decoration: const BoxDecoration(
                color: ColorResources.bgColor,
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(20.0),
                  topLeft: Radius.circular(20.0),
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: 10,
                    right: 20,
                    left: 20,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "choose_date_and_time".tr,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            Get.back();
                          },
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 60,
                    left: 5,
                    right: 5,
                    bottom: 0,
                    child: ListView(
                      children: [
                        _buildCalendar(setStateModal),
                        const Divider(),
                        Obx(() {
                          if (!_timeSlotsController.isError.value &&
                              !_bookedTimeSlotsController.isError.value) {
                            if (_timeSlotsController.isLoading.value ||
                                _bookedTimeSlotsController.isLoading.value) {
                              return const ILoadingIndicatorWidget();
                            } else if (_timeSlotsController.dataList.isEmpty) {
                              return Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: Text(
                                  "no_available_time_slot".tr,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: Colors.red,
                                  ),
                                ),
                              );
                            } else {
                              return _slotsGridView(
                                setStateModal,
                                _timeSlotsController.dataList,
                                _bookedTimeSlotsController.dataList,
                              );
                            }
                          } else {
                            return Text("something_went_wrong".tr);
                          }
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCalendar(setStateModal) {
    return SizedBox(
      height: 100,
      child: DatePicker(
        DateTime.now(),
        initialSelectedDate: DateTime.parse(_selectedDate),
        selectionColor: ColorResources.primaryColor,
        selectedTextColor: Colors.white,
        daysCount: 7,
        onDateChange: (date) {
          setState(() {
            final dateParse = DateFormat('yyyy-MM-dd').parse(date.toString());
            _selectedDate = DateTimeHelper.getYYYMMDDFormatDate(
              date.toString(),
            );
            _timeSlotsController.getData(
              widget.doctId ?? "",
              DateTimeHelper.getDayName(dateParse.weekday),
              _selectedAppointmentType,
            );
            _bookedTimeSlotsController.getData(
              widget.doctId ?? "",
              _selectedDate,
              getAppTypeName(_selectedAppointmentType),
            );
          });
          setStateModal(() {});
        },
      ),
    );
  }

  Widget _slotsGridView(
      setStateModal,
      List<TimeSlotsModel> timeSlots,
      List<BookedTimeSlotsModel> bookedTimeSlots,
      ) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: timeSlots.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        childAspectRatio: 2 / 1,
        crossAxisCount: 3,
      ),
      itemBuilder: (BuildContext context, int index) {
        return buildTimeSlots(
          timeSlots[index].timeStart ?? "--",
          timeSlots[index].timeEnd ?? "--",
          setStateModal,
          bookedTimeSlots,
        );
      },
    );
  }

  Widget buildTimeSlots(
      String timeStart,
      String timeEnd,
      setStateModal,
      List<BookedTimeSlotsModel> bookedTimeSlots,
      ) {
    return GestureDetector(
      onTap: DateTimeHelper.checkIfTimePassed(timeStart, _selectedDate) ||
          getCheckBookedTimeSlot(timeStart, bookedTimeSlots)
          ? null
          : () {
        _setTime = timeStart;
        _endTime = timeEnd;
        setStateModal(() {});
        setState(() {});
        Get.back();

        if (selectedFamilyMemberModel != null) {
          openAppointmentBox();
        } else {
          if (familyModelList.isEmpty) {
            _openBottomSheetAddPatient();
          } else {
            _openBottomSheetPatient();
          }
        }
      },
      child: Card(
        color: DateTimeHelper.checkIfTimePassed(timeStart, _selectedDate) ||
            getCheckBookedTimeSlot(timeStart, bookedTimeSlots)
            ? Colors.red
            : _setTime == timeStart
            ? ColorResources.primaryColor
            : Colors.green,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(5.0),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Center(
            child: Text(
              "$timeStart - $timeEnd",
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }

  bool getCheckVisibility(DoctorsModel doctorsModel, String appointmentType) {
    switch (appointmentType) {
      case "1":
        return doctorsModel.clinicAppointment == 1;
      case "2":
        return doctorsModel.videoAppointment == 1;
      case "3":
        return doctorsModel.emergencyAppointment == 1;
      default:
        return false;
    }
  }

  Future<void> getAndSetData() async {
    setState(() {
      _isLoading = true;
    });

    _selectedDate = DateTimeHelper.getYYYMMDDFormatDate(
      DateTime.now().toString(),
    );

    final resDoctors = await DoctorsService.getDataById(doctId: widget.doctId);
    if (resDoctors != null) {
      _doctorsModel = resDoctors;

      if (_doctorsModel?.clinicAppointment == 1) {
        _selectedAppointmentType = "1";
      } else if (_doctorsModel?.videoAppointment == 1) {
        _selectedAppointmentType = "2";
      } else if (_doctorsModel?.emergencyAppointment == 1) {
        _selectedAppointmentType = "3";
      }

      final familyMemberList = await FamilyMembersService.getData();
      if (familyMemberList != null && familyMemberList.isNotEmpty) {
        familyModelList = familyMemberList;
      }

      clinicVisitFee = _doctorsModel?.opdFee ?? 0;
      videoFee = _doctorsModel?.videoFee ?? 0;
      emergencyFee = _doctorsModel?.emgFee ?? 0;

      final userRes = await UserService.getDataById();
      if (userRes != null) {
        userModel = userRes;
        email = userRes.email ?? "";
      }

      if (_doctorsModel?.clinicStopBooking == 1) {
        stopBooking = true;
      }
      if (_doctorsModel?.clinicCouponEnable == 1) {
        couponEnable = true;
      }

      appointmentFee = getFeeFilter(_selectedAppointmentType);
      amtCalculation();

      final resDR = await DoctorsService.getDataDoctorsReview(
        doctId: widget.doctId,
      );
      if (resDR != null) {
        doctorReviewModel = resDR;
      }

      final activePG = await PaymentGatewayService.getActivePaymentGateway();
      if (activePG != null) {
        activePaymentGatewayName = activePG.title;
      }

      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> getFamilyMemberListList() async {
    setState(() {
      _isLoading = true;
    });

    final familyList = await FamilyMembersService.getData();
    if (familyList != null && familyList.isNotEmpty) {
      familyModelList = familyList;
      selectedFamilyMemberModel = familyList[0];

      if (_selectedAppointmentType == "3") {
        if (selectedFamilyMemberModel != null) {
          openAppointmentBox();
        }
      } else {
        if (_selectedDate == "" || _setTime == "") {
          _timeSlotsController.getData(
            widget.doctId ?? "",
            DateTimeHelper.getDayName(_todayDayTime.weekday),
            _selectedAppointmentType,
          );
          _bookedTimeSlotsController.getData(
            widget.doctId ?? "",
            DateTimeHelper.getYYYMMDDFormatDate(_todayDayTime.toString()),
            getAppTypeName(_selectedAppointmentType),
          );
          _openBottomSheet();
          return;
        } else if (_selectedDate != "" && _setTime != "") {
          if (selectedFamilyMemberModel != null) {
            openAppointmentBox();
          }
        }
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  String getAppTypeName(String selectedAppointmentTypeId) {
    switch (selectedAppointmentTypeId) {
      case "1":
        return "OPD";
      case "2":
        return "Video Consultant";
      case "3":
        return "Emergency";
      default:
        return "--";
    }
  }

  String getPaymentTypeLabel(int idPaymentType) {
    return PaymentTypeHelper.label(idPaymentType);
  }

  Widget _buildFamilyMemberCard() {
    return Card(
      color: ColorResources.cardBgColor,
      elevation: .1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(5.0),
      ),
      child: ListTile(
        leading: const Icon(Icons.person, size: 20),
        trailing: GestureDetector(
          onTap: () {
            if (familyModelList.isEmpty) {
              _openBottomSheetAddPatient();
            } else {
              _openBottomSheetPatient();
            }
          },
          child: Container(
            height: 25,
            width: 25,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: ColorResources.btnColor,
            ),
            child: const Icon(
              Icons.add,
              size: 15,
              color: Colors.white,
            ),
          ),
        ),
        title: Text(
          "patient".tr,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: selectedFamilyMemberModel == null
            ? null
            : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 3),
            Text(
              "${selectedFamilyMemberModel?.fName ?? "--"} ${selectedFamilyMemberModel?.lName ?? "--"}",
              style: const TextStyle(
                fontWeight: FontWeight.w400,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              selectedFamilyMemberModel?.phone ?? "--",
              style: const TextStyle(
                fontWeight: FontWeight.w400,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openBottomSheetAddPatient() {
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
          builder: (BuildContext context, setStateModal) {
            return Padding(
              padding: MediaQuery.of(context).viewInsets,
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "register_new_member".tr,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        decoration: ThemeHelper().inputBoxDecorationShaddow(),
                        child: TextFormField(
                          keyboardType: TextInputType.name,
                          validator: (item) {
                            return item!.length >= 2
                                ? null
                                : "enter_first_name".tr;
                          },
                          controller: _fNameController,
                          decoration: ThemeHelper().textInputDecoration(
                            'first_name_label'.tr,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        decoration: ThemeHelper().inputBoxDecorationShaddow(),
                        child: TextFormField(
                          keyboardType: TextInputType.name,
                          validator: (item) {
                            return item!.length >= 2
                                ? null
                                : "enter_last_name".tr;
                          },
                          controller: _lNameController,
                          decoration: ThemeHelper().textInputDecoration(
                            'last_name_label'.tr,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        decoration: ThemeHelper().inputBoxDecorationShaddow(),
                        child: TextFormField(
                          inputFormatters: <TextInputFormatter>[
                            FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                          ],
                          keyboardType: Platform.isIOS
                              ? const TextInputType.numberWithOptions(
                            decimal: true,
                            signed: true,
                          )
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
                                GestureDetector(
                                  onTap: () {
                                    showCountryPicker(
                                      context: context,
                                      showPhoneCode: true,
                                      onSelect: (Country country) {
                                        phoneCode = "+${country.phoneCode}";
                                        setStateModal(() {});
                                      },
                                    );
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.only(right: 8.0),
                                    child: Text(
                                      phoneCode,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            hintText: "1234567890",
                            fillColor: Colors.white,
                            filled: true,
                            contentPadding:
                            const EdgeInsets.fromLTRB(20, 10, 20, 10),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10.0),
                              borderSide:
                              const BorderSide(color: Colors.grey),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10.0),
                              borderSide:
                              BorderSide(color: Colors.grey.shade400),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10.0),
                              borderSide:
                              const BorderSide(color: Colors.red, width: 2),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10.0),
                              borderSide:
                              const BorderSide(color: Colors.red, width: 2),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SmallButtonsWidget(
                        title: "save".tr,
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            Get.back();
                            handleAddFamilyMemberData();
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> handleAddFamilyMemberData() async {
    setState(() {
      _isLoading = true;
    });

    final res = await FamilyMembersService.addUser(
      fName: _fNameController.text,
      lName: _lNameController.text,
      isdCode: phoneCode,
      phone: _mobileController.text,
      dob: "",
      gender: "",
    );

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

  double getFeeFilter(dynamic gridData) {
    switch (gridData) {
      case "1":
        return clinicVisitFee ?? 0;
      case "2":
        return videoFee ?? 0;
      case "3":
        return emergencyFee ?? 0;
      default:
        return 0;
    }
  }

  void openAppointmentBox() {
    showModalBottomSheet(
      backgroundColor: ColorResources.cardBgColor,
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
          builder: (BuildContext context, setStateModal) {
            return Padding(
              padding: MediaQuery.of(context).viewInsets,
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 20),
                        Image.asset(
                          ImageConstants.appointmentImage,
                          height: 150,
                          width: 150,
                        ),
                        const SizedBox(height: 5),
                        Text(
                          "only_one_step_away".tr,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                        const Divider(),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "doctor:".tr,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              "${_doctorsModel?.fName ?? "--"} ${_doctorsModel?.lName ?? "--"}",
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "patient:".tr,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Flexible(
                              child: Text(
                                "${selectedFamilyMemberModel?.fName ?? "--"} ${selectedFamilyMemberModel?.lName ?? "--"}",
                                textAlign: TextAlign.end,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "appointment:".tr,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              getAppTypeName(_selectedAppointmentType).tr,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "date_time:".tr,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Flexible(
                              child: Text(
                                _selectedAppointmentType == "3"
                                    ? DateTimeHelper.getDataFormat(
                                  DateTimeHelper.getTodayDateInString(),
                                )
                                    : "${DateTimeHelper.getDataFormat(_selectedDate)} - ${DateTimeHelper.convertTo12HourFormat(_setTime)}",
                                textAlign: TextAlign.end,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "appointment_fee:".tr,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              CurrencyFormatterHelper.format(appointmentFee),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        couponValue == null
                            ? Container()
                            : Padding(
                          padding: const EdgeInsets.only(top: 10.0),
                          child: Row(
                            mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "coupon_off".trParams({
                                  "value": "$couponValue",
                                }),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                "-${CurrencyFormatterHelper.format(offPrice)}",
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "total_amount".tr,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              CurrencyFormatterHelper.format(totalAmount),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Forma de pago',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        RadioListTile<int>(
                          value:  PaymentTypeHelper.payAtClinic,
                          groupValue: selectedPaymentTypeId,
                          onChanged: (value) {
                            clearCoupon();
                            setStateModal(() {
                              selectedPaymentTypeId = value ?? 20;
                            });
                            setState(() {});
                          },
                          title: const Text(
                            'Pago en clínica',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        RadioListTile<int>(
                          value: PaymentTypeHelper.creditCard,
                          groupValue: selectedPaymentTypeId,
                          onChanged: (value) {
                            clearCoupon();
                            setStateModal(() {
                              selectedPaymentTypeId = value ?? 40;
                            });
                            setState(() {});
                          },
                          title: const Text(
                            'Tarjeta de crédito',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        RadioListTile<int>(
                          value: PaymentTypeHelper.qrCode,
                          groupValue: selectedPaymentTypeId,
                          onChanged: (value) {
                            clearCoupon();
                            setStateModal(() {
                              selectedPaymentTypeId = value ?? 41;
                            });
                            setState(() {});
                          },
                          title: const Text(
                            'QR Code',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        RadioListTile<int>(
                          value: PaymentTypeHelper.debitCard,
                          groupValue: selectedPaymentTypeId,
                          onChanged: (value) {
                            clearCoupon();
                            setStateModal(() {
                              selectedPaymentTypeId = value ?? 50;
                            });
                            setState(() {});
                          },
                          title: const Text(
                            'Tarjeta de débito',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        isOnlinePayment && couponEnable
                            ? _buildCouponCode(setStateModal)
                            : Container(),
                        const SizedBox(height: 10),
                        SmallButtonsWidget(
                          title: isOnlinePayment
                              ? "pay_and_book_amt".trParams({
                            "totalAmount":
                            CurrencyFormatterHelper.format(
                              totalAmount,
                            ),
                          })
                              : "book_appointment".tr,
                          onPressed: () {
                            Get.back();

                            final bool checkTime =
                            DateTimeHelper.checkIfTimePassed(
                              _endTime,
                              _selectedDate,
                            );

                            if (checkTime) {
                              IToastMsg.showMessage(
                                "the_time_has_passed".tr,
                              );
                              _openBottomSheet();
                              return;
                            }

                            if (isOnlinePayment) {
                              if (activePaymentGatewayName == "Paystack" &&
                                  email == "") {
                                _openBottomSheetEmail();
                              } else {
                                handleAppointmentPaymentWithBancard();
                              }
                            } else {
                              handleAddAppointment();
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _openBottomSheetEmail() {
    showModalBottomSheet(
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(20.0),
          topLeft: Radius.circular(20.0),
        ),
      ),
      context: context,
      builder: (BuildContext context) {
        return Padding(
          padding: MediaQuery.of(context).viewInsets,
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "email".tr,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        Get.back();
                      },
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                Form(
                  key: _formKey3,
                  child: Container(
                    decoration: ThemeHelper().inputBoxDecorationShaddow(),
                    child: TextFormField(
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "enter_a_valid_email_address".tr;
                        }
                        if (!RegExp(
                          r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                        ).hasMatch(value)) {
                          return "enter_a_valid_email_address".tr;
                        }
                        return null;
                      },
                      controller: _emailController,
                      decoration: ThemeHelper().textInputDecoration('email'.tr),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SmallButtonsWidget(
                  title: "next".tr,
                  onPressed: () {
                    Get.back();
                    if (_formKey3.currentState!.validate()) {
                      email = _emailController.text;
                      UserService.updateProfile(
                        fName: "",
                        lName: "",
                        gender: "",
                        dob: "",
                        email: email,
                      );
                      handleAppointmentPaymentWithBancard();
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> handleAddAppointment() async {
    setState(() {
      _isLoading = true;
    });
    final int durationMinutes = _selectedAppointmentType == "3"
        ? 15
        : _calculateDurationMinutes(_setTime, _endTime);
    final int paymentTypeId =
    PaymentTypeHelper.normalize(selectedPaymentTypeId);
    final dynamic res = await AppointmentService.addAppointment(
      familyMemberId: selectedFamilyMemberModel?.id.toString() ?? "",
      patientId: "",
      status: "Confirmed",
      date: _selectedAppointmentType == "3"
          ? DateTimeHelper.getTodayDateInString()
          : _selectedDate,
      timeSlots: _selectedAppointmentType == "3"
          ? DateTimeHelper.getTodayTimeInString()
          : _setTime,
      durationMinutes: durationMinutes.toString(),
      doctId: widget.doctId ?? "",
      deptId: _doctorsModel?.deptId?.toString() ?? "",
      type: getAppTypeName(_selectedAppointmentType),
      meetingId: "",
      meetingLink: "",
      paymentStatus: "Unpaid",
      fee: appointmentFee.toString(),
      totalAmount: totalAmount.toString(),
      invoiceDescription: getAppTypeName(_selectedAppointmentType),
      paymentMethod: getPaymentTypeLabel(selectedPaymentTypeId),
      idPaymentType: paymentTypeId,
      paymentTransactionId: "",
      isWalletTxn: "0",
      couponId: couponId == null ? "" : couponId.toString(),
      couponOffAmount: offPrice.toString(),
      couponTitle: _couponNameController.text,
      couponValue: couponValue == null ? "" : couponValue.toString(),
      unitTotalAmount: unitTotalAmount.toString(),
    );

    if (res != null) {
      IToastMsg.showMessage("success".tr);

      final int? appointmentId = _readCreatedAppointmentId(res);

      setState(() {
        _isLoading = false;
      });

      if (appointmentId != null) {
        Get.offNamedUntil(
          RouteHelper.getAppointmentDetailsPageRoute(
            appId: appointmentId.toString(),
          ),
          ModalRoute.withName('/HomePage'),
        );
        return;
      }

      Get.offNamedUntil(
        RouteHelper.getMyBookingPageRoute(),
        ModalRoute.withName('/HomePage'),
      );
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> handleAppointmentPaymentWithBancard() async {
    setState(() {
      _isLoading = true;
    });
    final int durationMinutes = _selectedAppointmentType == "3"
        ? 15
        : _calculateDurationMinutes(_setTime, _endTime);
    try {
      final SharedPreferences preferences = await SharedPreferences.getInstance();
      final String uidRaw =
          preferences.getString(SharedPreferencesConstants.uid) ?? "-1";
      final int userId = int.tryParse(uidRaw) ?? -1;

      if (userId <= 0) {
        IToastMsg.showMessage("No se encontró el usuario.");
        setState(() {
          _isLoading = false;
        });
        return;
      }
      final int paymentTypeId =
      PaymentTypeHelper.normalize(selectedPaymentTypeId);
      final dynamic appointmentRes = await AppointmentService.addAppointment(
        familyMemberId: selectedFamilyMemberModel?.id.toString() ?? "",
        patientId: "",
        status: "Confirmed",
        date: _selectedAppointmentType == "3"
            ? DateTimeHelper.getTodayDateInString()
            : _selectedDate,
        timeSlots: _selectedAppointmentType == "3"
            ? DateTimeHelper.getTodayTimeInString()
            : _setTime,
        durationMinutes: durationMinutes.toString(),
        doctId: widget.doctId ?? "",
        deptId: _doctorsModel?.deptId?.toString() ?? "",
        type: getAppTypeName(_selectedAppointmentType),
        meetingId: "",
        meetingLink: "",
        paymentStatus: "Unpaid",
        fee: appointmentFee.toString(),
        totalAmount: totalAmount.toString(),
        invoiceDescription: getAppTypeName(_selectedAppointmentType),
        idPaymentType: paymentTypeId,
        paymentMethod: getPaymentTypeLabel(selectedPaymentTypeId),
        paymentTransactionId: "",
        isWalletTxn: "0",
        couponId: couponId == null ? "" : couponId.toString(),
        couponOffAmount: offPrice.toString(),
        couponTitle: _couponNameController.text,
        couponValue: couponValue == null ? "" : couponValue.toString(),
        unitTotalAmount: unitTotalAmount.toString(),
      );

      final int? appointmentId = _readCreatedAppointmentId(appointmentRes);

      if (appointmentId == null) {
        IToastMsg.showMessage("No se recibió appointment_id.");
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final Map<String, dynamic>? paymentStartResponse =
      await bancardAppointmentPaymentProvider.startAppointmentPayment(
        appointmentId: appointmentId,
        userId: userId,
        paymentTypeId: selectedPaymentTypeId,
        amount: totalAmount,
        currency: 'PYG',
        description:
        'Appointment #$appointmentId - ${getAppTypeName(_selectedAppointmentType)}',
      );

      print('paymentStart raw = $paymentStartResponse');

      if (paymentStartResponse == null) {
        IToastMsg.showMessage("No se pudo iniciar el pago.");
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final Map<String, dynamic> root = paymentStartResponse;


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

      final String? checkoutPageUrl =
      paymentFlow['checkout_page_url']?.toString();
      final String? paymentUrl = paymentFlow['payment_url']?.toString();

      if ((checkoutPageUrl == null || checkoutPageUrl.isEmpty) &&
          (paymentUrl == null || paymentUrl.isEmpty)) {
        print('start-payment root = $root');
        IToastMsg.showMessage(
          root['message']?.toString() ?? "No se recibió URL de pago.",
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _isLoading = false;
      });

      final dynamic result = await Get.to(
            () => MedicareClientPaymentGatewayPage(),
        arguments: {
          'appointment_id': appointmentId,
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
        },
      );

      await _handleGatewayResult(result, appointmentId);
    } catch (e) {
      if (kDebugMode) {
        print('handleAppointmentPaymentWithBancard error: $e');
      }

      setState(() {
        _isLoading = false;
      });

      IToastMsg.showMessage("something_went_wrong".tr);
    }
  }

  int? _readCreatedAppointmentId(dynamic raw) {
    if (raw == null) return null;

    if (raw is Map<String, dynamic>) {
      if (raw['id'] != null) {
        return int.tryParse(raw['id'].toString());
      }

      if (raw['data'] is Map<String, dynamic>) {
        final Map<String, dynamic> data = raw['data'];
        if (data['id'] != null) {
          return int.tryParse(data['id'].toString());
        }
      }
    }

    if (raw is Map) {
      final Map<String, dynamic> map = Map<String, dynamic>.from(raw);

      if (map['id'] != null) {
        return int.tryParse(map['id'].toString());
      }

      if (map['data'] is Map) {
        final Map<String, dynamic> data = Map<String, dynamic>.from(map['data']);
        if (data['id'] != null) {
          return int.tryParse(data['id'].toString());
        }
      }
    }

    return null;
  }
  int _calculateDurationMinutes(String startTime, String endTime) {
    final startParts = startTime.split(':').map(int.parse).toList();
    final endParts = endTime.split(':').map(int.parse).toList();

    final startMinutes = (startParts[0] * 60) + startParts[1];
    final endMinutes = (endParts[0] * 60) + endParts[1];

    final diff = endMinutes - startMinutes;
    return diff > 0 ? diff : 15;
  }

  Map<String, dynamic> _parseDynamicMap(dynamic rawData) {
    if (rawData == null) return <String, dynamic>{};

    if (rawData is Map<String, dynamic>) {
      return rawData;
    }

    if (rawData is Map) {
      return Map<String, dynamic>.from(rawData);
    }

    if (rawData is String) {
      try {
        final dynamic decoded = jsonDecode(rawData);
        if (decoded is Map<String, dynamic>) {
          return decoded;
        }
        if (decoded is Map) {
          return Map<String, dynamic>.from(decoded);
        }
      } catch (_) {
        return <String, dynamic>{};
      }
    }

    return <String, dynamic>{};
  }

  Future<void> _handleGatewayResult(dynamic result, int appointmentId) async {
    if (result is! Map) {
      Get.offNamedUntil(
        RouteHelper.getAppointmentDetailsPageRoute(
          appId: appointmentId.toString(),
        ),
        ModalRoute.withName('/HomePage'),
      );
      return;
    }

    final String status =
        result['payment_gateway_status']?.toString() ?? 'unknown';

    if (status == 'success') {
      IToastMsg.showMessage("appointment_booked_successfully".tr);
      Get.offNamedUntil(
        RouteHelper.getAppointmentDetailsPageRoute(
          appId: appointmentId.toString(),
        ),
        ModalRoute.withName('/HomePage'),
      );
      return;
    }

    if (status == 'canceled') {
      IToastMsg.showMessage("Pago cancelado. La cita quedó pendiente.");
      Get.offNamedUntil(
        RouteHelper.getAppointmentDetailsPageRoute(
          appId: appointmentId.toString(),
        ),
        ModalRoute.withName('/HomePage'),
      );
      return;
    }

    if (status == 'failed' || status == 'pending') {
      IToastMsg.showMessage("La cita quedó pendiente de pago.");
      Get.offNamedUntil(
        RouteHelper.getAppointmentDetailsPageRoute(
          appId: appointmentId.toString(),
        ),
        ModalRoute.withName('/HomePage'),
      );
      return;
    }

    Get.offNamedUntil(
      RouteHelper.getAppointmentDetailsPageRoute(
        appId: appointmentId.toString(),
      ),
      ModalRoute.withName('/HomePage'),
    );
  }

  bool getCheckBookedTimeSlot(
      String timeStart,
      List<BookedTimeSlotsModel> bookedTimeSlots,
      ) {
    bool returnValue = false;
    for (var element in bookedTimeSlots) {
      if (element.timeSlots == timeStart) {
        returnValue = true;
        break;
      }
    }
    return returnValue;
  }

  void clearInitData() {
    _fNameController.clear();
    _lNameController.clear();
    _mobileController.clear();
  }

  Widget _buildCouponCode(setStateModal) {
    return Row(
      children: [
        Flexible(
          flex: 4,
          child: Container(
            decoration: ThemeHelper().inputBoxDecorationShaddow(),
            child: TextFormField(
              keyboardType: TextInputType.name,
              validator: (item) {
                return item!.length > 2
                    ? null
                    : "enter_coupon_code_if_any".tr;
              },
              controller: _couponNameController,
              decoration: ThemeHelper().textInputDecoration('coupon_code'.tr),
            ),
          ),
        ),
        Flexible(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.only(left: 8.0, right: 8),
            child: SmallButtonsWidget(
              title: couponValue == null ? "apply".tr : "remove".tr,
              onPressed: couponValue == null
                  ? () async {
                if (_formKey.currentState!.validate()) {
                  Get.back();
                  handelCheckCoupon();
                }
              }
                  : () {
                clearCoupon();
                setStateModal(() {});
                Get.back();
                openAppointmentBox();
                IToastMsg.showMessage("coupon_removed".tr);
              },
            ),
          ),
        ),
      ],
    );
  }

  Future<void> handelCheckCoupon() async {
    setState(() {
      _isLoading = true;
    });

    final res = await CouponService.getValidateData(
      title: _couponNameController.text.toUpperCase(),
      clinicId: _doctorsModel?.clinicId.toString(),
    );

    if (res != null && res['status'] == true) {
      IToastMsg.showMessage(res['msg']);
      final value = res['data']['value'];
      final couponIdGet = res['data']['id'];
      couponValue = value != null ? double.parse(value.toString()) : null;
      couponId = couponIdGet != null ? int.parse(couponIdGet.toString()) : null;
      amtCalculation();
    } else {
      IToastMsg.showMessage(res['msg'] ?? "");
      clearCoupon();
    }

    setState(() {
      _isLoading = false;
    });

    openAppointmentBox();
  }

  void amtCalculation() {
    unitTotalAmount = appointmentFee;
    if (appointmentFee == 0) return;

    if (couponValue != null) {
      offPrice = (appointmentFee * couponValue!) / 100;
    } else {
      offPrice = 0;
    }

    totalAmount = appointmentFee - offPrice;
    setState(() {});
  }

  void clearCoupon() {
    couponValue = null;
    couponId = null;
    _couponNameController.clear();
    amtCalculation();
    setState(() {});
  }

  Widget _buildSocialMediaSection() {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        children: [
          _doctorsModel?.youtubeLink == null || _doctorsModel?.youtubeLink == ""
              ? Container()
              : GestureDetector(
            onTap: () {
              final url = _doctorsModel?.youtubeLink ?? "";
              launchUrl(
                Uri.parse(url),
                mode: LaunchMode.externalApplication,
              );
            },
            child: Image.asset(
              ImageConstants.youtubeImageBox,
              width: 30,
              height: 30,
            ),
          ),
          _doctorsModel?.fbLink == null || _doctorsModel?.fbLink == ""
              ? Container()
              : Padding(
            padding: const EdgeInsets.only(left: 20.0),
            child: GestureDetector(
              onTap: () {
                final url = _doctorsModel?.fbLink ?? "";
                launchUrl(
                  Uri.parse(url),
                  mode: LaunchMode.externalApplication,
                );
              },
              child: Image.asset(
                ImageConstants.facebookImageBox,
                width: 30,
                height: 30,
              ),
            ),
          ),
          _doctorsModel?.instaLink == null || _doctorsModel?.instaLink == ""
              ? Container()
              : Padding(
            padding: const EdgeInsets.only(left: 20.0),
            child: GestureDetector(
              onTap: () {
                final url = _doctorsModel?.instaLink ?? "";
                launchUrl(
                  Uri.parse(url),
                  mode: LaunchMode.externalApplication,
                );
              },
              child: Image.asset(
                ImageConstants.instagramImageBox,
                width: 30,
                height: 30,
              ),
            ),
          ),
          _doctorsModel?.twitterLink == null || _doctorsModel?.twitterLink == ""
              ? Container()
              : Padding(
            padding: const EdgeInsets.only(left: 20.0),
            child: GestureDetector(
              onTap: () {
                final url = _doctorsModel?.twitterLink ?? "";
                launchUrl(
                  Uri.parse(url),
                  mode: LaunchMode.externalApplication,
                );
              },
              child: Image.asset(
                ImageConstants.twitterImageBox,
                width: 30,
                height: 30,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingReviewBox() {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 150),
        child: PageView.builder(
          scrollDirection: Axis.horizontal,
          controller: PageController(viewportFraction: 0.9),
          itemCount: doctorReviewModel.length,
          itemBuilder: (context, index) {
            DoctorsReviewModel doctorsReviewModel = doctorReviewModel[index];
            return SizedBox(
              width: MediaQuery.sizeOf(context).width,
              child: Card(
                color: ColorResources.cardBgColor,
                elevation: .1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5.0),
                ),
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  isThreeLine: true,
                  leading: const Padding(
                    padding: EdgeInsets.only(left: 8.0),
                    child: Icon(Icons.person, size: 30),
                  ),
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${doctorsReviewModel.fName} ${doctorsReviewModel.lName}",
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      StarRating(
                        mainAxisAlignment: MainAxisAlignment.start,
                        length: 5,
                        color: doctorsReviewModel.points == 0
                            ? Colors.grey
                            : Colors.amber,
                        rating: double.parse(
                          (doctorsReviewModel.points ?? 0).toString(),
                        ),
                        between: 5,
                        starSize: 15,
                        onRaitingTap: (rating) {},
                      ),
                    ],
                  ),
                  subtitle: Text(
                    doctorsReviewModel.description ?? "--",
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildClinicInfo() {
    return GestureDetector(
      onTap: () {
        Get.toNamed(
          RouteHelper.getClinicPageRoute(
            clinicId: _doctorsModel?.clinicId.toString(),
          ),
        );
      },
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(5.0),
        ),
        color: ColorResources.cardBgColor,
        elevation: .1,
        child: ListTile(
          leading: _doctorsModel?.clinicThumbImage == null ||
              _doctorsModel?.clinicThumbImage == ""
              ? const SizedBox(
            height: 70,
            width: 70,
            child: Icon(Icons.image, size: 40),
          )
              : SizedBox(
            height: 70,
            width: 70,
            child: CircleAvatar(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: ImageBoxFillWidget(
                  imageUrl:
                  "${ApiContents.imageUrl}/${_doctorsModel?.clinicThumbImage}",
                  boxFit: BoxFit.fill,
                ),
              ),
            ),
          ),
          title: Text(
            _doctorsModel?.clinicTitle ?? "--",
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black,
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: Text(
            _doctorsModel?.clinicAddress ?? "--",
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              color: ColorResources.secondaryFontColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageClinic(List clinicImages) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: SizedBox(
        height: 70,
        child: GridView.builder(
          scrollDirection: Axis.horizontal,
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 100,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
          ),
          itemCount: clinicImages.length,
          itemBuilder: (context, index) {
            return GestureDetector(
              onTap: () {
                Get.to(
                      () => FullScreenImageViewerPage(
                    initialIndex: index,
                    images: clinicImages,
                    clinicName: _doctorsModel?.clinicTitle,
                  ),
                );
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: ImageBoxFillWidget(
                  boxFit: BoxFit.cover,
                  imageUrl:
                  "${ApiContents.imageUrl}/${clinicImages[index]['image']}",
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}