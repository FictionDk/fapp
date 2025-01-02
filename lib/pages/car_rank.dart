
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class CarRankView extends StatefulWidget {
  const CarRankView({super.key});
  @override
  State<CarRankView> createState() => _CarRankViewState();
}

class _CarRankViewState extends State<CarRankView> {
  final _TITLE = "Car selling rank";

  int _currPage = 0;
  final int _pageSize = 10;
  String _errMsg = '';
  final List<dynamic> _rankData = [];
  bool _hasMore = true;
  bool _isLoading = false;

  String? _selectedYear;
  int? _selectedMonth;
  String _selectedDate = '202411';

  final List<String> _years = List.generate(10, (index) => DateTime.now().year - index).map((e) => e.toString()).toList();
  final List<int> _months = List.generate(12, (index) => index + 1);

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _getData();
  }

  @override
  void dispose(){
    _scrollController.dispose();
    super.dispose();
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
      'month':_selectedDate,
      'rank_data_type':'11',
    });

    setState(() {
      _isLoading = true;
    });

    try{
      var resp = await http.get(url, headers: {
        "Content-Type": "application/json",
        "Accept": "application/json",
      }).timeout(const Duration(seconds: 10));

      setState(() {
        if(resp.statusCode == 200){
          final List<dynamic> fetched = jsonDecode(resp.body)['data']['list'];
          _rankData.addAll(fetched);
          _currPage++;
          _hasMore = fetched.length >= _pageSize;
        }else{
          _errMsg = "请求失败,${resp.body}";
        }
      });

      WidgetsBinding.instance.addPostFrameCallback((_){
        _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(microseconds: 500),
            curve: Curves.easeInOut);
      });
    }catch(e){
      setState(() {
        _errMsg = "请求失败,${e.toString()}";
      });
    }finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _reset(){
    setState(() {
      _rankData.clear();
    });
    _getData();
  }

  void _updateSelectedDate() {
    if (_selectedYear != null && _selectedMonth != null) {
      setState(() {
        _selectedDate = '$_selectedYear${_selectedMonth.toString().padLeft(2, '0')}';
      });
    }
  }

  Widget _buildList(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_TITLE),
        leading: IconButton(onPressed: (){Navigator.pop(context);}, icon: const Icon(Icons.arrow_back)),
        actions: [
          PopupMenuButton(
            onSelected: (String result){
              setState(() {
                _selectedYear = result;
                _updateSelectedDate();
              });
            },
            itemBuilder: (BuildContext context) => _years.map((String year){
              return PopupMenuItem<String>(value: year,child: Text(year),);
            }).toList(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(children: [
                Text(_selectedYear ?? '2024'), const Icon(Icons.arrow_drop_down),
              ],),
            ),
          ),
          PopupMenuButton(
            onSelected: (int result){
              setState(() {
                _selectedMonth = result;
                _updateSelectedDate();
              });
            },
            itemBuilder: (BuildContext context)=> _months.map((int month){
              return PopupMenuItem<int>(value: month,child: Text(DateTime(0, month).month.toString()),);
            }).toList(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(children: [
                Text(_selectedMonth == null ? '11' : DateTime(0, _selectedMonth!).month.toString()),
                const Icon(Icons.arrow_drop_down),
            ],),
            ),
          ),
        ],
      ),
      body: _errMsg != '' ? Center(child: Text("$_errMsg"),) : Stack(
        children: [
          ListView.builder(
            controller: _scrollController,
            itemCount: _rankData.length,
            itemBuilder:(context,idx){
              final item = _rankData[idx];
              return ListTile(
                leading: Image.network(item['image']),
                title: Text("${item['series_name']},${item['count']}"),
              );
            }),
          if(_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            )
        ],
      ),

      floatingActionButton: _hasMore ?
        FloatingActionButton(
          onPressed: _getData,
          tooltip: 'LoadMore',
          child: const Icon(Icons.add),
        ) : null,
      persistentFooterButtons: <Widget>[
        ElevatedButton(onPressed: _reset,child: Text('刷新'),),
      ],
    );
  }
}