import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

class VersionControl{

  static Future<String> getVersionName()async{
  String versionName="";
  PackageInfo packageInfo= await  PackageInfo.fromPlatform();
  String version = packageInfo.version;
  versionName=   version.toString();
  if (kDebugMode) {
    print("Version $version");
  }
    return versionName;
      }

}