
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
  final _hosts = 'www.dongchedi.com';
  final _path = '/motor/pc/car/rank_data';

  int _offset = 0;
  final int _pageSize = 10;
  String _errMsg = '';
  final List<dynamic> _rankData = [];
  bool _hasMore = true;
  bool _isLoading = false;

  String _selectedMonth = '500';
  final List<Map<String,String>> _monthArr = [{'text': "近半年",'month': '500'}];
  final Map<String,String> _monthMap = {'500':'近半年'};

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _offset = 0;
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

  _calItemHigh(BuildContext context, BoxConstraints constraints){
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    final double appBarHeight = AppBar().preferredSize.height;
    final double availableHeight = constraints.maxHeight - appBarHeight - statusBarHeight;
    return availableHeight / _pageSize;
  }

  _getData() async {
    var url = Uri.https(_hosts, _path, {
      'aid':'1839','app_name': 'auto_web_pc',
      'offset':'$_offset',
      'count':'$_pageSize',
      'month': _selectedMonth,
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
          final result = jsonDecode(resp.body)['data'];
          final List<dynamic> fetched = result['list'];
          _rankData.addAll(fetched);
          _offset = _offset + _pageSize;
          _hasMore = fetched.length >= _pageSize;
          List<dynamic> rankMonth = result['sells_rank_month'];
          _monthArr.clear();
          for(var v in rankMonth){
            _monthMap['${v['month']}'] = v['text'];
            _monthArr.add({'month':'${v['month']}','text': v['text']});
          }
        }else{
          _errMsg = "req failed,${resp.body}";
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
        _errMsg = "req failed,${e.toString()}";
      });
    }finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _reset(){
    _offset = 0;
    setState(() {
      _rankData.clear();
    });
    _getData();
  }

  Widget _buildList(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_TITLE),
        leading: IconButton(onPressed: (){Navigator.pop(context);}, icon: const Icon(Icons.arrow_back)),
        actions: [
          PopupMenuButton(
            onSelected: (String result){
              setState(() => _selectedMonth = result);
              _reset();
            },
            itemBuilder: (BuildContext context) => _monthArr.map((Map<String,String>m){
              return PopupMenuItem<String>(value: m['month'],child: Text(m['text']??''));
            }).toList(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(children: [
                Text(_monthMap[_selectedMonth]??''), const Icon(Icons.arrow_drop_down),
              ],),
            ),
          ),
        ],
      ),
      body: _errMsg != '' ? Center(child: Text("$_errMsg"),) : LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints){
            double itemHeight = _calItemHigh(context, constraints);
            return Stack(
              children: [
                ListView.builder(
                    controller: _scrollController,
                    itemCount: _rankData.length,
                    itemBuilder:(context,idx){
                      final item = _rankData[idx];
                      return SizedBox(
                        height: itemHeight,
                        child: ListTile(
                          leading: Image.network(item['image']),
                          title: Text("${item['series_name']}}"),
                          subtitle: Text('${item['count']}'),
                        ),
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
            );
          }),
      floatingActionButton: _hasMore ?
        FloatingActionButton(
          onPressed: _getData,
          tooltip: 'LoadMore',
          child: const Icon(Icons.add),
        ) : null,
      persistentFooterButtons: <Widget>[
        ElevatedButton(onPressed: _reset,child: Text('Refresh'),)
      ],
    );
  }
}