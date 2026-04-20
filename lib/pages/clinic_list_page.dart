import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/clinic_service.dart';
import '../widget/app_bar_widget.dart';
import 'package:get/get.dart';
import '../helpers/route_helper.dart';
import '../model/city_model.dart';
import '../model/clinic_model.dart';
import '../services/city_service.dart';
import '../utilities/api_content.dart';
import '../utilities/colors_constant.dart';
import '../widget/image_box_widget.dart';
import '../widget/loading_Indicator_widget.dart';
import '../widget/no_data_widgets.dart';
import '../widget/search_box_widget.dart';

class ClinicListPage extends StatefulWidget {
  const ClinicListPage({super.key});

  @override
  State<ClinicListPage> createState() => _ClinicListPageState();
}

class _ClinicListPageState extends State<ClinicListPage> {
  List<CityModel> _cityModelList=[];
  List<CityModel> filteredCities = [];
  final TextEditingController _searchTextController=TextEditingController();
  final TextEditingController _searchTextCityController=TextEditingController();
  final ScrollController _bottomSheetScrollController=ScrollController();
  final TextEditingController _searchTextDoctorsController=TextEditingController();
  String? selectedCityId;
  List<ClinicModel> clinicModelList=[];
  List<ClinicModel> filterClinic = [];
  bool _isLoading=false;
  @override
  void initState() {

    getAndSetData();
    // TODO: implement initState
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: IAppBar.commonAppBar(title: "clinics".tr),
      body:  _isLoading?const ILoadingIndicatorWidget():_buildBody(),
    );
  }

  _buildBody() {
    return ListView(
      padding: EdgeInsets.all(8),
      children: [
        const SizedBox(height: 10),
        ISearchBox.buildSearchBoxOnTap(
            textEditingController: _searchTextCityController,
            labelText: "search_city".tr,
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
          labelText: "search_clinic".tr,
          onChanged: (){
            filterClinics(_searchTextDoctorsController.text);
          },
          suffixIcon: Icon(FontAwesomeIcons.stethoscope, size: 20),
        ),

        const SizedBox(height: 20),
        filterClinic.isEmpty?
        const NoDataWidget():
    _buildClinic(filterClinic)
      ],
    );
  }
  void filterClinics(String query) {
    if (query.isEmpty) {
      setState(() {
        filterClinic = clinicModelList;
      });
    } else {
      setState(() {
        filterClinic = clinicModelList.where((doc) {
          final lowerQuery = query.toLowerCase();
          return (doc.title?.toLowerCase().contains(lowerQuery) ?? false) ||
              (doc.address?.toLowerCase().contains(lowerQuery) ?? false) ;

        }).toList();
      });
    }
  }
  _buildClinic(dataList) {
    return ListView.builder(
        padding: const EdgeInsets.all(0),
       // controller: _scrollController,
        // physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: dataList.length<=5?dataList.length:5,
        itemBuilder: (context,index){
          return   _buildClinicCard(dataList[index]);
        });
  }
  _buildClinicCard(ClinicModel clinicModel){
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(5.0),
      ),
      color: ColorResources.cardBgColor,
      elevation: .1,
      child: ListTile(
        onTap: (){
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
      ),
    );
  }

  void getAndSetData() async{
    setState(() {
      _isLoading=true;
    });
    SharedPreferences sharedPreferences=await SharedPreferences.getInstance();
    final city=sharedPreferences.getString("city")??"";
    selectedCityId=sharedPreferences.getString("city_id")??"";
    _searchTextCityController.text=city;
    _searchTextController.text=city;
    final cityRes=await CityService.getData(search: "");
    if(cityRes!=null){
      _cityModelList=cityRes;
      filteredCities.addAll(_cityModelList);
    }
    final res=await ClinicService.getData(start: "0",end:"10",cityId: selectedCityId);
    if(res!=null){
      clinicModelList=res;
      filterClinic.addAll(clinicModelList);
    }
    setState(() {
      _isLoading=false;
    });
  }
  getClinicData()async{
    setState(() {
      _isLoading=true;
    });
    clinicModelList.clear();
    filterClinic.clear();

    final res=await ClinicService.getData(start: "0",end:"10",cityId: selectedCityId);
    if(res!=null){
      clinicModelList=res;
      filterClinic.addAll(clinicModelList);
    }
    setState(() {
      _isLoading=false;
    });
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
                                            getClinicData();
                                          },
                                          title: Text("${cityMode.title},${cityMode.stateTitle}",
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
}
