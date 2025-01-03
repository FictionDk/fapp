import 'package:shared_preferences/shared_preferences.dart';

Future<void> save(String key, String value) async {
  final instance = await SharedPreferences.getInstance();
  instance.setString(key, value);
}

Future<String> getString(String key) async {
  final instance = await SharedPreferences.getInstance();
  return instance.getString(key) ?? '';
}