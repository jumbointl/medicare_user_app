import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pull_to_refresh_flutter3/pull_to_refresh_flutter3.dart';
import '../controller/blog_post_controller.dart';
import '../widget/app_bar_widget.dart';

import '../helpers/route_helper.dart';
import '../model/blog_post_model.dart';
import '../utilities/api_content.dart';
import '../utilities/colors_constant.dart';
import '../widget/error_widget.dart';
import '../widget/image_box_widget.dart';
import '../widget/loading_Indicator_widget.dart';
import '../widget/no_data_widgets.dart';

class BlogListPage extends StatefulWidget {
  const BlogListPage({super.key});

  @override
  State<BlogListPage> createState() => _BlogListPageState();
}

class _BlogListPageState extends State<BlogListPage> {
  final BlogPostController _blogPostController=Get.put(BlogPostController());
  final TextEditingController _textEditingController=TextEditingController();
  final ScrollController _scrollController=ScrollController();
  RefreshController refreshController=RefreshController();
  int start=0;
  int end=20;
@override
  void initState() {
    // TODO: implement initState
  _blogPostController.getData();
    super.initState();
  }
  void _onRefresh() async{
    refreshController.refreshCompleted();

  }
  void _onLoading() async{
    if(mounted) {
      setState(() {
      });
    }
    refreshController.loadComplete();
    end+=20;
    _blogPostController.getMoreDataData(0, end, _textEditingController.text);
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: IAppBar.commonAppBar(title: "Blog"),
      body: _buildBody(),
    );
  }
  _buildBody() {
    return  Stack(
      children: [
        SizedBox(
          height: MediaQuery.sizeOf(context).height,
          width: MediaQuery.sizeOf(context).width,
        ),
        Positioned(
          top: 10,
          left:0,
          right: 0,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        onSubmitted: (value){
                          _blogPostController.getData(0,20,_textEditingController.text);
                        },
                        controller: _textEditingController,
                        decoration: InputDecoration(
                          hintText: 'search...'.tr,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12.0),
                        ),
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.only(left:8.0,right: 8),
                      child: GestureDetector(
                        onTap: (){
                          _textEditingController.clear();
                          _blogPostController.getData(0,20,_textEditingController.text);
                        },
                        child: const Icon(Icons.clear,
                          color: ColorResources.greyBtnColor,
                          size: 20,),
                      ),
                    )

                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Divider()
            ],
          ),
        ),
        Positioned(
          top: 90,
          bottom: 0,
          left:0,
          right: 0,
          child: SmartRefresher(
            scrollController:_scrollController,
            enablePullDown: false,
            enablePullUp: true,
            header: null,
            footer: null,
            controller: refreshController,
            onRefresh: _onRefresh,
            onLoading: _onLoading,
            child: Obx(() {
              if (!_blogPostController.isError.value) { // if no any error
                if (_blogPostController.isLoading.value) {
                  return const IVerticalListLongLoadingWidget();
                } else if (_blogPostController.dataList.isEmpty) {
                  return const NoDataWidget();
                }
                else {
                  return ListView.builder(
                      padding: const EdgeInsets.all(0),
                      shrinkWrap: true,
                      itemCount: _blogPostController.dataList.length<=5? _blogPostController.dataList.length:5,
                      itemBuilder: (context,index){
                        return   _buildBlogPost( _blogPostController.dataList[index]);
                      });
                }
              }else {
                return  const IErrorWidget();
              } //Error svg
            }
            ),
          ),
        ),

      ],
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
}
