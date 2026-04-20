import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:get/get.dart';
import '../../services/web_page_service.dart';
import '../../widget/app_bar_widget.dart';
import '../../widget/loading_Indicator_widget.dart';
import '../../widget/no_data_widgets.dart';

class PrivacyPage extends StatefulWidget {
  const PrivacyPage({super.key});

  @override
  State<PrivacyPage> createState() => _AboutUsPageState();
}

class _AboutUsPageState extends State<PrivacyPage> {
  bool _isLoading=false;
  String? body;
  @override
  void initState() {
    // TODO: implement initState
    getAndSetData();
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: IAppBar.commonAppBar(title: "privacy_policy".tr),
      body: _isLoading?const ILoadingIndicatorWidget():body==null?const NoDataWidget():
      ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: HtmlWidget(
                body??""
            ),
          ),
        ],
      ),
    );
  }

  void getAndSetData() async{
    setState(() {
      _isLoading=true;
    });
    final res= await WebPageService.getDataById(id: "2");
    if(res!=null){
      body=res.body;
    }
    setState(() {
      _isLoading=false;
    });
  }
}
