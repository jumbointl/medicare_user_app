import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:star_rating/star_rating.dart';
import 'package:url_launcher/url_launcher.dart';
import '../model/clinic_model.dart';
import '../model/testimonial_model.dart';
import '../services/clinic_service.dart';
import '../services/doctor_service.dart';
import '../services/testimonial_service.dart';
import '../widget/app_bar_widget.dart';
import '../widget/appointment_only_back_guard.dart';
import '../widget/loading_Indicator_widget.dart';

import '../helpers/route_helper.dart';
import '../model/doctors_model.dart';
import '../services/configuration_service.dart';
import '../utilities/api_content.dart';
import '../utilities/clinic_config.dart';
import '../utilities/colors_constant.dart';
import '../utilities/image_constants.dart';
import '../utilities/sharedpreference_constants.dart';
import '../widget/button_widget.dart';
import '../widget/carousel_widget.dart';
import '../widget/image_box_widget.dart';
import 'package:get/get.dart';

import 'auth/login_page.dart';

class ClinicPage extends StatefulWidget {
  final String? clinicId;
  final bool showAppBar;
  const ClinicPage({super.key,this.clinicId,this.showAppBar=true});

  @override
  State<ClinicPage> createState() => _ClinicPageState();
}

class _ClinicPageState extends State<ClinicPage> {
  bool stopBooking =false;
  bool _isLoading=false;
  ClinicModel? clinicModel;
  List<DoctorsModel> listDoctorModel=[];
  List<TestimonialModel> listTestimonials=[];
  final ScrollController _scrollController=ScrollController();
  List <String> clinicImages=[];
    @override
  void initState() {
    // TODO: implement initState
    // Persist whichever clinic the user is currently viewing as the runtime
    // clinic_id. Catches every path into ClinicPage (list tap, home card,
    // doctor-details clinic info, deep links, embedded mode). Downstream
    // services pick this up via ClinicConfig.applyTo() / defaultClinicId.
    final cid = int.tryParse(widget.clinicId ?? '');
    if (cid != null && cid > 0) {
      ClinicConfig.setActiveClinicId(cid);
    }
    getAndSetData();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final body = _isLoading || clinicModel == null
        ? ILoadingIndicatorWidget()
        : _buildBody();
    if (!widget.showAppBar) {
      return AppointmentOnlyBackGuard(child: body);
    }
    return AppointmentOnlyBackGuard(
      child: Scaffold(
        appBar: IAppBar.commonAppBar(title: clinicModel?.title ?? "clinic".tr),
        drawer: appointmentOnlyDrawer(),
        body: body,
      ),
    );
  }

  void getAndSetData() async{
  setState(() {
    _isLoading=true;
  });
final res=await ClinicService.getDataById(clinicId: widget.clinicId);
if(res!=null){
  clinicModel=res;
}
if(clinicModel?.clinicImages!=null){
  for(int i =0;i<clinicModel!.clinicImages!.length;i++){
    clinicImages.add("${ApiContents.imageUrl}/${clinicModel!.clinicImages?[i]['image']??""}");
  }
}

  
  final resConfig=await ConfigurationService.getDataById(idName: "stop_booking");
  if(resConfig!=null){
    if(resConfig.value=="true"){
      stopBooking=true;
    }
  }
  setState(() {
    _isLoading=false;
  });
    final resList=await DoctorsService.getDataByClinicId(clinicId: widget.clinicId.toString());
    if(resList!=null&&resList.isNotEmpty){
      setState(() {
        listDoctorModel=resList;
      });
    }
  final resTest=await TestimonialsService.getData( widget.clinicId.toString(),"");
  if(resTest!=null&&resTest.isNotEmpty){
    setState(() {
      listTestimonials=resTest;
    });
  }
  }

  _buildBody() {
  final embedded = !widget.showAppBar;
  return ListView(
    controller: embedded ? null : _scrollController,
    shrinkWrap: embedded,
    physics: embedded ? const NeverScrollableScrollPhysics() : null,
    padding: EdgeInsets.all(5),
    children: [
    buildImageSection(),
    _buildClinicListTile(),
      _buildContactCard(),
      _buildDescBox(),
      _buildDescTimeBox(),
      listTestimonials.isEmpty?Container(): _buildTestimonialBox(),
      _buildDrList()
    ],
  );
  }

  Widget buildTimingWidget(Map<String, String> schedule) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: schedule.entries.map((entry) {
        final day = entry.key[0].toUpperCase() + entry.key.substring(1); // Capitalize day
        return ListTile(
          title: Text(
            day,
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500),
          ),
          trailing: Text(entry.value,
          style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400
          ),
          ),
        );
      }).toList(),
    );
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
              clinicModel?.phone==null|| clinicModel?.phone==""?Container(): _buildTapBox(ImageConstants.telephoneImageBox, "call".tr,()async{
                if( clinicModel?.phone!=null&& clinicModel?.phone!=""){
                  await launchUrl(Uri.parse("tel:${ clinicModel?.phone}"));
                }
              }),
              clinicModel?.whatsapp==null|| clinicModel?.whatsapp==""?Container():   Padding(padding: const EdgeInsets.only(left: 20),
                  child:      _buildTapBox(ImageConstants.whatsappImageBox, "whatsapp".tr,()async{
                    if( clinicModel?.whatsapp!=null&& clinicModel?.whatsapp!=""){
                      final url = "https://wa.me/${ clinicModel?.whatsapp}?text=Hello"; //remember country code
                      await launchUrl(Uri.parse(url),
                          mode: LaunchMode.externalApplication
                      );
                    }

                  })
              ),

              clinicModel?.email==null|| clinicModel?.email==""?Container():   Padding(padding: const EdgeInsets.only(left: 20),
                child:  _buildTapBox(ImageConstants.emailImageBox, "email".tr,()async{
                  if( clinicModel?.email!=null&& clinicModel?.email!=""){
                    await launchUrl(Uri.parse("mailto:${ clinicModel?.email}"));
                  }

                }),
              ),

              clinicModel?.longitude==null|| clinicModel?.latitude==null?Container():  Padding(padding: const EdgeInsets.only(left: 20),
                child:     _buildTapBox(ImageConstants.mapPlaceImageBox, "map".tr,()async{
                  if(clinicModel?.longitude!=null&&clinicModel?.latitude!=null){
                    final url="http://maps.google.com/maps?daddr=${clinicModel?.latitude},${clinicModel?.longitude}";
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
            clinicModel?.ambulanceNumber==null||clinicModel?.ambulanceNumber==""?Container():  clinicModel?.ambulanceBtnEnable==1?  Flexible(
                child: Padding(padding: const EdgeInsets.only(left: 20),
                  child: _buildTapBox(ImageConstants.ambulanceImageBox, "ambulance".tr,()async{
                    if(clinicModel?.ambulanceNumber!=null&&clinicModel?.ambulanceNumber!=""){
                      await launchUrl(Uri.parse("tel:${clinicModel?.ambulanceNumber}"));
                    }

                  }),
                ),
              ):Container()


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
  _buildClinicListTile() {
  return   Card(
    elevation: .1,
    color: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10.0),
    ),
    child: ListTile(
      leading:    clinicModel?.image==null|| clinicModel?.image==""?
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
                imageUrl: "${ApiContents.imageUrl}/${clinicModel?.image}",
                boxFit: BoxFit.fill,
              ),
            ),
          )
      ),
      title: Text(
        clinicModel?.title??"",
        style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500
        ),
      ),
      subtitle: Text(
        clinicModel?.address??"",
        style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w400
        ),
      ),
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

  _buildDrList() {
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
            child:     Text("doctors".tr,
              style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14
              ),),
        ),
        subtitle:   Padding(
          padding: const EdgeInsets.only(top:10.0),
          child:  ListView.builder(
              controller: _scrollController,
              shrinkWrap: true,
              itemCount: listDoctorModel.length,
              itemBuilder: (context,index){
                DoctorsModel doctorsModel=listDoctorModel[index];
                return
                  Padding(
                    padding: const EdgeInsets.only(top:3.0),
                    child: Card(
                      color:  ColorResources.cardBgColor,
                      elevation: .1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child:
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                    flex:2,
                                    child: Stack(
                                      children: [
                                        doctorsModel.image==null|| doctorsModel.image==""? const CircleAvatar(
                                          backgroundColor: Colors.white,
                                          radius: 30,
                                          child: Icon(Icons.person,
                                            size: 40,),
                                        ):   ClipOval(child:
                                        SizedBox(
                                          height: 70,
                                          width: 70,
                                          child: CircleAvatar(child:ImageBoxFillWidget(
                                            imageUrl:
                                            "${ApiContents.imageUrl}/${doctorsModel.image}",
                                            boxFit: BoxFit.fill,
                                          )),
                                        ),
                                        ),

                                        const Positioned(
                                          top: 5,
                                          right: 0,
                                          child:  CircleAvatar(backgroundColor: Colors.white,radius: 8,
                                            child:CircleAvatar(backgroundColor: Colors.green,radius: 6),),
                                        )
                                      ],
                                    )),
                                const SizedBox(width: 20),
                                Flexible(
                                    flex:6,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Flexible(
                                              child: Text("full_name".trArgs([doctorsModel.fName??"--", doctorsModel.lName??"--"]),
                                                style: const TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 16
                                                ),),
                                            ),
                                            Image.asset(ImageConstants.playImage,height: 24,
                                              width: 24,)
                                          ],
                                        ),
                                        const SizedBox(height:2),
                                        Text(doctorsModel.specialization??"",
                                          style: const TextStyle(
                                              color: ColorResources.secondaryFontColor,
                                              fontWeight: FontWeight.w500,
                                              fontSize: 12
                                          ),),
                                        const SizedBox(height: 10),
                                        Row(
                                          children:[
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
                                            const  SizedBox(width: 10),
                                            Text(
                                              'rating_review_text'.trParams({
                                                'rating': '${doctorsModel.averageRating ?? "--"}',
                                                'count': '${doctorsModel.numberOfReview ?? 0}',
                                              }),
                                              style: const TextStyle(
                                                  color: ColorResources.secondaryFontColor,
                                                  fontWeight: FontWeight.w500,
                                                  fontSize: 12
                                              ),)
                                          ],
                                        ),

                                        const SizedBox(height: 10),
                                        Row(
                                          children:[
                                            const  Icon(FontAwesomeIcons.briefcase,color: ColorResources.iconColor,size: 15),
                                            const  SizedBox(width: 5),
                                            Text("experience_year".trParams({'count':  "${doctorsModel.exYear??"--"}"}),
                                              style:const TextStyle(
                                                  color: ColorResources.secondaryFontColor,
                                                  fontWeight: FontWeight.w500,
                                                  fontSize: 12
                                              ),)],
                                        ),
                                        doctorsModel.stopBooking==1?   Padding(
                                          padding:const EdgeInsets.only(top:10.0),
                                          child: Row(
                                            children:[
                                              Icon(Icons.warning_amber_rounded,color: ColorResources.redColor,size: 15),
                                              SizedBox(width: 5),
                                              Text("current_not_accepting_appointment".tr,
                                                style:const TextStyle(
                                                    color: ColorResources.redColor,
                                                    fontWeight: FontWeight.w500,
                                                    fontSize: 12
                                                ),)],
                                          ),
                                        ):Container()
                                      ],))
                              ],
                            ),
                            const SizedBox(height: 10),
                            const Divider(),
                            Row(
                              children: [
                                Icon(FontAwesomeIcons.hospital,
                                  size: 15,
                                ),
                                const SizedBox(width: 10),
                                Text(doctorsModel.clinicTitle??"--",
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontSize: 13,
                                        color: ColorResources.secondaryFontColor,
                                        fontWeight: FontWeight.w500)),
                              ],
                            ),
                            Text(doctorsModel.clinicAddress??"--",
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 13,
                                    color: ColorResources.secondaryFontColor,
                                    fontWeight: FontWeight.w500)),
                            // const Divider(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children:[
                                    const   Icon(FontAwesomeIcons.circleCheck,color: ColorResources.btnColorGreen,size: 15),
                                    const SizedBox(width: 5),
                                    Text(
                                      'appointments_done'.trParams({
                                        'count': '${doctorsModel.totalAppointmentDone ?? 0}'
                                      }),
                                      style:const TextStyle(
                                          color: ColorResources.secondaryFontColor,
                                          fontWeight: FontWeight.w500,
                                          fontSize: 12
                                      ),)],
                                ),
                                const  SizedBox(width: 10),
                                Flexible(
                                    child: SmallButtonsWidget(
                                      width: 150,
                                      height: 35,
                                      titleFontSize: 12,
                                      title: "book_now".tr,
                                      onPressed: stopBooking||doctorsModel.stopBooking==1?null:()async {

                                        SharedPreferences preferences = await SharedPreferences.getInstance();

                                        final loggedIn = preferences.getBool(SharedPreferencesConstants.login) ??false;
                                        final userId= preferences.getString(SharedPreferencesConstants.uid);
                                        if(loggedIn&&userId!=""&&userId!=null){
                                          Get.toNamed(RouteHelper.getDoctorsDetailsPageRoute(doctId:doctorsModel.id.toString() ));
                                        }else{
                                          Get.to(()=>LoginPage(onSuccessLogin:  (){      Get.toNamed(RouteHelper.getDoctorsDetailsPageRoute(doctId:doctorsModel.id.toString() ));}));
                                          // Get.toNamed(RouteHelper.getLoginPageRoute());
                                        }


                                      },rounderRadius: 10,))

                              ],
                            ),
                            const SizedBox(height: 10),

                          ],
                        ),
                      ),
                    ),
                  );
              })
        ),

      ),
    );


  }

  buildImageSection() {
  return clinicImages.isEmpty?
  Container()
      :CarouselSliderWidget(
    imagesUrl: clinicImages
  );
  }

  _buildDescBox() {
  return clinicModel?.description==null
      ||clinicModel?.description==""?
    Container():
  Card(
    elevation: .1,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(5.0),
    ),
    color: ColorResources.cardBgColor,
    child: ExpansionTile(
      childrenPadding: EdgeInsets.zero,        // Remove extra padding below children
      tilePadding: EdgeInsets.symmetric(horizontal: 10),  // Adjust padding
      collapsedBackgroundColor: Colors.transparent,        // No background color when collapsed
      backgroundColor: Colors.transparent,                 // No background color when expanded
      collapsedShape: RoundedRectangleBorder(              // Remove border when collapsed
        borderRadius: BorderRadius.circular(5.0),
      ),
      shape: RoundedRectangleBorder(                       // Remove border when expanded
        borderRadius: BorderRadius.circular(5.0),
      ),

      title: Text("description".tr,
      style: TextStyle(
        fontWeight: FontWeight.w500,
        fontSize: 14
      ),
      ),
     children: [Padding(
       padding: EdgeInsets.all(10),
       child: Text(clinicModel?.description??"",
         style: TextStyle(
             fontSize: 13,
             fontWeight: FontWeight.w400
         ),
       ),
     ),],
    ),
  );
  }
  _buildDescTimeBox() {
    return clinicModel?.openingHours==null
        ||clinicModel?.openingHours==""?
    Container():
    Card(
      elevation: .1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(5.0),
      ),
      color: ColorResources.cardBgColor,
      child: ExpansionTile(
        childrenPadding: EdgeInsets.zero,        // Remove extra padding below children
        tilePadding: EdgeInsets.symmetric(horizontal: 10),  // Adjust padding
        collapsedBackgroundColor: Colors.transparent,        // No background color when collapsed
        backgroundColor: Colors.transparent,                 // No background color when expanded
        collapsedShape: RoundedRectangleBorder(              // Remove border when collapsed
          borderRadius: BorderRadius.circular(5.0),
        ),
        shape: RoundedRectangleBorder(                       // Remove border when expanded
          borderRadius: BorderRadius.circular(5.0),
        ),
        title: Text("opening_hours".tr,
          style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14
          ),
        ),
        children: [Padding(
          padding: EdgeInsets.all(10),
          child: buildTimingWidget(getConvertedData(clinicModel!.openingHours!))
        ),],
      ),
    );
  }
  _buildTestimonialBox() {
    return

    Card(
      elevation: .1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(5.0),
      ),
      color: ColorResources.cardBgColor,
      child: ExpansionTile(
        childrenPadding: EdgeInsets.zero,        // Remove extra padding below children
        tilePadding: EdgeInsets.symmetric(horizontal: 10),  // Adjust padding
        collapsedBackgroundColor: Colors.transparent,        // No background color when collapsed
        backgroundColor: Colors.transparent,                 // No background color when expanded
        collapsedShape: RoundedRectangleBorder(              // Remove border when collapsed
          borderRadius: BorderRadius.circular(5.0),
        ),
        shape: RoundedRectangleBorder(                       // Remove border when expanded
          borderRadius: BorderRadius.circular(5.0),
        ),
        title: Text("testimonials".tr,
          style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14
          ),
        ),
        children: [_buildRatingReviewBox()],
      ),
    );
  }
  _buildRatingReviewBox(){
    return ConstrainedBox(
      constraints: const BoxConstraints(
        maxHeight: 150, // Set a maximum height to maintain balance
      ),
      child: PageView.builder(
        scrollDirection: Axis.horizontal,
        controller: PageController(viewportFraction: 0.9), // Controls card width
        itemCount: listTestimonials.length,
        // controller: PageController(viewportFraction: 0.9), // Controls card width
        itemBuilder: (context,index){
          TestimonialModel testimonialModel=listTestimonials[index];
          return SizedBox(
            width:MediaQuery.sizeOf(context).width,
            child: Card(
              color:  ColorResources.cardBgColor,
              elevation: .1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5.0),
              ),
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                isThreeLine: true,
                leading: const Padding(
                  padding: EdgeInsets.only(left:8.0),
                  child: Icon(Icons.person,
                    size: 30,
                  ),
                ),
                title: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text("${testimonialModel.title}",
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500
                      ),
                    ),
                    StarRating(
                      mainAxisAlignment: MainAxisAlignment.start,
                      length: 5,
                      color:  testimonialModel.ratting==0?Colors.grey:Colors.amber,
                      rating: double.parse((testimonialModel.ratting??0).toString()),
                      between: 5,
                      starSize: 15,
                      onRaitingTap: (rating) {
                      },
                    ),
                  ],
                ),
                subtitle: Text(testimonialModel.desc??"--",
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400
                  ),
                )
                ,
              ),
            ),
          );
        },
      ),
    );
  }

  Map<String, String> getConvertedData(String s) {
    return Map<String, String>.from(jsonDecode(s));
  }

}
