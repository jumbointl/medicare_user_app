import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:get/get.dart';
import '../utilities/api_content.dart';
import '../controller/testimonial_controller.dart';
import '../helpers/date_time_helper.dart';
import '../model/testimonial_model.dart';
import '../widget/app_bar_widget.dart';
import '../widget/error_widget.dart';
import '../widget/loading_Indicator_widget.dart';
import '../widget/no_data_widgets.dart';

class TestimonialPage extends StatefulWidget {
  const TestimonialPage({super.key});

  @override
  State<TestimonialPage> createState() => _TestimonialPageState();
}

class _TestimonialPageState extends State<TestimonialPage> {
  TestimonialController? testimonialController=TestimonialController();
  @override
  void initState() {
    // TODO: implement initState
    testimonialController=Get.put(TestimonialController());
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: IAppBar.commonAppBar(title: "testimonials".tr),
      body:  Obx(() {
        if (!testimonialController!.isError.value) { // if no any error
          if (testimonialController!.isLoading.value) {
            return const IVerticalListLongLoadingWidget();
          } else if (testimonialController!.dataList.isEmpty) {
            return const NoDataWidget();
          }

          else {
            return _buildList(testimonialController!.dataList);
          }
        }else {
          return  const IErrorWidget();
        } //Error svg
      }
      ),
    );
  }
  Widget _buildList(RxList dataList) {
    return ListView.builder(
        shrinkWrap: true,
        itemCount:dataList.length ,
        itemBuilder: (context,index){
          TestimonialModel testimonialModel=dataList[index];
       //   print(testimonialModel.image);
          return Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            elevation: 0,
            child: ListTile(
              subtitle:   Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const SizedBox(height: 3),
                  Text(testimonialModel.subTitle??"",
                    style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14
                    ),),
                  const SizedBox(height: 3),
                  Text(testimonialModel.desc??"",
                    style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14
                    ),),
                ],
              ),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(testimonialModel.title??"",
                        style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14
                        ),),
                      const SizedBox(height: 3),
                      Text(DateTimeHelper.getDataFormat(testimonialModel.createdAt),
                          style:  const TextStyle(
                              fontWeight: FontWeight.w400,
                              fontSize: 14
                          )),
                      const SizedBox(height: 3),
                      _buildRatingBar(testimonialModel.ratting??0),
                    ],
                  ),
                  testimonialModel.image==null?Container(): CircleAvatar(
                    radius: 30.0,
                    backgroundImage:
                    NetworkImage("${ApiContents.imageUrl}/${testimonialModel.image}"),
                    backgroundColor: Colors.transparent,
                  )
                ],
              ),
            ),
          );
        });
  }

  _buildRatingBar(int intiRating) {
    return RatingBar.builder(
      initialRating: double.parse(intiRating.toString()),
      ignoreGestures: true,
      minRating: 1,
      direction: Axis.horizontal,
      allowHalfRating: true,
      itemCount: 5,
      itemSize: 20,
      itemPadding:const  EdgeInsets.symmetric(horizontal: 0.0),
      itemBuilder: (context, _) => const Icon(
        Icons.star,
        color: Colors.amber,
      ),
      onRatingUpdate: (rating) {

      },
    );
  }
}
