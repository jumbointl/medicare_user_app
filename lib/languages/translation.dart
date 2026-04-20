import 'package:get/get.dart';
import 'package:medicare_user_app/languages/es.dart';
import 'package:medicare_user_app/languages/pt.dart';
import 'package:medicare_user_app/languages/zh.dart';
import 'package:medicare_user_app/languages/zh_tw.dart';

import 'en.dart';

class Translation extends Translations {
 static Map<String, Map<String, String>> get assetKeys => {
  ...enKeys,
  ...esKeys,
  ...ptKeys,
  ...zhKeys,
  ...zhTwKeys,
 };

 @override
 Map<String, Map<String, String>> get keys => assetKeys;
}