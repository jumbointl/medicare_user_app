import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import '../model/blog_post_model.dart';
import '../services/blog_post_service.dart';
import '../utilities/colors_constant.dart';
import '../widget/app_bar_widget.dart';
import '../widget/image_box_widget.dart';
import '../widget/loading_Indicator_widget.dart';

import '../utilities/api_content.dart';

class BlogDetailsPage extends StatefulWidget {
 final  String? id;
   const BlogDetailsPage({super.key,required this.id});

  @override
  State<BlogDetailsPage> createState() => _BlogDetailsPageState();
}

class _BlogDetailsPageState extends State<BlogDetailsPage> {
  BlogPostModel? blogPostModel;
  final ScrollController _scrollController=ScrollController();

  @override
  void initState() {
    // TODO: implement initState
    getAndSetData();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: IAppBar.commonAppBar(title: ""),
      body: blogPostModel == null ? ILoadingIndicatorWidget() : _buildBody(),
    );
  }

  _buildBody() {
    return ListView(
      controller: _scrollController,
      children: [
        blogPostModel!.image==null|| blogPostModel!.image==""?Container():  _buildThumbSection(),
        _buildTitleSection(),
        Divider(),
        _buildContent(),
        Divider(),
        _buildAuthorBox()
      ],
    );
  }

  _buildThumbSection() {
    return SizedBox(
        height: 200,
        child: ImageBoxFillWidget(imageUrl: "${ApiContents.imageUrl}/${blogPostModel!.image}",));
  }

  _buildTitleSection() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Padding(
            padding: const EdgeInsets.only(top: 5.0),
            child: Text(blogPostModel!.title ?? "",
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.only(top: 5.0),
            child: Text(blogPostModel!.description ?? "",
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top:0.0),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
              color: ColorResources.btnColor,
              child: Padding(
                padding: const EdgeInsets.all(5.0),
                child: Text(blogPostModel!.catTitle ?? "",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  getAndSetData() async {
    blogPostModel = await BlogPostService.getDataById(id: widget.id);
    setState(() {

    });
  }

  _buildContent() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: HtmlWidget(
          blogPostModel!.content??""),
    );
  }

  _buildAuthorBox() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Author's",style: TextStyle(
              color: ColorResources.primaryColor,
              fontSize: 16,fontWeight: FontWeight.w500),),
          ListView.builder(
              physics: NeverScrollableScrollPhysics(),
                  itemCount: blogPostModel!.author?.length??0,
              shrinkWrap: true,
              itemBuilder: (context,index){
                    final authorDetails=  blogPostModel!.author![index];
            return Card(
              elevation: .1,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: ListTile(
                leading:  authorDetails['image'] == null ||
                    authorDetails['image'] == "" ?
                const CircleAvatar(
                  backgroundColor: Colors.white,
                  radius: 25,
                  child: Icon(Icons.person),
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
                              '${ApiContents.imageUrl}/${authorDetails['image']}'
                          ),
                        ),
                      ),
                    )
                ),
                title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("${authorDetails['notes']}",
                    style: TextStyle(
                        fontWeight: FontWeight.w400,
                        fontSize: 12
                    ),
                  ),
                  Text("${authorDetails['f_name']} ${authorDetails['l_name']} (${authorDetails['role']})",
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14
                  ),
                  ),
                ],
              ),
              subtitle: Text("${authorDetails['specialization']??""}",
                style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14
                ),
              ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
