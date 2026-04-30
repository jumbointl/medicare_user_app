import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/city_model.dart';
import '../services/city_service.dart';
import '../services/doctor_service.dart';
import '../model/doctors_model.dart';
import '../services/configuration_service.dart';
import '../controller/depratment_controller.dart';
import '../helpers/route_helper.dart';
import '../model/department_model.dart';
import '../utilities/api_content.dart';
import '../utilities/colors_constant.dart';
import '../utilities/image_constants.dart';
import '../utilities/sharedpreference_constants.dart';
import '../widget/app_bar_widget.dart';
import '../widget/button_widget.dart';
import '../widget/image_box_widget.dart';
import '../widget/loading_Indicator_widget.dart';
import '../widget/no_data_widgets.dart';
import '../widget/search_box_widget.dart';
import 'package:star_rating/star_rating.dart';

import 'auth/login_page.dart';

class DoctorsListPage extends StatefulWidget {
  final String? selectedDeptId;
  final String? selectedDeptTitle;
  const DoctorsListPage({super.key,this.selectedDeptId,this.selectedDeptTitle});

  @override
  State<DoctorsListPage> createState() => _DoctorsListPageState();
}

class _DoctorsListPageState extends State<DoctorsListPage> {
   // final DoctorsController _doctorsController=Get.put(DoctorsController());
  final ScrollController _scrollController=ScrollController();
  final TextEditingController _searchTextController=TextEditingController();
    final TextEditingController _searchTextCityController=TextEditingController();
  final TextEditingController _searchTextDoctorsController=TextEditingController();
   final DepartmentController _departmentController=Get.put(DepartmentController(),tag: "department");

   final ScrollController _bottomSheetScrollController=ScrollController();
   List<CityModel> _cityModelList=[];
   List<CityModel> filteredCities = [];
   String? selectedCityId;
   List<DoctorsModel> _doctorModelList=[];
   List<DoctorsModel> filtereddoctors = [];
    int? selectedDeptId;
   String? selectedDeptTitle;
   bool stopBooking =false;
  bool _isLoading=false;
  @override
  void initState() {
    // TODO: implement initState
    if(widget.selectedDeptId!=""&&widget.selectedDeptTitle!="")
    {
      selectedDeptId = int.parse(widget.selectedDeptId??"");
      selectedDeptTitle = widget.selectedDeptTitle;
    }
    // _doctorsController.getData("");
    getAndSetData();
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:  ColorResources.bgColor,
      appBar: IAppBar.commonAppBar(title: "doctors".tr),
      body: _isLoading?const ILoadingIndicatorWidget():_buildBody(),
    );
  }

  // build body ui
  _buildBody() {
    return ListView(
      controller: _scrollController,
      padding:const  EdgeInsets.all(8),
      children: [
        const SizedBox(height: 10),
        ISearchBox.buildSearchBoxOnTap(
            textEditingController: _searchTextCityController,
            labelText: "search_city",
            onTap:(){

          _openBottomSheetSearchCity();
        },
            suffixIcon: Icon(Icons.location_on,
              size: 20,
            )
        ),
        const SizedBox(height: 10),
    _searchTextCityController.text==""?Container():
    ISearchBox.buildSearchBox(
      textEditingController: _searchTextDoctorsController,
      labelText: "search_placeholder_doctor_page".tr,
          onChanged: (){
            filterDoctors(_searchTextDoctorsController.text);
          },

          suffixIcon: Icon(FontAwesomeIcons.stethoscope, size: 20),
        ),

        const SizedBox(height: 20),
        _buildDepartment(),
        selectedDeptTitle==null?Container():
        Padding(
            padding: const EdgeInsets.only(bottom:0.0,top:0),
          child: Row(
            children: [
              RichText(
                text:  TextSpan(
                  text: 'showing_doctors_from'.tr,
                  style: const TextStyle(
                      color: ColorResources.primaryFontColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 14
                  ),
                  children:  <TextSpan>[
                    TextSpan(text: ' $selectedDeptTitle' , style:const TextStyle(
                        color: ColorResources.primaryColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 14
                    ),),
                     TextSpan(text:"department_sm".tr,
                    style: const TextStyle(
                        color: ColorResources.primaryFontColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 14
                    ),)
                  ],
                ),
              ),
              IconButton(onPressed: (){
                setState(() {
                  selectedDeptId=null;
                  selectedDeptTitle=null;
                });
              }, icon: const Icon(Icons.remove_circle,color: ColorResources.btnColor,
              size: 24,
              ))
            ],
          )),
        filtereddoctors.isEmpty?
        const NoDataWidget():
     _buildDrList(filtereddoctors)

    //  Obx(() {
    //   if (!_doctorsController.isError.value) { // if no any error
    //     if (_doctorsController.isLoading.value) {
    //       return const IVerticalListLongLoadingWidget();
    //     } else if (_doctorsController.dataList.isEmpty) {
    //       return const NoDataWidget();
    //     }
    //     else {
    //       return _buildDrList(_doctorsController.dataList);
    //     }
    //   }else {
    //     return  const IErrorWidget();
    //   } //Error svg
    // }
    // )
      ],
    );
  }

  // build dr list ui
  _buildDrList(List dataList) {
    return
     ListView.builder(
        controller: _scrollController,
        shrinkWrap: true,
        itemCount: dataList.length,
        itemBuilder: (context,index){
          DoctorsModel doctorsModel=dataList[index];
          return showDoctor(doctorsModel)?
          Padding(
            padding: const EdgeInsets.only(top:20.0),
            child: Card(
              color:  ColorResources.cardBgColor,
              elevation: .1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5.0),
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
                                      Text('not_accepting_appointments'.tr,
                                        style:TextStyle(
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
                                  debugPrint("userId $userId");
                                  debugPrint("Get to getDoctorsDetailsPageRoute doctId ${doctorsModel.id}");
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
          ):Container();});

  }
   _buildDepartment() {
     return     Obx(() {
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
                     style: const TextStyle(
                         fontWeight: FontWeight.w600,
                         fontSize: 14
                     ),),
                   dataList.length<4?Container():  Text('swipe_more'.tr,
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
                       setState(() {
                         if(selectedDeptId==departmentModel.id){
                           selectedDeptId=null;
                           selectedDeptTitle=null;
                         }
                         else{
                           selectedDeptId=departmentModel.id;
                           selectedDeptTitle=departmentModel.title;
                         }


                       });
                       // Get.toNamed(RouteHelper.getSearchProductsPageRoute(initSelectedProductCatId: productCatModel.id.toString()));
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
                           style:  TextStyle(
                             color:selectedDeptId==departmentModel.id?Colors.red:Colors.black ,
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
  getAndSetData()async{
    setState(() {
      _isLoading=true;
    });
    SharedPreferences sharedPreferences=await SharedPreferences.getInstance();
    final city=sharedPreferences.getString("city")??"";
    selectedCityId=sharedPreferences.getString("city_id")??"";
    _searchTextCityController.text=city;
    _searchTextController.text=city;

    final res=await ConfigurationService.getDataById(idName: "stop_booking");
    if(res!=null){
      if(res.value=="true"){
        stopBooking=true;
      }
    }

    final cityRes=await CityService.getData(search: "");
    if(cityRes!=null){
      _cityModelList=cityRes;
      filteredCities.addAll(_cityModelList);
    }
    final resD=await DoctorsService.getData(searchQuery: "",cityId: selectedCityId);
    if(resD!=null){
      _doctorModelList=resD;
      filtereddoctors.addAll(_doctorModelList);
    }
    setState(() {
      _isLoading=false;
    });
  }

  getDoctorsData()async{
    setState(() {
      _isLoading=true;
    });
    _doctorModelList.clear();
    filtereddoctors.clear();

    final res=await DoctorsService.getData(searchQuery: "",cityId: selectedCityId);
    if(res!=null){
      _doctorModelList=res;
      filtereddoctors.addAll(_doctorModelList);
    }
    setState(() {
      _isLoading=false;
    });

  }

 bool showDoctor(DoctorsModel doctorsModel) {
    if(selectedDeptId==null){
      return true;
    }else if (selectedDeptId!=null&&selectedDeptId==doctorsModel.deptId)
      {
        return true;
      }
    else {
      return false;
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
                             suffixIcon: Icon(Icons.location_on,
                             size: 20,
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
                                       onTap: (){
                                         Get.back();
                                         selectedCityId=cityMode.id.toString();
                                         _searchTextCityController.text="${cityMode.title},${cityMode.stateTitle}";
                                         _searchTextController.text="${cityMode.title},${cityMode.stateTitle}";
                                         _searchTextDoctorsController.clear();
                                         getDoctorsData();
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
  void filterDoctors(String query) {
    if (query.isEmpty) {
      setState(() {
        filtereddoctors = _doctorModelList;
      });
    } else {
      setState(() {
        filtereddoctors = _doctorModelList.where((doc) {
          final lowerQuery = query.toLowerCase();
          return (doc.fName?.toLowerCase().contains(lowerQuery) ?? false) ||
              (doc.lName?.toLowerCase().contains(lowerQuery) ?? false) ||
              (doc.clinicTitle?.toLowerCase().contains(lowerQuery) ?? false) ||
              (doc.specialization?.toLowerCase().contains(lowerQuery) ?? false) ||
              (doc.deptName?.toLowerCase().contains(lowerQuery) ?? false) ||
              (doc.clinicAddress?.toLowerCase().contains(lowerQuery) ?? false);
        }).toList();
      });
    }
  }
}
