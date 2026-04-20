import '../model/blog_post_model.dart';
import '../helpers/get_req_helper.dart';
import '../utilities/api_content.dart';

class BlogPostService{

  static const  getUrl=   ApiContents.blogPostUrl;
  static const  getByIdUrl=   ApiContents.blogPostUrl;
  static List<BlogPostModel> dataFromJson (jsonDecodedData){
    return List<BlogPostModel>.from(jsonDecodedData.map((item)=>BlogPostModel.fromJson(item)));
  }

  static Future <List<BlogPostModel>?> getData({required int start,
    required int end,
    required bool isFeatured,
    String search="",

  })async
  {
    Map<String, dynamic>? body={};
    if(isFeatured)
    {
      body={
        "start":start.toString(),
        "end":end.toString(),
        "search":search,
        "featured":"1",
        'status':"Published"
      };
    }else{
      body={
        "start":start.toString(),
        "end":end.toString(),
        "search":search,
        'status':"Published"
      };
    }

    final res=await GetService.getReqWithBodY(getUrl,body);

    if(res==null) {
      return null;
    } else {
      List<BlogPostModel> dataModelList = dataFromJson(res);
      return dataModelList;
    }
  }

  static Future <BlogPostModel?> getDataById({required String? id})async {
    final res=await GetService.getReq("$getByIdUrl/${id??""}");
    if(res==null) {
      return null;
    } else {
      BlogPostModel dataModel = BlogPostModel.fromJson(res);
      return dataModel;
    }
  }

}