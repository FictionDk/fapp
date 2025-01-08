import 'dart:convert';

import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> save(String key, String value) async {
  final instance = await SharedPreferences.getInstance();
  instance.setString(key, value);
}

Future<String> getString(String key) async {
  final instance = await SharedPreferences.getInstance();
  return instance.getString(key) ?? '';
}

Future<void> cleanMapForList(String key) async {
  final instance = await SharedPreferences.getInstance();
  instance.setStringList(key, []);
}

Future<void> addMapForList(String key, Map<String,dynamic> mapData) async {
  final instance = await SharedPreferences.getInstance();
  List<String> rList = instance.getStringList(key) ?? [];
  rList.add(coverToJson(mapData));
  bool r = await instance.setStringList(key, rList);
}

Future<List<Map<String,dynamic>>> getMapForList(String key) async {
  final instance = await SharedPreferences.getInstance();
  List<String> rList = instance.getStringList(key) ?? [];
  if(rList.isEmpty) return [];
  List<Map<String,dynamic>> result = [];
  for (var value in rList) {
    result.add(coverFromJson(value));
  }
  return result;
}


final DateFormat _formatter = DateFormat('yyyy-MM-ddTHH:mm:ssZ');
Map<String,dynamic> coverFromJson(String json){
  final Map<String, dynamic> map = jsonDecode(json);
  return map.map((k,v)=>MapEntry(k, _parseValue(k, v)));
}

String coverToJson(Map<String,dynamic> data){
  return jsonEncode(data.map((key, value) => MapEntry(key, _convertValue(value))));
}

dynamic _convertValue(dynamic value) {
  if (value is DateTime) {
    return _formatter.format(value);
  } else if (value is Map) {
    return value.map((k, v) => MapEntry(k, _convertValue(v)));
  } else if (value is List) {
    return value.map((item) => _convertValue(item)).toList();
  }
  return value;
}

dynamic _parseValue(String key, dynamic value) {
  if (value is String && _isCustomFormat(key)) {
    try {
      return _formatter.parse(value);
    } catch (_) {
      return value;
    }
  } else if (value is Map) {
    return value.map((k, v) => MapEntry(k, _parseValue(key, v)));
  } else if (value is List) {
    return value.map((item) => _parseValue(key, item)).toList();
  }
  return value;
}

bool _isCustomFormat(String key) {
  return "time" == key;
}