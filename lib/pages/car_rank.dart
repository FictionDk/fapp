
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class CarRankView extends StatefulWidget {
  const CarRankView({super.key});
  @override
  State<CarRankView> createState() => _CarRankViewState();
}

class _CarRankViewState extends State<CarRankView> {
  int _currPage = 0;
  final int _pageSize = 10;
  String _errMsg = '';
  List<dynamic> _rankData = [];
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _getData();
  }

  // 触发时间: setState
  @override
  Widget build(BuildContext context) {
    return _buildList(context);
  }

  _getData() async {
    var url = Uri.https('www.dongchedi.com','/motor/pc/car/rank_data', {
      'aid':'1839','app_name': 'auto_web_pc',
      'offset':'$_currPage',
      'count':'$_pageSize',
      'month':'202411',
      'rank_data_type':'11',
    });

    var resp = await http.get(url, headers: {
      "Content-Type": "application/json",
      "Accept": "application/json",
    }).timeout(const Duration(seconds: 10));

    if(resp.statusCode == 200){
      final List<dynamic> fetched = jsonDecode(resp.body)['data']['list'];
      setState(() {
        _rankData = fetched;
        _currPage++;
      });
      _hasMore = fetched.length >= _pageSize;
    }else{
      _errMsg = "请求失败,${resp.body}";
    }
  }

  Widget _buildList(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Car selling rank')),
      body: _errMsg != '' ? Center(child: Text("$_errMsg"),) : ListView.builder(
        itemCount: _rankData.length,
        itemBuilder:(context,idx){
          final item = _rankData[idx];
          return ListTile(
            leading: Image.network(item['image']),
            title: Text("${item['series_name']},${item['count']}"),
          );
        }),
      floatingActionButton: _hasMore ?
        FloatingActionButton(
          onPressed: _getData,
          tooltip: 'LoadMore',
          child: const Icon(Icons.add),
        ) : null,
    );
  }
}