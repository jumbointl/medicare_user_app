import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:medicare_user_app/helpers/currency_formatter_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:star_rating/star_rating.dart';
import 'package:url_launcher/url_launcher.dart';
import '../controller/lab_cart_controller.dart';
import '../helpers/route_helper.dart';
import '../model/lab_cart_model.dart';
import '../model/pathologist_model.dart';
import '../model/pathology_test_model.dart';
import '../model/testimonial_model.dart';
import '../services/pathologist_service.dart';
import '../services/testimonial_service.dart';
import '../widget/app_bar_widget.dart';
import '../widget/loading_Indicator_widget.dart';
import '../services/configuration_service.dart';
import '../services/lab_cart_service.dart';
import '../services/pathologt_test_service.dart';
import '../utilities/api_content.dart';
import '../utilities/colors_constant.dart';
import '../utilities/image_constants.dart';
import '../utilities/sharedpreference_constants.dart';
import '../widget/button_widget.dart';
import '../widget/carousel_widget.dart';
import '../widget/image_box_widget.dart';
import 'package:get/get.dart';
import '../widget/search_box_widget.dart';
import 'auth/login_page.dart';

class PathologyPage extends StatefulWidget {
  final String? pathId;
  const PathologyPage({super.key,this.pathId});

  @override
  State<PathologyPage> createState() => _PathologyPageState();
}

class _PathologyPageState extends State<PathologyPage> {
  bool stopBooking =false;
  bool _isLoading=false;
  PathologistModel? pathologistModel;
  List<PathologyTestModel> pathologyTestModel=[];
  List<TestimonialModel> listTestimonials=[];
  final ScrollController _scrollController=ScrollController();
  final LabCartController _labCartController=Get.find(tag: "lab_cart");
  final TextEditingController _searchTextCityController=TextEditingController();
  List<PathologyTestModel> filterPathologistModel = [];
  List <String> pathImages=[];
  bool _isLoadingCartBtn=false;
  bool _isLabTestLoading=false;
  @override
  void initState() {
    // TODO: implement initState
    getAndSetData();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: IAppBar.commonAppBar(title: pathologistModel?.title??"pathology_lab".tr),
        body:_isLoading||pathologistModel==null?ILoadingIndicatorWidget():_buildBody()
    );
  }

  void getAndSetData() async{

    setState(() {
      _isLoading=true;
    });

    _labCartController.getData(widget.pathId.toString());
    final res=await PathologistService.getDataById( pathId:widget.pathId);
    if(res!=null){
      pathologistModel=res;
    }
    if(pathologistModel!.pathologyImage!=null){
      for(int i =0;i<pathologistModel!.pathologyImage!.length;i++){
        pathImages.add("${ApiContents.imageUrl}/${pathologistModel!.pathologyImage?[i]['image']??""}");
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

    setState(() {
      _isLabTestLoading=true;
    });
    final resList=await PathologyTestService.getDataByPathId(pathId: widget.pathId.toString());
    if(resList!=null&&resList.isNotEmpty){
      setState(() {
        pathologyTestModel=resList;
        filterPathologistModel.addAll(pathologyTestModel);
      });
    }

    setState(() {
      _isLabTestLoading=false;
    });
    final resTest=await TestimonialsService.getData( "",widget.pathId.toString());
    if(resTest!=null&&resTest.isNotEmpty){
      setState(() {
        listTestimonials=resTest;
      });
    }
  }

  _buildBody() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
            top: 0,
            right: 0,
            left: 0,
            bottom: 0,
            child: ListView(
              children: [
                buildImageSection(),
                _buildPathListTile(),
               pathologistModel?.isShowContactBox==1? _buildContactCard():Container(),
                _buildDescBox(),
                _buildDescTimeBox(),
                listTestimonials.isEmpty?Container(): _buildTestimonialBox(),
                _buildLabList(),
                SizedBox(height: 100)
              ],
            )),
    _labCartController.dataList.isNotEmpty? Positioned(
            bottom: 50,
            left: 10,
            right: 10,
            child:Stack(
              clipBehavior: Clip.none,
              children: [
                SizedBox(
                  height: 65,
                  child: Padding(
                    padding: const EdgeInsets.only(left:8.0),
                    child: InkWell(
                      onTap: _isLoadingCartBtn||stopBooking||pathologistModel?.stopBooking==1?null
                          :(){

                        Get.toNamed(RouteHelper.getLabCartCheckOutPageRoute(pathId: widget.pathId.toString()));
                      },
                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        color:  ColorResources.orangeColor,
                        elevation: .1,
                        child:
                            Padding(
                              padding: const EdgeInsets.only(left:60.0,top: 6,bottom: 6),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Obx(() {
                              final itemCount = _labCartController.dataList.length;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                        CurrencyFormatterHelper.format(getTotalAmount(_labCartController.dataList)),
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500
                                      ),
                                    ),
                                    Text(
                                      itemCount == 1? "item_in_cart".trParams({"count":itemCount.toString()}):
                                      "items_in_cart".trParams({"count":itemCount.toString()}),
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500
                                      ),
                                    ),
                                  ],
                                ),
                              );
                                                  }),
                                  Row(
                                    children: [
                                      Text("view".tr,
                                        style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.white
                                        ),
                                      ),
                                      Icon(Icons.arrow_right,
                                      color: Colors.white)
                                    ],
                                  )
                                                ],

                                                ),
                            )
                                     ,
                      ),
                    ),
                  ),
                ),

                Positioned(
                  left: 0,
                  child: CircleAvatar(
                    backgroundColor:ColorResources.lightBlueColor,
                      radius: 30,
                      child: Icon(Icons.shopping_cart,
                      color:ColorResources.orangeColor,
                        size: 30,
                      )),
                ),

              ],
            )
        ):Container()


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
              pathologistModel?.phone==null|| pathologistModel?.phone==""?Container(): _buildTapBox(ImageConstants.telephoneImageBox, "call".tr,()async{
                if( pathologistModel?.phone!=null&& pathologistModel?.phone!=""){
                  await launchUrl(Uri.parse("tel:${ pathologistModel?.phone}"));
                }
              }),
              pathologistModel?.whatsapp==null|| pathologistModel?.whatsapp==""?Container():   Padding(padding: const EdgeInsets.only(left: 20),
                  child:      _buildTapBox(ImageConstants.whatsappImageBox, "whatsapp".tr,()async{
                    if( pathologistModel?.whatsapp!=null&& pathologistModel?.whatsapp!=""){
                      final url = "https://wa.me/${ pathologistModel?.whatsapp}?text=Hello"; //remember country code
                      await launchUrl(Uri.parse(url),
                          mode: LaunchMode.externalApplication
                      );
                    }

                  })
              ),

              pathologistModel?.email==null|| pathologistModel?.email==""?Container():   Padding(padding: const EdgeInsets.only(left: 20),
                child:  _buildTapBox(ImageConstants.emailImageBox, "email".tr,()async{
                  if( pathologistModel?.email!=null&& pathologistModel?.email!=""){
                    await launchUrl(Uri.parse("mailto:${ pathologistModel?.email}"));
                  }

                }),
              ),

              pathologistModel?.longitude==null|| pathologistModel?.latitude==null?Container():  Padding(padding: const EdgeInsets.only(left: 20),
                child:     _buildTapBox(ImageConstants.mapPlaceImageBox, "map".tr,()async{
                  if(pathologistModel?.longitude!=null&&pathologistModel?.latitude!=null){
                    final url="http://maps.google.com/maps?daddr=${pathologistModel?.latitude},${pathologistModel?.longitude}";
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
  _buildPathListTile() {
    return   Card(
      elevation: .1,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: ListTile(
        isThreeLine: true,
        leading:    pathologistModel?.image==null|| pathologistModel?.image==""?
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
                  imageUrl: "${ApiContents.imageUrl}/${pathologistModel?.image}",
                  boxFit: BoxFit.fill,
                ),
              ),
            )
        ),
        title: Text(
          pathologistModel?.title??"",
          style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Row(
              children: [
                StarRating(
                  mainAxisAlignment: MainAxisAlignment.center,
                  length: 5,
                  color: pathologistModel?.averageRating == 0
                      ? Colors.grey
                      : Colors.amber,
                  rating: pathologistModel?.averageRating ?? 0,
                  between: 5,
                  starSize: 15,
                  onRaitingTap: (rating) {},
                ),
                const SizedBox(width: 10),
                Text(
                  'rating_review_text'.trParams({
                    'rating': '${pathologistModel?.averageRating ?? "--"}',
                    'count': '${pathologistModel?.numberOfReview ?? 0}',
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
                    "count": (pathologistModel?.totalBookingDone ?? 0).toString()
                  }),
                  style: const TextStyle(
                      color: ColorResources.greenFontColor,
                      fontWeight: FontWeight.w500,
                      fontSize: 12
                  ),)
              ],
            ),
            Text(
              pathologistModel?.address??"",
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w400
              ),
            ),
            const SizedBox(height: 3),
            pathologistModel?.stopBooking==1||   stopBooking?  Row(
          children:[
            Icon(Icons.warning_amber_rounded,color: ColorResources.redColor,size: 15),
            SizedBox(width: 5),
            Text("current_not_accepting_booking".tr,
              style:const TextStyle(
                  color: ColorResources.redColor,
                  fontWeight: FontWeight.w500,
                  fontSize: 14
              ),)],
        ):Container()

          ],
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

  _buildLabList() {
    return Card(
      elevation: .1,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(5.0),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(0),
        title:   Padding(
          padding:const EdgeInsets.only(bottom: 10.0),
          child:     Padding(
            padding: const EdgeInsets.only(left:8.0),
            child: Text("lab_test".tr,
              style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14
              ),),
          ),
        ),
        subtitle:   Padding(
            padding: const EdgeInsets.only(top:10.0),
            child:  _isLabTestLoading?ILoadingIndicatorWidget():filterPathologistModel.isEmpty?Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text("no_data_found!".tr),
            ): Column(
              children: [
                Padding(
                    padding: EdgeInsets.fromLTRB(5, 0, 5, 10),
                child:      ISearchBox.buildSearchBox(
                  textEditingController: _searchTextCityController,
                  labelText: "search_test".tr,
                  onChanged: (){
                      filter(_searchTextCityController.text);
                  },
                  suffixIcon: Icon(FontAwesomeIcons.stethoscope, size: 20),
                )),
                ListView.builder(
                  padding: EdgeInsets.zero,
                    controller: _scrollController,
                    shrinkWrap: true,
                    itemCount: filterPathologistModel.length,
                    itemBuilder: (context,index){
                      PathologyTestModel pathologyTest=filterPathologistModel[index];
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
                              padding: const EdgeInsets.all(0.0),
                              child: Theme(
                                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),

                                child: ExpansionTile(
                                  tilePadding: EdgeInsets.zero,
                                  childrenPadding: EdgeInsets.zero,        // Remove extra padding below children
                                    controlAffinity: ListTileControlAffinity.leading,
                                  // isThreeLine: true,
                                  leading:
                                  pathologyTest.image==null|| pathologyTest.image==""? const SizedBox(
                                    width: 50,
                                    child: Icon(Icons.image,
                                      size: 40,),
                                  ):   SizedBox(
                                    height: 50,
                                    width: 50,
                                    child: CircleAvatar(child:ImageBoxFillWidget(
                                      imageUrl:
                                      "${ApiContents.imageUrl}/${pathologyTest.image}",
                                      boxFit: BoxFit.fill,
                                    )),
                                  ),
                                  title:      Text(pathologyTest.title??"--",
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 14
                                    ),),
                                  subtitle:   Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 3),
                                      Text(CurrencyFormatterHelper.format(pathologyTest.amount??0),
                                        overflow:TextOverflow.ellipsis ,
                                        maxLines: 1,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w500,
                                            fontSize: 14
                                        ),),
                                      const SizedBox(height: 3),
                                      Text(pathologyTest.subTitle??"",
                                        overflow:TextOverflow.ellipsis ,
                                        maxLines: 1,
                                        style: const TextStyle(
                                            color: ColorResources.secondaryFontColor,
                                            fontWeight: FontWeight.w500,
                                            fontSize: 12
                                        ),),
                                      const SizedBox(height: 3),
                                      pathologyTest.subtests==null||pathologyTest.subtests!.isEmpty?Container():
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.check_circle_outline,
                                                color: Colors.green,
                                                size: 15,
                                              ),
                                              SizedBox(width: 5),
                                              Text(
                                                "tests_included".trParams({"count":pathologyTest.subtests!.length.toString()}),
                                                overflow:TextOverflow.ellipsis ,
                                                maxLines: 1,
                                                style: const TextStyle(
                                                    color: Colors.green,
                                                    fontWeight: FontWeight.w500,
                                                    fontSize: 12
                                                ),),
                                            ],
                                          ),

                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          children: [
                                            Obx(() {
                                              if(_labCartController.dataList.any((element) => element.labTestId.toString()==pathologyTest.id.toString())) {
                                                return Row(
                                                  children: [
                                                   Icon(Icons.shopping_cart,
                                                   size: 20,
                                                    color: ColorResources.primaryColor,
                                                   ),
                                                    const SizedBox(width: 10),
                                                    Text("1",
                                                      style: const TextStyle(
                                                          color: ColorResources.primaryColor,
                                                          fontWeight: FontWeight.w500,
                                                          fontSize: 16
                                                      ),
                                                    ),
                                                    const SizedBox(width: 10),
                                                    IconButton(
                                                      onPressed: _isLoadingCartBtn||stopBooking||pathologistModel?.stopBooking==1?null:()async{
                                                        SharedPreferences preferences=await SharedPreferences.getInstance();
                                                        final loggedIn = preferences.getBool(SharedPreferencesConstants.login) ??false;
                                                        final userId= preferences.getString(SharedPreferencesConstants.uid);
                                                        if(loggedIn&&userId!=""&&userId!=null){
                                                          _handelRemoveToCartData(pathologyTest.id!);
                                                        }else{
                                                          Get.to(()=>LoginPage(onSuccessLogin:  (){
                                                            _handelRemoveToCartData(pathologyTest.id!);
                                                          } ));

                                                        }

                                                      },
                                                      icon: Icon(Icons.remove_circle_outline,
                                                        size: 20,
                                                        color: ColorResources.redColor,
                                                        ),
                                                    ),

                                                  ],
                                                );
                                              } else {
                                                return  Padding(
                                                  padding: const EdgeInsets.only(top:8.0,bottom: 8.0,right: 10),
                                                  child: SmallButtonsWidget(
                                                      width: 150,
                                                      height: 35,
                                                      titleFontSize: 12,
                                                      title: "add_to_cart".tr,
                                                      onPressed:  _isLoadingCartBtn||stopBooking||pathologistModel?.stopBooking==1?null:()async{
                                                        SharedPreferences preferences=await SharedPreferences.getInstance();
                                                        final loggedIn = preferences.getBool(SharedPreferencesConstants.login) ??false;
                                                        final userId= preferences.getString(SharedPreferencesConstants.uid);
                                                        if(loggedIn&&userId!=""&&userId!=null){
                                                          _handelAddToCartData(pathologyTest);
                                                        }else{
                                                          Get.to(()=>LoginPage(onSuccessLogin:  (){
                                                            _handelAddToCartData(pathologyTest);
                                                          } ));

                                                        }
                                                      }),
                                                );
                                              }
                                           }
                                            ),
                                          ],
                                        ),
                                      Text(pathologyTest.description??"",
                                        overflow:TextOverflow.ellipsis ,
                                        maxLines: 2,
                                        style: const TextStyle(
                                            color: ColorResources.secondaryFontColor,
                                            fontWeight: FontWeight.w500,
                                            fontSize: 12
                                        ),),
                                      pathologistModel?.stopBooking==1?
                                      Padding(
                                        padding:const EdgeInsets.only(top:10.0),
                                        child: Row(
                                          children:[
                                            Icon(Icons.warning_amber_rounded,color: ColorResources.redColor,size: 15),
                                            SizedBox(width: 5),
                                            Text("current_not_accepting_booking".tr,
                                              style:const TextStyle(
                                                  color: ColorResources.redColor,
                                                  fontWeight: FontWeight.w500,
                                                  fontSize: 12
                                              ),)],
                                        ),
                                      ):Container()
                                    ],
                                  ),
                                children: [
                                  pathologyTest.subtests==null||pathologyTest.subtests!.isEmpty?Container():
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
                                          itemCount: pathologyTest.subtests!.length,
                                          itemBuilder: (context,subIndex){
                                            final subTest=pathologyTest.subtests![subIndex];
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
                              )

                            ),
                          ),
                        );
                    }),
              ],
            )
        ),

      ),
    );


  }

  buildImageSection() {
    return pathImages.isEmpty?
    Container()
        :CarouselSliderWidget(
        imagesUrl: pathImages
    );
  }

  _buildDescBox() {
    return pathologistModel?.description==null
        ||pathologistModel?.description==""?
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
          child: Text(pathologistModel?.description??"",
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
    return pathologistModel?.openingHours==null
        ||pathologistModel?.openingHours==""?
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
            child: buildTimingWidget(getConvertedData(pathologistModel!.openingHours!))
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

  void _handelAddToCartData(PathologyTestModel pathologyTest)async {
    setState(() {
      _isLoadingCartBtn=true;
    });
  final res=  await  LabCartService.addData(labTestId: pathologyTest.id.toString(),qty: "1");
    setState(() {
      _isLoadingCartBtn=false;
    });
  if(res!=null){
    //add the data to the cart controller
    //check if the item already exists in the cart
    final existingIndex = _labCartController.dataList.indexWhere(
            (element) => element.labTestId.toString() == pathologyTest.id.toString()
    );

    if (existingIndex == -1) {
      // Item does not exist, so add to list
      _labCartController.dataList.add(
        LabCartModel(labTestId: pathologyTest.id,amount:pathologyTest.amount ),
      );
    } else {
      // Optionally, you could update or handle the existing item here
      // _labCartController.dataList[existingIndex] = ...
    }
  }

}
  void _handelRemoveToCartData(int testID)async {
    setState(() {
      _isLoadingCartBtn=true;
    });
    final res=  await  LabCartService.addData(labTestId: testID.toString(),qty: "0");
    setState(() {
      _isLoadingCartBtn=false;
    });
    if(res!=null){
      //add the data to the cart controller
      //check if the item already exists in the cart
      final existingIndex = _labCartController.dataList.indexWhere(
              (element) => element.labTestId.toString() == testID.toString()
      );

      if (existingIndex == -1) {

      } else {
        // Item does not exist, so add to list
        _labCartController.dataList.removeAt(existingIndex);
        // Optionally, you could update or handle the existing item here
        // _labCartController.dataList[existingIndex] = ...
      }
    }

  }

  double getTotalAmount(RxList<LabCartModel> dataList) {
    double total = dataList.fold<double>(0.0, (sum, item) => sum + (item.amount ?? 0.0));
    return total;
  }
  void filter(String query) {
    if (query.isEmpty) {
      setState(() {
        filterPathologistModel = pathologyTestModel;
      });
    } else {
      setState(() {
        filterPathologistModel = filterPathologistModel.where((doc) {
          final lowerQuery = query.toLowerCase();
          return (doc.title?.toLowerCase().contains(lowerQuery) ?? false);


        }).toList();
      });
    }
  }
}
