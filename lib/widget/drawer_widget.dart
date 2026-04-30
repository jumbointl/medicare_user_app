import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../languages/language_storage_helper.dart';
import '../languages/translation.dart';
import '../model/language_model.dart';
import '../pages/edit_profile_page.dart';
import '../services/user_service.dart';
import '../services/user_subscription.dart';
import '../controller/user_controller.dart';
import '../languages/version_control.dart';
import '../pages/auth/login_page.dart';
import 'package:get/get.dart';
import '../utilities/api_content.dart';
import '../utilities/clinic_config.dart';
import '../utilities/image_constants.dart';
import '../widget/toast_message.dart';
import '../controller/notification_dot_controller.dart';
import '../helpers/date_time_helper.dart';
import '../helpers/route_helper.dart';
import '../utilities/colors_constant.dart';
import '../utilities/sharedpreference_constants.dart';
import 'image_box_widget.dart';

class IDrawerWidget{

  buildDrawerWidget( UserController userController,NotificationDotController notificationDotController,bool enableAiAssistant){
    return Drawer(
      backgroundColor: Colors.white,
      child: ListView(
        padding: const EdgeInsets.all(8),
        children: [
          const SizedBox(height: 40),
          _buildProfileSection(userController),
          _buildLanguageButton(),
          const SizedBox(height: 20),
          Divider(),
          const SizedBox(height: 10),
          _buildCardBox("profile".tr,Icons.person,()async{
            Get.back();
            SharedPreferences preferences = await SharedPreferences.getInstance();
            final loggedIn = preferences.getBool(SharedPreferencesConstants.login) ??false;
            final userId= preferences.getString(SharedPreferencesConstants.uid);
            if(loggedIn&&userId!=""&&userId!=null){

              Get.toNamed(RouteHelper.getEditUserProfilePageRoute());
            }else{

              Get.to(
                    () => LoginPage(
                  onSuccessLogin: () {
                    Get.back();
                    Get.to(() => const EditProfilePage(autoCloseSeconds: 0));
                  },
                ),
              );
            }

          }),
          enableAiAssistant? _buildCardBox("ai_health_assistant".tr,Icons.psychology,()async{
            Get.back();
            Get.toNamed(RouteHelper.getAiChatPageRoute());

          }):Container(),

          _buildCardBox("family_members".tr,Icons.people,()async{
            Get.back();
            SharedPreferences preferences = await SharedPreferences.getInstance();

            final loggedIn = preferences.getBool(SharedPreferencesConstants.login) ??false;
            final userId= preferences.getString(SharedPreferencesConstants.uid);
            if(loggedIn&&userId!=""&&userId!=null){
              Get.toNamed(RouteHelper.getFamilyMemberListPageRoute());
            }else{
              Get.to(()=>LoginPage(onSuccessLogin:  (){ Get.toNamed(RouteHelper.getFamilyMemberListPageRoute());}));
            }

          }),

          _buildCardBox("appointment_booking".tr,Icons.history,()async{
            Get.back();
            SharedPreferences preferences = await SharedPreferences.getInstance();

            final loggedIn = preferences.getBool(SharedPreferencesConstants.login) ??false;
            final userId= preferences.getString(SharedPreferencesConstants.uid);
            if(loggedIn&&userId!=""&&userId!=null){
              Get.toNamed(RouteHelper.getMyBookingPageRoute());
            }else{
              Get.to(()=>LoginPage(onSuccessLogin:  (){ Get.toNamed(RouteHelper.getMyBookingPageRoute());}));
            }
          }),
          if (ClinicConfig.showLab) _buildCardBox("lab_booking".tr,Icons.history,()async{
            Get.back();
            SharedPreferences preferences = await SharedPreferences.getInstance();

            final loggedIn = preferences.getBool(SharedPreferencesConstants.login) ??false;
            final userId= preferences.getString(SharedPreferencesConstants.uid);
            if(loggedIn&&userId!=""&&userId!=null){
              Get.toNamed(RouteHelper.getLabBookingHistoryPageRoute());
            }else{
              Get.to(()=>LoginPage(onSuccessLogin:  (){ Get.toNamed(RouteHelper.getLabBookingHistoryPageRoute());}));
            }
          }),
          _buildCardBox("vitals".tr,Icons.bloodtype_outlined,()async{
            Get.back();
            SharedPreferences preferences = await SharedPreferences.getInstance();

            final loggedIn = preferences.getBool(SharedPreferencesConstants.login) ??false;
            final userId= preferences.getString(SharedPreferencesConstants.uid);
            if(loggedIn&&userId!=""&&userId!=null){
              Get.toNamed(RouteHelper.getVitalsPageRoute());
            }else{
              Get.to(()=>LoginPage(onSuccessLogin:  (){ Get.toNamed(RouteHelper.getVitalsPageRoute());}));
            }

          }),
          _buildCardBox("prescription".tr,Icons.file_copy,()async{
            Get.back();
            SharedPreferences preferences = await SharedPreferences.getInstance();

            final loggedIn = preferences.getBool(SharedPreferencesConstants.login) ??false;
            final userId= preferences.getString(SharedPreferencesConstants.uid);
            if(loggedIn&&userId!=""&&userId!=null){
              Get.toNamed(RouteHelper.getPrescriptionListPageRoute());
            }else{
              Get.to(()=>LoginPage(onSuccessLogin:  (){ Get.toNamed(RouteHelper.getPrescriptionListPageRoute());}));
            }

          }),
          _buildCardBox("files".tr,Icons.file_copy,()async{
            Get.back();
            SharedPreferences preferences = await SharedPreferences.getInstance();

            final loggedIn = preferences.getBool(SharedPreferencesConstants.login) ??false;
            final userId= preferences.getString(SharedPreferencesConstants.uid);
            if(loggedIn&&userId!=""&&userId!=null){
              Get.toNamed(RouteHelper.getPatientFilePageRoute());
            }else{
              Get.to(()=>LoginPage(onSuccessLogin:  (){ Get.toNamed(RouteHelper.getPatientFilePageRoute());}));
            }

          }),

          _buildNotificationCardBox(notificationDotController,"notification".tr,Icons.notifications,()async{
            Get.back();
            SharedPreferences preferences = await SharedPreferences.getInstance();
            final loggedIn = preferences.getBool(SharedPreferencesConstants.login) ??false;
            final userId= preferences.getString(SharedPreferencesConstants.uid);
            if(loggedIn&&userId!=""&&userId!=null){
              Get.toNamed(RouteHelper.getNotificationPageRoute());
            }else{
              Get.to(()=>LoginPage(onSuccessLogin:  (){ Get.toNamed(RouteHelper.getNotificationPageRoute());}));
            }


          }),

          _buildCardBox("wallet".tr,Icons.wallet,()async{
            Get.back();
            SharedPreferences preferences = await SharedPreferences.getInstance();
            final loggedIn = preferences.getBool(SharedPreferencesConstants.login) ??false;
            final userId= preferences.getString(SharedPreferencesConstants.uid);
            if(loggedIn&&userId!=""&&userId!=null){
              Get.toNamed(RouteHelper.getWalletPageRoute());
            }else{
              Get.to(()=>LoginPage(onSuccessLogin:  (){ Get.toNamed(RouteHelper.getWalletPageRoute());}));

            }


          }),
          _buildCardBox("contact_us".tr,Icons.support_agent,(){
            Get.back();
            Get.toNamed(RouteHelper.getContactUsPageRoute());

          }),
          _buildCardBox("share".tr,Icons.share,(){
            Get.back();
            Get.toNamed(RouteHelper.getShareAppPageRoute());
          }),
          const Divider(),
          _buildCardBox("testimonials".tr,Icons.book,(){
            Get.back();
            Get.toNamed(RouteHelper.getTestimonialPageRoute());
          }),
          const Divider(),
          _buildCardBox("about_us".tr,Icons.info,(){
            Get.back();
            Get.toNamed(RouteHelper.getAboutUsPageRoute());
          }),
          _buildCardBox("privacy_policy".tr,Icons.link,()async{
            Get.back();
            Get.toNamed(RouteHelper.getPrivacyPagePageRoute());
          }),
          _buildCardBox("terms_condition".tr,Icons.link,()async {
            Get.back();
            Get.toNamed(RouteHelper.getTermCondPageRoute());
          }),
          const Divider(),
          _buildLogOutBtn(userController),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: FutureBuilder(
                future: VersionControl.getVersionName(),
                builder: (context, snapshot) {
                  return Text("app_version".trParams({'vnumber': "${snapshot.data}"}),
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500
                    ),);
                }
            ),
          )
        ],
      ),
    );
  }

  static _buildProfileSection(UserController userController) {
    return Obx(() {
      if (!userController.isError.value) { // if no any error
        if (userController.isLoading.value) {
          return const Text("--");
        } else {
          return  SizedBox(
            height: 140,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SizedBox(
                      height: 70,
                      width: 70,
                      child: ClipOval(
                          child:
                          userController.usersData.value.imageUrl==null||userController.usersData.value.imageUrl==""?
                          const Icon(Icons.person,
                            size: 50,):
                          ImageBoxFillWidget(imageUrl:"${ApiContents.imageUrl}/${userController.usersData.value.imageUrl}") ),
                    ),
                    Row(
                        children:[
                          Image.asset(ImageConstants.crownImage,
                              width: 40,
                              height: 20),
                          Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            color: ColorResources.containerBgColor,
                            child:   Padding(
                              padding: EdgeInsets.all(5.0),
                              child: Text("member".tr,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14
                                ),),
                            ),
                          )
                        ]

                    )
                  ],
                ),
                const SizedBox(height: 20),
                Text("hello_user".trParams({"uname":userController.usersData.value.fName??"--"}),
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600
                  ),),
                Text("membership_since_date".trParams({"dates":DateTimeHelper.getDataFormat(userController.usersData.value.createdAt)}),
                  style:const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400
                  ),),

              ],
            ),
          );
        }
      }else {
        return Padding(
            padding: const EdgeInsets.fromLTRB(0,0,0,0),
            child:  ListTile(
              onTap:()async {
                Get.back();
                SharedPreferences preferences = await SharedPreferences.getInstance();
                final loggedIn = preferences.getBool(SharedPreferencesConstants.login) ??false;
                final userId= preferences.getString(SharedPreferencesConstants.uid);
                if(loggedIn&&userId!=""&&userId!=null){
                  Get.toNamed(RouteHelper.getEditUserProfilePageRoute());
                }else{

                  Get.to(
                        () => LoginPage(
                      onSuccessLogin: () {
                        Get.back();
                        Get.to(() => const EditProfilePage(autoCloseSeconds: 0));
                      },
                    ),
                  );
                }
              },
              leading: const Icon(Icons.person),
              title:     Text("login/signup".tr,
                style:const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400
                ),),
            )

        );
      } //Error svg
    }
    );
  }

  static _buildCardBox(String title,IconData icon,onPressed,[selected]) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        decoration:  BoxDecoration(
          color:selected??false?ColorResources.primaryColor:null,
          borderRadius: const BorderRadius.all(
              Radius.circular(5.0) //                 <--- border radius here
          ),
        ),

        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 8, 20),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                Icon(icon,size: 20,
                  color: selected??false?Colors.white:Colors.grey,),
                const SizedBox(width:20),
                Text(title,
                  style:  TextStyle(
                      color: selected??false?Colors.white:Colors.black,
                      fontWeight: FontWeight.w400,
                      fontSize: 14
                  ),),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static _buildNotificationCardBox(NotificationDotController notificationDotController,String title,IconData icon,onPressed,[selected]) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        decoration:  BoxDecoration(
          color:selected??false?ColorResources.primaryColor:null,
          borderRadius: const BorderRadius.all(
              Radius.circular(5.0) //                 <--- border radius here
          ),
        ),

        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 8, 20),
          child: Row(
            children: [
              Stack(
                children: [
                  Icon(icon,size: 20,
                    color: selected??false?Colors.white:Colors.grey,),
                  Obx((){
                    return  notificationDotController.isShow.value?  const Icon(
                      Icons.circle,
                      size: 10,
                      color: Colors.red,
                    ):Container();
                  })
                ],
              ),
              const SizedBox(width:20),
              Text(title,
                style:  TextStyle(
                    color: selected??false?Colors.white:Colors.black,
                    fontWeight: FontWeight.w400,
                    fontSize: 14
                ),),
            ],
          ),
        ),
      ),
    );
  }

  static _buildLogOutBtn(UserController userController) {
    return Obx(() {
      if (!userController.isError.value) { // if no any error
        if (userController.isLoading.value) {
          return  Container();
        } else {
          return  _buildCardBox("logout".tr,Icons.power_settings_new,()async{
            final res= await UserService.logOutUser();
            if(res!=null){
              SharedPreferences prefs=await SharedPreferences.getInstance();
              prefs.clear();
              IToastMsg.showMessage("logout".tr);
              final NotificationDotController notificationDotController=Get.find(tag: "notification_dot");
              final   UserController userController0=Get.find(tag: "user");
              userController0.getData();
              notificationDotController.setDotStatus(false);
              Get.offAllNamed(RouteHelper.getHomePageRoute());
              UserSubscribe.deleteToTopi(topicName: "PATIENT_APP");
            }

          });
        }
      }else {
        return Container();
      } //Error svg
    }
    );
  }


  Widget _buildLanguageButton() {
    return FutureBuilder<List<LanguageModel>>(
      future: LanguageStorage.getLanguages(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Container();
        }

        final languages = snapshot.data!;
        final currentTag = Get.locale?.toLanguageTag();

        String currentTitle = 'Language';

        for (final lang in languages) {
          final code = lang.code ?? '';
          if (code.isNotEmpty &&
              currentTag == LocaleHelper.parse(code).toLanguageTag()) {
            currentTitle = lang.title ?? code;
            break;
          }
        }

        return _buildCardBox(
          'Language: $currentTitle',
          Icons.language,
              () {
            Get.back();
            Get.toNamed(RouteHelper.getLanguagePageRoute());
          },
        );
      },
    );
  }




}