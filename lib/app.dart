import 'dart:async';
import 'package:device_info/device_info.dart';
import 'dart:io';

class App {
  static final DeviceInfoPlugin deviceInfoPlugin = new DeviceInfoPlugin();
  static String androidVersion = "";
  
  static Future<Null> initPlatformState() async{
    try{
      if (Platform.isAndroid){
        androidVersion = _readAndroidBuildData(await deviceInfoPlugin.androidInfo);
      }
    } on Exception { }
  }
  static String _readAndroidBuildData(AndroidDeviceInfo build){
    return build.version.release.toString();
  }

}

  bool checkVersion({String have, String need}){
    List<String> haveArray = have.split(".");
    List<String> needArray = need.split(".");
    // check each version level. If "have" is less than "need" at any point, we return false
    for (int i = 0; i < needArray.length; i++){
      if (haveArray.length > i){
        if (int.tryParse(haveArray[i]) < int.tryParse(needArray[i]))
          return false;
      }
    }
    // "have" has fewer decimals than "need" so we'll check the last "have".
    if (haveArray.length < needArray.length){
    //       If the last "have" decimal is less "need" then we return false
    //       have = 1.3     need = 1.3.1
    //       have = 1.2     need = 1.3.0
      if (int.tryParse(haveArray[haveArray.length - 1]) < int.tryParse(needArray[haveArray.length - 1]))
        return false;
    //       If the last "have" decimal is equal to the same "need" and the rest of "need" != 0, return false
    //       have = 1.1     need = 1.0.0    okay
    //       have = 1       need = 1.0.0    okay
    //       have = 1       need = 1.0.1    not okay
      if (int.tryParse(haveArray[haveArray.length - 1]) == int.tryParse(needArray[haveArray.length - 1])){
        int needSum = 0;
        for (int i = haveArray.length; i < needArray.length; i++){
          needSum += int.tryParse(needArray[i]);
        }
        if (needSum != 0)
          return false;
      }
    }
    // If we've made it this far, then the "need" >= "have". return true
    return true;
  }
