import '../model/blog_post_model.dart';
import '../services/blog_post_service.dart';

import '../widget/toast_message.dart';
import 'package:get/get.dart';


class BlogPostController extends GetxController {
  var isLoading = false.obs; // Loading for data fetching
  var dataList = <BlogPostModel>[].obs; // list of all fetched data
  var isError = false.obs;
  var isLoadingMoreData = false.obs;

  void getData([int start=0,int end=20,String search=""]) async {
    isLoading(true);
    try {
      final getDataList = await BlogPostService.getData(start: start,end: end,search: search,isFeatured: false);
      if (getDataList !=null) {
        isError(false);
        dataList.value = getDataList;
      } else {
        isError(true);
      }
    } catch (e) {
      isError(true);
    } finally {
      isLoading(false);
    }
  }

  void getMoreDataData(int start,int end,String search) async {
    isLoadingMoreData(true);
    try {
      final getDataList = await BlogPostService.getData(start: start,end: end,search: search,isFeatured: false);
      if (getDataList !=null) {
        if(dataList.length==getDataList.length){
          IToastMsg.showMessage("No more data available");
        }
        dataList.value = getDataList;
      }
    } finally {
      isLoadingMoreData(false);
    }
  }


}
