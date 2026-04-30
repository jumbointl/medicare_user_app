import 'dart:io';
import 'package:medicare_user_app/model/currency_model.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:udemy_core/udemy_core.dart' show SafeBottomBar;
import 'package:url_launcher/url_launcher.dart';
import '../controller/clinic_controller.dart';
import '../controller/pathologist_controller.dart';
import '../model/blog_post_model.dart';
import '../model/clinic_model.dart';
import '../model/pathologist_model.dart';
import '../services/banner_service.dart';
import '../services/blog_post_service.dart';
import '../services/city_service.dart';
import '../controller/depratment_controller.dart';
import '../controller/doctors_controller.dart';
import '../controller/notification_dot_controller.dart';
import '../helpers/route_helper.dart';
import '../model/city_model.dart';
import '../model/department_model.dart';
import '../model/doctors_model.dart';
import '../pages/auth/login_page.dart';
import '../pages/clinic_page.dart';
import '../pages/doctors_list_page.dart';
import '../pages/my_booking_page.dart';
import '../pages/wallet_page.dart';
import '../services/configuration_service.dart';
import '../services/notification_seen_service.dart';
import '../utilities/sharedpreference_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:star_rating/star_rating.dart';
import '../controller/user_controller.dart';
import '../utilities/api_content.dart';
import '../utilities/clinic_config.dart';
import '../utilities/colors_constant.dart';
import '../utilities/image_constants.dart';
import '../widget/carousel_widget.dart';
import '../widget/drawer_widget.dart';
import '../widget/image_box_widget.dart';
import '../widget/loading_Indicator_widget.dart';
import '../widget/search_box_widget.dart';
import 'package:location/location.dart' as loc;
import 'package:app_settings/app_settings.dart';

import 'edit_profile_page.dart';
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey<ScaffoldState> _key = GlobalKey();
  final DepartmentController _departmentController=Get.put(DepartmentController(),tag: "department");
  final DoctorsController _doctorsController=Get.put(DoctorsController(),tag: "doctor");
  final ScrollController _scrollController=ScrollController();
  final NotificationDotController _notificationDotController=Get.find(tag: "notification_dot");
  final ClinicController _clinicController=Get.put(ClinicController());
  final PathologistController _pathologistController=Get.put(PathologistController());
  final TextEditingController _searchTextController=TextEditingController();
  final ScrollController _bottomSheetScrollController=ScrollController();
  List <BlogPostModel> blogList=[];

  int _selectedIndex = 3; // Index of the initially selected item
  bool _isLoading=false;
  UserController userController=Get.find(tag: "user");
  String appStoreUrl="";
  String playStoreUrl="";
  String? clinicLat;
  String? clinicLng;
  String? email;
  String? phone;
  String? cityId;
  String? cityName;
  String? whatsapp;
  String? ambulancePhone;
  List<CityModel> _cityModelList=[];
  List<CityModel> filteredCities = [];
  bool enableAiAssistant=false;
  List <String> bannerImageList=[];

  late List boxCardItems=[
    {
      "title":"appointment",
      "assets":ImageConstants.appointmentImageBox,
      "onClick":()async{
        SharedPreferences preferences = await SharedPreferences.getInstance();

        final loggedIn = preferences.getBool(SharedPreferencesConstants.login) ??false;
        final userId= preferences.getString(SharedPreferencesConstants.uid);
        if(loggedIn&&userId!=""&&userId!=null){
          Get.toNamed(RouteHelper.getMyBookingPageRoute());
        }else{
          Get.to(()=>LoginPage(onSuccessLogin:  (){ Get.toNamed(RouteHelper.getMyBookingPageRoute());}));
          // Get.toNamed(RouteHelper.getLoginPageRoute());
        }
      }
    },
    {
      "title":"vitals",
      "assets":ImageConstants.vialImageBox,
      "onClick":()async{
        SharedPreferences preferences = await SharedPreferences.getInstance();

        final loggedIn = preferences.getBool(SharedPreferencesConstants.login) ??false;
        final userId= preferences.getString(SharedPreferencesConstants.uid);
        if(loggedIn&&userId!=""&&userId!=null){
          Get.toNamed(RouteHelper.getVitalsPageRoute());
        }else{
          Get.to(()=>LoginPage(onSuccessLogin:  (){ Get.toNamed(RouteHelper.getVitalsPageRoute());}));
          // Get.toNamed(RouteHelper.getLoginPageRoute());
        }
      }
    },
    {
      "title":"prescription",
      "assets":ImageConstants.prescriptionImageBox,
      "onClick":()async{
        SharedPreferences preferences = await SharedPreferences.getInstance();

        final loggedIn = preferences.getBool(SharedPreferencesConstants.login) ??false;
        final userId= preferences.getString(SharedPreferencesConstants.uid);
        if(loggedIn&&userId!=""&&userId!=null){
          Get.toNamed(RouteHelper.getPrescriptionListPageRoute());
        }else{
          Get.to(()=>LoginPage(onSuccessLogin:  (){ Get.toNamed(RouteHelper.getPrescriptionListPageRoute());}));
          // Get.toNamed(RouteHelper.getLoginPageRoute());
        }
      }
    },
    {
      "title":"profile",
      "assets":ImageConstants.profileImageBox,
      "onClick":()async{
        SharedPreferences preferences = await SharedPreferences.getInstance();

        final loggedIn = preferences.getBool(SharedPreferencesConstants.login) ??false;
        final userId= preferences.getString(SharedPreferencesConstants.uid);
        if(loggedIn&&userId!=""&&userId!=null){

          Get.toNamed(RouteHelper.getEditUserProfilePageRoute());

        }else{

          Get.to(() => LoginPage(
            onSuccessLogin: () {
              Get.back();
              Get.to(
                    () => LoginPage(
                  onSuccessLogin: () {
                    Get.back();
                    Get.to(() => const EditProfilePage(autoCloseSeconds: 0));
                  },
                ),
              );
            },
          ));
        }
      }
    },
    {
      "title":"family_member",
      "assets":ImageConstants.familyMemberImageBox,
      "onClick":()async{
        SharedPreferences preferences = await SharedPreferences.getInstance();

        final loggedIn = preferences.getBool(SharedPreferencesConstants.login) ??false;
        final userId= preferences.getString(SharedPreferencesConstants.uid);
        if(loggedIn&&userId!=""&&userId!=null){
          Get.toNamed(RouteHelper.getFamilyMemberListPageRoute());
        }else{
          Get.to(()=>LoginPage(onSuccessLogin:  (){ Get.toNamed(RouteHelper.getFamilyMemberListPageRoute());}));
          // Get.toNamed(RouteHelper.getLoginPageRoute());
        }
      }
    },
    {
      "title":"wallet",
      "assets":ImageConstants.walletImageBox,
      "onClick":()async{
        SharedPreferences preferences = await SharedPreferences.getInstance();

        final loggedIn = preferences.getBool(SharedPreferencesConstants.login) ??false;
        final userId= preferences.getString(SharedPreferencesConstants.uid);
        if(loggedIn&&userId!=""&&userId!=null){
          Get.toNamed(RouteHelper.getWalletPageRoute());
        }else{
          Get.to(()=>LoginPage(onSuccessLogin:  (){ Get.toNamed(RouteHelper.getWalletPageRoute());}));
          // Get.toNamed(RouteHelper.getLoginPageRoute());
        }
      }
    },
    {
      "title":"notification",
      "assets":ImageConstants.notificationImageBox,
      "onClick":()async{
        SharedPreferences preferences = await SharedPreferences.getInstance();

        final loggedIn = preferences.getBool(SharedPreferencesConstants.login) ??false;
        final userId= preferences.getString(SharedPreferencesConstants.uid);
        if(loggedIn&&userId!=""&&userId!=null){
          Get.toNamed(RouteHelper.getNotificationPageRoute());
        }else{
          Get.to(()=>LoginPage(onSuccessLogin:  (){ Get.toNamed(RouteHelper.getNotificationPageRoute());}));
          // Get.toNamed(RouteHelper.getLoginPageRoute());
        }
      }
    },
    {
      "title":"contact_us",
      "assets":ImageConstants.contactUsImageBox,
      "onClick":()async{

       Get.toNamed(RouteHelper.getContactUsPageRoute());
      }
    },
    {
      "title":"files",
      "assets":ImageConstants.filesImageBox,
      "onClick":()async{
        SharedPreferences preferences = await SharedPreferences.getInstance();

        final loggedIn = preferences.getBool(SharedPreferencesConstants.login) ??false;
        final userId= preferences.getString(SharedPreferencesConstants.uid);
        if(loggedIn&&userId!=""&&userId!=null){
          Get.toNamed(RouteHelper.getPatientFilePageRoute());
        }else{
          Get.to(()=>LoginPage(onSuccessLogin:  (){ Get.toNamed(RouteHelper.getPatientFilePageRoute());}));
          // Get.toNamed(RouteHelper.getLoginPageRoute());
        }
      }
    }
  ];
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadInitialData();
    });
  }

  Future<void> _loadInitialData() async {
    await userController.getData();
    if (!mounted) return;
    _requestLocationPermission();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _selectedIndex==3?true:false,
      onPopInvokedWithResult: (didPop, dynamic)  {
        if (_selectedIndex == 3) {}
        else {
          setState(() {
            _selectedIndex = 3;
          });
        //  return false;
        }
      },
      child: Scaffold(
          key: _key,
          drawer:_isLoading?null:IDrawerWidget().buildDrawerWidget(userController,_notificationDotController,enableAiAssistant),
        backgroundColor: ColorResources.bgColor,
          bottomNavigationBar:_isLoading?null: SafeBottomBar(child: BottomAppBar(
            height: 80,
            shape: const CircularNotchedRectangle(),
            notchMargin: 8.0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                GestureDetector(
                  onTap: () async {
                      SharedPreferences preferences = await SharedPreferences.getInstance();
                      final loggedIn = preferences.getBool(
                          SharedPreferencesConstants.login) ?? false;
                      final userId = preferences.getString(
                          SharedPreferencesConstants.uid);
                      if (loggedIn && userId != "" && userId != null) {
                        _onItemTapped(4);
                      } else {
                     Get.to(LoginPage(onSuccessLogin: (){  _onItemTapped(4);},));
                      }
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.calendar_month,
                          color: _selectedIndex == 4 ? ColorResources
                              .primaryColor : Colors.black),
                      const SizedBox(height: 3),
                      Text("appointments".tr,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: _selectedIndex == 4 ? ColorResources
                                .primaryColor : Colors.grey
                        ),)
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    _onItemTapped(2);
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.search,
                          color: _selectedIndex == 2 ? ColorResources
                              .primaryColor : Colors.black),
                      const SizedBox(height: 3),
                      Text("search".tr,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: _selectedIndex == 2 ? ColorResources
                                .primaryColor : Colors.grey
                        ),)
                    ],
                  ),
                ),
                const SizedBox(width: 30),
                // Empty space for the circular button
                GestureDetector(
                  onTap: () async {
                    SharedPreferences preferences = await SharedPreferences.getInstance();
                    final loggedIn = preferences.getBool(
                        SharedPreferencesConstants.login) ?? false;
                    final userId = preferences.getString(
                        SharedPreferencesConstants.uid);
                    if (loggedIn && userId != "" && userId != null) {
                      _onItemTapped(1);
                    } else {
                      Get.to(LoginPage(onSuccessLogin: (){  _onItemTapped(1);},));
                    }
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.account_balance_wallet,
                          color: _selectedIndex == 1 ? ColorResources
                              .primaryColor : Colors.black),
                      const SizedBox(height: 3),
                      Text("wallet".tr,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: _selectedIndex == 1 ? ColorResources
                                .primaryColor : Colors.grey
                        ),)
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () {
                    _key.currentState!.openDrawer();
                    // print("open drawer");
                  },
                  child:  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const   Icon(Icons.menu,
                        color: Colors.black,
                      ),
                      const  SizedBox(height: 3),
                      Text("menu".tr,
                        style:const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey,
                        ),)
                    ],
                  ),
                )

              ],
            ),
          )),
          floatingActionButtonLocation:_isLoading?null:
          FloatingActionButtonLocation.centerDocked,
          floatingActionButton: MediaQuery
              .of(context)
              .viewInsets
              .bottom != 0 ? null :
          FloatingActionButton(
            heroTag: "home_main_fab",
            backgroundColor: ColorResources.secondaryColor,
            onPressed:()=> _onItemTapped(3),
            tooltip: 'home'.tr,
            elevation: 2.0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30.0),
            ),
            child: const Icon(Icons.home,
            color: Colors.white),
          ),
        body:
            Stack(
              children: [
                _isLoading||cityId==""||cityId==null?const ILoadingIndicatorWidget(): _selectedIndex == 1 ? const WalletPage() : _selectedIndex == 2
                    ? const DoctorsListPage(selectedDeptTitle: "",selectedDeptId: "")
                    : _selectedIndex == 4 ? const MyBookingPage() :_buildBody(),

               enableAiAssistant? Positioned(
                  bottom: 20, // above bottom navigation
                  right: 16,
                  child: FloatingActionButton(
                    heroTag: "chat_fab",
                    backgroundColor: ColorResources.btnColor,
                    onPressed: () async {
                      Get.toNamed(RouteHelper.getAiChatPageRoute());
                    },
                    child: const Icon(Icons.chat, color: Colors.white),
                  ),
                ):Container(),
              ],
            )

      ),
    );
  }



  _buildBody() {
    return ListView(
      controller: _scrollController,
      padding:const  EdgeInsets.all(0),
      children: [
        _buildProfileSection(),

        bannerImageList.isEmpty?Container():   CarouselSliderWidget(
          imagesUrl: bannerImageList,
        ),
       // _buildHeaderSection(),
        (enableAiAssistant && ClinicConfig.showAiBanner) ? aiDoctorSuggestionCard() : Container(),
        _buildDepartment(),
        _buildClinicSection(),
        if (!ClinicConfig.hasClinicFilter) _buildDoctor(),
        if (ClinicConfig.showLab) _buildPathologistLab(),
        if (ClinicConfig.showBlog && blogList.isNotEmpty) _buildBlogList(),
        _buildCardBox(),
        const SizedBox(height: 100)
      ],
    );
  }

  _buildCardBox(){
    return    GridView.builder(
      controller: _scrollController,
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      itemCount: 9,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          childAspectRatio: 1,
          crossAxisCount: 3 ),
      itemBuilder: (BuildContext context, int index) {
        return  Card(
          elevation: .1,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          child:  GestureDetector(
            onTap: boxCardItems[index]['onClick'],
            child: GridTile(
              footer:  Padding(
                padding: const EdgeInsets.all(5.0),
                child: Text(boxCardItems[index]['title'].toString().tr,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500
                ),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(40.0),
                child: Image.asset(boxCardItems[index]['assets']),
              ), //just for testing, will fill with image later
            ),
          ),
        );
      },
    );
  }
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

  }
  _buildDepartmentBox(List dataList) {
    return Card(
      elevation: .1,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(5.0),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(5),
        title:   Padding(
            padding:const EdgeInsets.only(bottom: 10.0),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children:[
                   Text("department".tr,
                    style:const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14
                    ),),
                  dataList.length<4?Container():
                   Text('swipe_more'.tr,
                    style: const TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.w600,
                        fontSize: 14
                    ),),
                ]
            )

        ),
        subtitle:  SizedBox(
          height: 100,
          child: ListView.builder(
              padding: const EdgeInsets.all(0),
              itemCount: dataList.length,
              shrinkWrap: true,
              scrollDirection: Axis.horizontal,
              itemBuilder: (context,index){
                final DepartmentModel departmentModel=dataList[index];
                return  Padding(
                  padding: const EdgeInsets.fromLTRB(8,8,18,8),
                  child: GestureDetector(
                    onTap: (){
                         Get.toNamed(RouteHelper.getDoctorsListPageRoute(
                           selectedDeptId: departmentModel.id?.toString()??"",
                           selectedDeptTitle: departmentModel.title??""
                         ));
                      //   Get.toNamed(RouteHelper.getSearchProductsPageRoute(initSelectedProductCatId: productCatModel.id.toString()));
                    },
                    child: Column(
                      children: [
                        departmentModel.image == null ||
                            departmentModel.image == "" ?
                        const CircleAvatar(
                          backgroundColor: Colors.white,
                          radius: 25,
                          child: Icon(Icons.image),
                        )
                            :
                        CircleAvatar(
                            backgroundColor: Colors.white,
                            radius: 25,
                            child:
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                image: DecorationImage(
                                  fit: BoxFit.fill,
                                  image: NetworkImage(
                                      '${ApiContents.imageUrl}/${departmentModel.image}'
                                  ),
                                ),
                              ),
                            )
                        ),
                        const SizedBox(height: 5),
                        Text(departmentModel.title??"--",
                          maxLines: 1, // Limit to 1 line
                          overflow: TextOverflow.ellipsis,
                          style:const  TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500
                          ),
                        )
                      ],
                    ),
                  ),
                );}),
        ),
      ),
    );
  }
  _buildDoctorBox(List dataList) {
    return Card(
      elevation: .1,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(5.0),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(5),
        title:   Padding(
            padding:const EdgeInsets.only(bottom: 10.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'best_doctors_in'.trParams({'city': cityName ?? '--'}),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  if (dataList.length >= 3) ...[
                    const SizedBox(width: 12),
                    Text(
                      'swipe_more'.tr,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ],
              ),
            )
        ),
        subtitle:   Padding(
          padding: const EdgeInsets.only(top:10.0),
          child: SizedBox(
              height:  dataList.length>2?220:100,
              child:
              GridView.builder(
                  padding: const EdgeInsets.all(0),
                   physics: dataList.length>2?null:const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  scrollDirection:  dataList.length>2?Axis.horizontal:Axis.vertical,
                  itemCount: dataList.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      childAspectRatio: .58,
                      crossAxisCount: 2 ),
                  itemBuilder: (context,index){
                    return   _buildDoctorCard(dataList[index]);
                  })
          ),
        ),

      ),
    );
  }

  _buildClinicList(List dataList) {
    return Card(
      elevation: .1,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(5.0),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(5),
        title:   Padding(
            padding:const EdgeInsets.only(bottom: 10.0),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children:[
                  Text('best_clinic_in'.trParams({'city': cityName ?? '--'}),

                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14
                    ),),
                  GestureDetector(
                    onTap: (){
                      Get.toNamed(RouteHelper.getClinicListPageRoute());
                    },
                    child:   Text('view_all'.tr,
                      style:TextStyle(
                          color: ColorResources.btnColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 14
                      ),),
                  ),
                ]
            )
        ),
        subtitle:   Padding(
          padding: const EdgeInsets.only(top:10.0),
          child: ListView.builder(
              padding: const EdgeInsets.all(0),
              controller: _scrollController,
              // physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: dataList.length<=5?dataList.length:5,
              itemBuilder: (context,index){
                return   _buildClinicCard(dataList[index]);
              }),
        ),

      ),
    );
  }
  _buildPathLabList(List dataList) {
    return Card(
      elevation: .1,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(5.0),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(5),
        title:   Padding(
            padding:const EdgeInsets.only(bottom: 10.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'best_path_in'.trParams({'city': cityName ?? '--'}),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () {
                      Get.toNamed(RouteHelper.getPathologistListPageRoute());
                    },
                    child: Text(
                      'view_all'.tr,
                      style: TextStyle(
                        color: ColorResources.btnColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            )
        ),
        subtitle:   Padding(
          padding: const EdgeInsets.only(top:10.0),
          child: ListView.builder(
              padding: const EdgeInsets.all(0),
              controller: _scrollController,
              // physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: dataList.length<=5?dataList.length:5,
              itemBuilder: (context,index){
                return   _buildPathCard(dataList[index]);
              }),
        ),

      ),
    );
  }
  _buildPathCard(PathologistModel pathModel){
    return ListTile(
      isThreeLine: true,
      onTap: (){
        Get.toNamed(RouteHelper.getPathologyPageRoute(pathId: pathModel.id.toString()));
      },
      title: Text(pathModel.title??"",
        style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14
        ),
      ),
      subtitle:  Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 2),
          Row(
            children: [
              StarRating(
                mainAxisAlignment: MainAxisAlignment.center,
                length: 5,
                color: pathModel.averageRating == 0
                    ? Colors.grey
                    : Colors.amber,
                rating: pathModel.averageRating ?? 0,
                between: 5,
                starSize: 15,
                onRaitingTap: (rating) {},
              ),
              const SizedBox(width: 10),
              Text(
                'rating_review_text'.trParams({
                  'rating': '${pathModel.averageRating ?? "--"}',
                  'count': '${pathModel.numberOfReview ?? 0}',
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
                  "count": (pathModel.totalBookingDone ?? 0).toString()
                }),
                style: const TextStyle(
                    color: ColorResources.greenFontColor,
                    fontWeight: FontWeight.w500,
                    fontSize: 12
                ),)
            ],
          ),
          const SizedBox(height: 5),
          Text(pathModel.address??"",
            style: TextStyle(
                color: ColorResources.secondaryFontColor,
                fontWeight: FontWeight.w400,
                fontSize: 12
            ),
          ),
        ],
      ),
      leading:    pathModel.image==null|| pathModel.image==""?
      const SizedBox(
        height: 70,
        width: 70,
        child: Icon(Icons.image,
            size: 40),
      )
          :   SizedBox(
          height: 70,
          width: 70,
          child: CircleAvatar(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10), // Adjust the radius according to your preference
              child: ImageBoxFillWidget(
                imageUrl: "${ApiContents.imageUrl}/${pathModel.image}",
                boxFit: BoxFit.fill,
              ),
            ),
          )
      ),
    );
  }
  _buildClinicCard(ClinicModel clinicModel){
    return ListTile(
      onTap: () async {
        await ClinicConfig.setActiveClinicId(clinicModel.id);
        Get.toNamed(RouteHelper.getClinicPageRoute(clinicId: clinicModel.id.toString()));
      },
      title: Text(clinicModel.title??"",
      style: TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 14
      ),
      ),
      subtitle:  Text(clinicModel.address??"",
        style: TextStyle(
          color: ColorResources.secondaryFontColor,
            fontWeight: FontWeight.w400,
            fontSize: 12
        ),
      ),
      leading:    clinicModel.image==null|| clinicModel.image==""?
      const SizedBox(
        height: 70,
        width: 70,
        child: Icon(Icons.image,
            size: 40),
      )
          :   SizedBox(
          height: 70,
          width: 70,
          child: CircleAvatar(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10), // Adjust the radius according to your preference
              child: ImageBoxFillWidget(
                imageUrl: "${ApiContents.imageUrl}/${clinicModel.image}",
                boxFit: BoxFit.fill,
              ),
            ),
          )
      ),
    );
  }
  _buildDoctorCard(DoctorsModel doctorsModel) {
    return  GestureDetector(
      onTap: ()async {
        SharedPreferences preferences = await SharedPreferences.getInstance();

        final loggedIn = preferences.getBool(SharedPreferencesConstants.login) ??false;
        final userId= preferences.getString(SharedPreferencesConstants.uid);
        if(loggedIn&&userId!=""&&userId!=null){
          Get.toNamed(RouteHelper.getDoctorsDetailsPageRoute(doctId: doctorsModel.id.toString()));
        }else{
          Get.to(()=>LoginPage(
              onSuccessLogin:  (){
            Get.toNamed(RouteHelper.getDoctorsDetailsPageRoute(doctId: doctorsModel.id.toString()));}));

        }
      },
      child:
      SizedBox(
        // width: 240,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                    flex:2,
                    child: Stack(
                      children: [
                        doctorsModel.image==null|| doctorsModel.image==""?
                        const SizedBox(
                          height: 70,
                          width: 70,
                          child: Icon(Icons.person,
                              size: 40),
                        )
                            :   SizedBox(
                            height: 70,
                            width: 70,
                            child: CircleAvatar(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10), // Adjust the radius according to your preference
                                child: ImageBoxFillWidget(
                                  imageUrl: "${ApiContents.imageUrl}/${doctorsModel.image}",
                                  boxFit: BoxFit.fill,
                                ),
                              ),
                            )
                        ),

                        const Positioned(
                          top: 5,
                          right: 0,
                          child:  CircleAvatar(backgroundColor: Colors.white,radius: 6,
                            child:CircleAvatar(backgroundColor: Colors.green,radius: 4),),
                        )
                      ],
                    )),
                const SizedBox(width: 10),
                Flexible(
                    flex:6,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                "${doctorsModel.fName??"--"} ${doctorsModel.lName??"--"}",
                                maxLines: 2, // Limit to 1 line
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12
                                ),),
                            ),
                          ],
                        ),
                        const SizedBox(height:2),
                        Text(doctorsModel.specialization??"",
                          maxLines: 1, // Limit to 1 line
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: ColorResources.secondaryFontColor,
                              fontWeight: FontWeight.w500,
                              fontSize: 12
                          ),),
                         const SizedBox(height: 2),
                        Row(
                          children: [
                            StarRating(
                              mainAxisAlignment: MainAxisAlignment.center,
                              length: 5,
                              color:  doctorsModel.averageRating==0?Colors.grey:Colors.amber,
                              rating: doctorsModel.averageRating??0,
                              between: 5,
                              starSize: 15,
                              onRaitingTap: (rating) {
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                            'rating_review_text'.trParams({
                        'rating': '${doctorsModel.averageRating ?? "--"}',
                        'count': '${doctorsModel.numberOfReview ?? 0}',
                        }),

                          style:const TextStyle(
                              color: ColorResources.secondaryFontColor,
                              fontWeight: FontWeight.w500,
                              fontSize: 12
                          ),)
                      ],))
              ],
            ),
          ],
        ),
      ),
    );
  }

  _buildDepartment() {
    return      Obx(() {
      if (!_departmentController.isError.value) { // if no any error
        if (_departmentController.isLoading.value) {
          return const IVerticalListLongLoadingWidget();
        } else if (_departmentController.dataList.isEmpty) {
          return  Container();
        } else {
          return
            _departmentController.dataList.length==1?Container(): _buildDepartmentBox(_departmentController.dataList);
        }
      }else {
        return Container();
      } //Error svg
    }
    );
  }

  _buildDoctor() {
    return   Obx(() {
      if (!_doctorsController.isError.value) { // if no any error
        if (_doctorsController.isLoading.value) {
          return const IVerticalListLongLoadingWidget();
        } else if (_doctorsController.dataList.isEmpty) {
          return  Padding(
            padding: const EdgeInsets.all(10.0),
            child:  Text('no_doctors_found_in'.trParams({'city': cityName ?? '--'}),
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500
            ),
            ),
          );
        } else {
          return _buildDoctorBox(_doctorsController.dataList);
        }
      }else {
        return Container();
      } //Error svg
    }
    );
  }

  /// Mirrors `medicare-user-web` Components/Clinics.jsx single-clinic logic:
  /// when exactly one clinic is in scope (env-configured or returned), embed
  /// the full ClinicPage (clinic detail + doctors below) instead of a carousel.
  Widget _buildClinicSection() {
    final ids = ClinicConfig.allowedClinicIds;
    final defaultId = ClinicConfig.defaultClinicId;
    if (ids.length == 1) {
      return ClinicPage(clinicId: ids.first.toString(), showAppBar: false);
    }
    if (ids.isEmpty && defaultId != null) {
      return ClinicPage(clinicId: defaultId.toString(), showAppBar: false);
    }
    return Obx(() {
      if (_clinicController.isError.value) return Container();
      if (_clinicController.isLoading.value) {
        return const IVerticalListLongLoadingWidget();
      }
      if (_clinicController.dataList.isEmpty) return Container();
      if (_clinicController.dataList.length == 1) {
        final id = _clinicController.dataList.first.id;
        if (id != null) {
          return ClinicPage(clinicId: id.toString(), showAppBar: false);
        }
      }
      return _buildClinicList(_clinicController.dataList);
    });
  }
  _buildPathologistLab() {
    return   Obx(() {
      if (!_pathologistController.isError.value) { // if no any error
        if (_pathologistController.isLoading.value) {
          return const IVerticalListLongLoadingWidget();
        } else if (_pathologistController.dataList.isEmpty) {
          return  Container();
        } else {
          return _buildPathLabList(_pathologistController.dataList);
        }
      }else {
        return Container();
      } //Error svg
    }
    );
  }

  void _requestNotificationPermission() {
    setState(() {
      _isLoading=true;
    });
    if (Platform.isAndroid) {
      FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
      flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();
    } else if (Platform.isIOS) {
      final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
      flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }

  void getAndSetData() async{
    setState(() {
      _isLoading=true;
    });
    _departmentController.getData();
    _doctorsController.getData("",cityId.toString());
    _clinicController.getData("0","10",cityId.toString());
    _pathologistController.getData("0","10",cityId.toString());
    final cityRes=await CityService.getData(search: "");

    if(cityRes!=null){
      _cityModelList=cityRes;
      filteredCities.addAll(_cityModelList);
    }
    final res=await NotificationSeenService.getDataById();
    if(res!=null){
      if(res.dotStatus==true){
        _notificationDotController.setDotStatus(true);
      }
    }
    String? playStoreLink;
    String? androidForceUpdateBoxEnable;
    String? androidAndroidAppVersion;
    String? androidUpdateBoxEnable;
    String? androidTechnicalIssueEnable;

    String? appStoreLink;
    String? iosForceUpdateBoxEnable;
    String? iosAppVersion;
    String? iosUpdateBoxEnable;
    String? iosTechnicalIssueEnable;


    final configRes=await ConfigurationService.getData();
    if(configRes!=null) {
      for (var e in configRes) {
        if(e.idName=="ai_health_assistant"){
          enableAiAssistant= e.value=="true"?true:false;
        }
        if(Platform.isAndroid){
          if (e.idName == "play_store_link") {
            playStoreLink = e.value;
          }
          if (e.idName == "android_technical_issue_enable") {
            androidTechnicalIssueEnable = e.value;
          }
          if (e.idName == "android_update_box_enable") {
            androidUpdateBoxEnable = e.value;
          }
          if (e.idName == "android_android_app_version") {
            androidAndroidAppVersion = e.value;
          }
          if (e.idName == "android_force_update_box_enable") {
            androidForceUpdateBoxEnable = e.value;
          }
        }
        if(Platform.isIOS){
          if (e.idName == "app_store_link") {
            appStoreLink = e.value;
          }
          if (e.idName == "ios_technical_issue_enable") {
            iosTechnicalIssueEnable = e.value;
          }
          if (e.idName == "ios_update_box_enable") {
            iosUpdateBoxEnable = e.value;
          }
          if (e.idName == "ios_app_version") {
            iosAppVersion = e.value;
          }
          if (e.idName == "ios_force_update_box_enable") {
            iosForceUpdateBoxEnable = e.value;
          }
        }

        // 💰 Currency settings (platform independent)
        if (e.idName == "currency_symbol") {
          Currency.currencySymbol = e.value??"₹";
        }
        if (e.idName == "currency_position") {
          Currency.currencyPosition = e.value??"Right"; // left / right
        }
        if (e.idName == "number_of_decimal") {
          Currency. currencyDecimal = int.parse(e.value??"2");
        }
        if (e.idName == "decimal_separator") {
          Currency.currencyDecimalSeparator = e.value??".";
        }
        if (e.idName == "thousand_separator") {
          Currency.currencyThousandSeparator = e.value??",";
        }
      }
    }
      //print("Currency -- ${Currency.currencySymbol}");

    if(Platform.isAndroid){
      // if(webSetting!=null){
        playStoreUrl=playStoreLink??"";
        if (kDebugMode) {
          print("Play store Url $playStoreUrl");
         }
    //}
      if(androidTechnicalIssueEnable!=null) {
        if (androidTechnicalIssueEnable== "true") {
          _openDialogIssueBox();
        } else {

          if(androidUpdateBoxEnable!=null){
            if(androidUpdateBoxEnable=="true"){

              if(androidAndroidAppVersion!=null){
                PackageInfo.fromPlatform().then((PackageInfo packageInfo)async {
                  String version = packageInfo.version;
                  if (kDebugMode) {
                    print("Version $version");
                    print("setting version $androidAndroidAppVersion");
                  }
                  if(version.toString()!=androidAndroidAppVersion.toString()){
                    if(androidForceUpdateBoxEnable!=null){
                      if(androidForceUpdateBoxEnable=="true"){
                        _openDialogSettingBox(false);
                      }else{
                        _openDialogSettingBox(true);
                      }
                    }
                  }
                }
                );
              }
            }

          }

        }
      }

    }else if(Platform.isIOS){

     // if(webSetting!=null){
        appStoreUrl=appStoreLink??"";
        if (kDebugMode) {
          print("app store Url $appStoreUrl");
        }
      //}
      if(iosTechnicalIssueEnable!=null) {
        if (iosTechnicalIssueEnable == "true") {
          _openDialogIssueBox();
        } else {
          if(iosUpdateBoxEnable!=null){
            if(iosUpdateBoxEnable=="true"){

              if(iosAppVersion!=null){
                PackageInfo.fromPlatform().then((PackageInfo packageInfo)async {
                  String version = packageInfo.version;
                  if (kDebugMode) {
                    print("Version Ios $version");
                    print("setting version Ios $iosAppVersion");
                  }
                  if(version.toString()!=iosAppVersion.toString()){
                    if(iosForceUpdateBoxEnable!=null){
                      if(iosForceUpdateBoxEnable=="true"){
                        _openDialogSettingBox(false);
                      }else{
                        _openDialogSettingBox(true);
                      }
                    }
                  }
                }
                );

              }
            }

          }
        }
      }
    }
    bannerImageList.clear();
    final resBanner=await BannerService.getData();
    if(resBanner!=null) {
      for(int i=0;i<resBanner.length;i++){
        bannerImageList.add("${ApiContents.imageUrl}/${resBanner[i].image??""}");
      }

    }

    _requestNotificationPermission();
    setState(() {
      _isLoading=false;
    });

    if (ClinicConfig.showBlog) {
      final resBlogPost=await BlogPostService.getData(start: 0, end: 5, isFeatured: true);
      if(resBlogPost!=null){
        setState(() {
          blogList=resBlogPost;
        });
      }
    }
  }
  _openDialogSettingBox(bool isCancel) {
    return showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        // return object of type Dialog
        return PopScope(
            canPop: isCancel,
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.0),
            ),
            title:  Text("update".tr,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 18
              ),),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(isCancel
                    ? "update_app_prompt_body_1".tr
                    : "update_app_prompt_body_2".tr,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontWeight: FontWeight.w400,
                        fontSize: 12
                    )),
                const SizedBox(height: 10),

              ],
            ),
            actions: <Widget>[
              isCancel ? ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorResources.greyBtnColor,
                  ),
                  child:  Text("cancel".tr,
                      style: const TextStyle(
                          fontWeight: FontWeight.w400,
                          fontSize: 12
                      )),
                  onPressed: () {
                    Navigator.of(context).pop();
                  }) : Container(),
              ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorResources.greenFontColor,
                  ),
                  child:  Text("update".tr,
                    style: TextStyle(
                        fontWeight: FontWeight.w400,
                        fontSize: 12
                    ),),
                  onPressed: () async {
                    // Navigator.of(context).pop();
                    if (Platform.isAndroid) {
                      if (playStoreUrl != "") {
                        try {
                          await launchUrl(Uri.parse(playStoreUrl),
                              mode: LaunchMode.externalApplication);
                        }
                        catch (e) {
                          if (kDebugMode) {
                            print(e);
                          }
                        }
                      }
                    } else if (Platform.isIOS) {
                      if (appStoreUrl != "") {
                        try {
                          await launchUrl(Uri.parse(appStoreUrl),
                              mode: LaunchMode.externalApplication);
                        }
                        catch (e) {
                          if (kDebugMode) {
                            print(e);
                          }
                        }
                      }
                    }
                  }),
              // usually buttons at the bottom of the dialog
            ],
          ),
        );
      },
    );
  }
  _openDialogIssueBox() {
    return showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        // return object of type Dialog
        return PopScope(
          canPop: false,
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.0),
            ),
            title:  Text("sorry!".tr,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 18
              ),),
            content:  Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                    "tech_issue_prompt_body".tr,
                    textAlign: TextAlign.center,
                    style:const TextStyle(
                        fontWeight: FontWeight.w400,
                        fontSize: 12
                    )),
                SizedBox(height: 10),

              ],
            ),
          ),
        );
      },
    );
  }


  _buildProfileSection() {
    return Padding(
      padding: const EdgeInsets.all(0.0),
      child: Container(
        padding: EdgeInsets.fromLTRB(10, 50, 10, 20),
        color: ColorResources.appBarColor,
        child:
        Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: ColorResources.bgColor,
                      child: Icon(Icons.person,
                        color: Colors.black,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                             Text("welcome!".tr,
                              style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                  fontSize: 14
                              ),),
                            const SizedBox(width: 3),
                            GestureDetector(
                              onTap: ()async{

                                SharedPreferences preferences = await SharedPreferences.getInstance();
                                final loggedIn = preferences.getBool(SharedPreferencesConstants.login) ??false;
                                final userId= preferences.getString(SharedPreferencesConstants.uid);
                                if(loggedIn&&userId!=""&&userId!=null){
                                  Get.toNamed(RouteHelper.getNotificationPageRoute());
                                }else{
                                  Get.to(()=>LoginPage(onSuccessLogin:  (){ Get.toNamed(RouteHelper.getNotificationPageRoute());}));
                                  // Get.toNamed(RouteHelper.getLoginPageRoute());
                                }
                              },
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Icon(
                                    Icons.notifications_none,
                                    color: Colors.white,
                                    size: 25,),
                                  Obx((){
                                    return _notificationDotController.isShow.value? const Positioned(
                                      top:0,
                                      right:0,
                                      child: Icon(Icons.circle,
                                        color: Colors.red,
                                        size: 10,
                                      ),
                                    ):Container();
                                  })


                                ],
                              ),
                            )
                          ],
                        ),
                        Row(
                          children: [
                            Obx((){
                              return      !userController.isLoading.value&&  userController.usersData.value.fName!=null? Text("${userController.usersData.value.fName}",
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16
                                ),): Text("user".tr,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16
                                ),);
                            }),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),

                Row(
                  children: [
                    GestureDetector(
                      onTap: (){
                        _openBottomSheetSearchCity();
                      },
                      child: Row(
                        children: [
                          Text(cityName??"--",
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                                fontSize: 16
                            ),
                          ),
                        const SizedBox(width: 10),
                        Icon(Icons.location_on,
                          color: Colors.white,
                        )
                        ],
                      ),
                    ),
                  ],
                )

              ],
            ),
            const SizedBox(height: 15),
            ISearchBox.buildSearchBoxOnTap(
                textEditingController: null,
                labelText: "search.....".tr,
                onTap:(){
                  _onItemTapped(2);
                //  _requestLocationPermission();
                //  _clinicController.getData("0","5",cityId.toString());
                }
            ),
          ],
        ),
      )
    );
  }

  void _requestLocationPermissionCurrentLocation() async{


    loc.Location location =  loc.Location();
    bool serviceEnabled = await location.serviceEnabled();

    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        if (kDebugMode) {
          print("Location services are disabled.");
        }
        return;
      }
    }

    loc.PermissionStatus permissionGranted = await location.hasPermission();
    double? lat;
    double? long;
    if (kDebugMode) {
      print("Location Permission status $permissionGranted");
    }
    if (permissionGranted == loc.PermissionStatus.granted) {
      setState(() {
        _isLoading=true;
      });
      // Get the user's current location
      loc.LocationData locationData = await location.getLocation();
      lat=locationData.latitude;
      long=locationData.longitude;

      final res=await CityService.getLocationData(lat: lat?.toString()??"",lng:long?.toString()??"" );
      setState(() {
        _isLoading=false;
      });
      cityId=res['city_id']?.toString();
      cityName=res['city']?.toString();
      _searchTextController.text=cityName??"";
      SharedPreferences sharedPreferences=await SharedPreferences.getInstance();
      sharedPreferences.setString("city_id", cityId??"");
      sharedPreferences.setString("city", cityName??"");
      _persistActiveClinicId(sharedPreferences, fromCity: res['clinic_id']);
      _doctorsController.getData("",cityId.toString());
      _clinicController.getData("0","5",cityId.toString());
      _pathologistController.getData("0","5",cityId.toString());
      setState((){});
    }else{
      _showPermissionDialog();
    }

  }
  void _showPermissionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,  // Prevent dialog from closing by tapping outside
      builder: (BuildContext context) => AlertDialog(
        title:  Text(
            'location_permission_required'.tr,
          style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold),
        ),
        content:  Text(
          'location_permission_description'.tr,
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text("cancel".tr, style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.settings, size: 20),
            label:  Text("open_settings".tr),
            onPressed: () {
              AppSettings.openAppSettings();
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }
  void _requestLocationPermission() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();

    cityName = sharedPreferences.getString("city") ?? "";
    cityId = sharedPreferences.getString("city_id") ?? "";

    if (cityName != null && cityName != "" && cityId != null && cityId != "") {
      getAndSetData();
      return;
    }

    loc.Location location = loc.Location();
    bool serviceEnabled = await location.serviceEnabled();

    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        if (kDebugMode) {
          print("Location services are disabled.");
        }
        getAndSetData();
        return;
      }
    }

    loc.PermissionStatus permissionGranted = await location.hasPermission();
    double? lat;
    double? long;

    if (kDebugMode) {
      print("Location Permission status $permissionGranted");
    }

    if (permissionGranted == loc.PermissionStatus.granted) {
      loc.LocationData locationData = await location.getLocation();
      lat = locationData.latitude;
      long = locationData.longitude;
    }

    final res = await CityService.getLocationData(
      lat: lat?.toString() ?? "",
      lng: long?.toString() ?? "",
    );

    cityId = res['city_id']?.toString();
    cityName = res['city']?.toString();

    sharedPreferences.setString("city_id", cityId ?? "");
    sharedPreferences.setString("city", cityName ?? "");
    _persistActiveClinicId(sharedPreferences, fromCity: res['clinic_id']);

    getAndSetData();
  }

  void _persistActiveClinicId(
    SharedPreferences prefs, {
    Object? fromCity,
  }) {
    if (!ClinicConfig.hasClinicFilter) return;
    int? resolved;
    if (fromCity is int) {
      resolved = fromCity;
    } else if (fromCity is String) {
      resolved = int.tryParse(fromCity);
    }
    resolved ??= ClinicConfig.defaultClinicId;
    if (resolved == null && ClinicConfig.allowedClinicIds.isNotEmpty) {
      resolved = ClinicConfig.allowedClinicIds.first;
    }
    if (resolved != null) {
      prefs.setString(
        SharedPreferencesConstants.clinicId,
        resolved.toString(),
      );
    }
  }

  _openBottomSheetSearchCity() {
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
                return FractionallySizedBox(
                  heightFactor: 0.9, // Adjust this factor to control the height (e.g., 0.7 = 70% of screen height)
                  child: Padding(
                    padding: MediaQuery
                        .of(context)
                        .viewInsets,
                    child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Stack(
                          // controller: _bottomSheetScrollController,
                          children: [
                            ISearchBox.buildSearchBox(
                                textEditingController: _searchTextController,
                                labelText: "search_city".tr,
                                onChanged:(){
                                  filterCities(_searchTextController.text,setState);
                                },
                                suffixIcon: IconButton(
                                  onPressed: (){
                                    Get.back();
                                    _requestLocationPermissionCurrentLocation();
                                  },
                                  icon: Icon(Icons.my_location,
                                    size: 20,
                                  ),
                                )
                            ),
                            Positioned(
                              top: 50,
                              left: 0,
                              right: 0,
                              bottom: 0,
                              child:  filteredCities.isEmpty?
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child:  Text("no_data_found!".tr),
                              ): ListView.builder(
                                  controller: _bottomSheetScrollController,
                                  shrinkWrap: true,
                                  itemCount:filteredCities.length,
                                  itemBuilder: (context,index){
                                    CityModel cityMode=filteredCities[index];
                                    return Card(
                                      color:  ColorResources.cardBgColor,
                                      elevation: .1,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(5.0),
                                      ),
                                      child: ListTile(
                                          onTap: ()async {
                                            Get.back();
                                            cityId=cityMode.id.toString();
                                            cityName="${cityMode.title}";
                                            _searchTextController.text="${cityMode.title},${cityMode.stateTitle}";
                                            SharedPreferences sharedPreferences=await SharedPreferences.getInstance();
                                            sharedPreferences.setString("city_id", cityId??"");
                                            sharedPreferences.setString("city", cityName??"");
                                            _persistActiveClinicId(sharedPreferences, fromCity: cityMode.clinicId);
                                            _doctorsController.getData("",cityId.toString());
                                            _clinicController.getData("0","5",cityId.toString());
                                            _pathologistController.getData("0","5",cityId.toString());

                                            this.setState((){});
                                          },
                                          title: Text("city_state".trArgs([cityMode.title??"", cityMode.stateTitle??""]),
                                            style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500
                                            ),
                                          )),
                                    );
                                  }
                              ),
                            )
                          ],
                        )
                    ),
                  ),
                );
              }
          );
        },

      ).whenComplete(() {

      });
  }
  void filterCities(String query,setState) {
    if (query.isEmpty) {
      setState(() {
        filteredCities = _cityModelList;
      });
    } else {
      setState(() {
        filteredCities = _cityModelList
            .where((city) =>
        city.title!.toLowerCase().contains(query.toLowerCase()) ||
            city.stateTitle!.toLowerCase().contains(query.toLowerCase()))
            .toList();
      });
    }
  }
  Future <bool> getLoginDetails() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    final loggedIn = preferences.getBool(SharedPreferencesConstants.login) ??
        false;
    final userId = preferences.getString(SharedPreferencesConstants.uid);
    if (loggedIn && userId != "" && userId != null) {
      return true;
    } else {
      return false;
    }
  }
  _buildBlogList() {
    return Card(
      elevation: .1,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(5.0),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(5),
        title:   Padding(
            padding:const EdgeInsets.only(bottom: 10.0),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children:[
                  Text('blog_post'.tr,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14
                    ),),
                  GestureDetector(
                    onTap: (){
                     Get.toNamed(RouteHelper.getBlogListPageRoute());
                    },
                    child:   Text('view_all'.tr,
                      style:TextStyle(
                          color: ColorResources.btnColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 14
                      ),),
                  ),
                ]
            )
        ),
        subtitle:   Padding(
          padding: const EdgeInsets.only(top:10.0),
          child: ListView.builder(
              padding: const EdgeInsets.all(0),
              controller: _scrollController,
              // physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: blogList.length<=5?blogList.length:5,
              itemBuilder: (context,index){
                return   _buildBlogPost(blogList[index]);
              }),
        ),

      ),
    );
  }
  _buildBlogPost(BlogPostModel blogPostModel){
    return ListTile(
      onTap: (){
        Get.toNamed(RouteHelper.getBlogDetailsPageRoute(id: blogPostModel.id.toString()));
      },
      title: Text(blogPostModel.title??"",
        style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14
        ),
      ),
      subtitle:  Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(blogPostModel.description??"",
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                color: ColorResources.secondaryFontColor,
                fontWeight: FontWeight.w400,
                fontSize: 12
            ),
          ),

          Padding(
            padding: const EdgeInsets.only(top:3.0),
            child: Text(blogPostModel.catTitle??"",
              style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 12
              ),
            ),
          ),
        ],
      ),
      leading:    blogPostModel.image==null|| blogPostModel.image==""?
      const SizedBox(
        height: 70,
        width: 70,
        child: Icon(Icons.image,
            size: 40),
      )
          :   SizedBox(
          height: 70,
          width: 70,
          child: CircleAvatar(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10), // Adjust the radius according to your preference
              child: ImageBoxFillWidget(
                imageUrl: "${ApiContents.imageUrl}/${blogPostModel.image}",
                boxFit: BoxFit.fill,
              ),
            ),
          )
      ),
    );
  }
  Widget aiDoctorSuggestionCard() {
    return GestureDetector(
      onTap: () {
        Get.toNamed(RouteHelper.getAiChatPageRoute());
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: ColorResources.cardGradientColor,
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.25),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            // AI Icon
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.smart_toy,
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            // Text Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children:  [
                  Text(
                    "talk_with_ai".tr,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    "ai_chat_card_desc".trParams({"city":cityName??"--"}),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

}
