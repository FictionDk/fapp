
import 'package:fapp/pages/car_rank.dart';
import 'package:fapp/pages/index.dart';
import 'package:fapp/pages/login.dart';
import 'package:flutter/cupertino.dart';

final Map<String, WidgetBuilder> routes = {
  'login' : (context) => const LoginView(),
  'index' : (context) => const IndexView(),
  'rank': (context) => const CarRankView(),
};