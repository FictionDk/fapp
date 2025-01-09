import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';


Future<Map<String,String>> getDeviceInfo() async {
  try{
    final DeviceInfoPlugin dip = DeviceInfoPlugin();
    if(Platform.isAndroid){
      final AndroidDeviceInfo adi = await dip.androidInfo;
      return {'dModel':adi.model, 'dId': adi.id};
    }
  }catch(e){
    print("failed to get device info: $e");
  }
  return {};
}