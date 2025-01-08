
import 'package:fapp/pages/baby_bottle.dart';
import 'package:fapp/pages/car_rank.dart';
import 'package:fapp/pages/image_upload.dart';
import 'package:fapp/pages/index.dart';
import 'package:fapp/pages/login.dart';
import 'package:flutter/cupertino.dart';

final Map<String, WidgetBuilder> routes = {
  'login' : (context) => const LoginView(),
  'index' : (context) => const IndexView(),
  'rank': (context) => const CarRankView(),
  'image': (context) => const ImageUploadPage(),
  'babyBottle': (context) => const BabyBottleView()
};