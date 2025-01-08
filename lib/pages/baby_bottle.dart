import 'dart:convert';

import 'package:fapp/utils/cached.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

class BabyBottleView extends StatefulWidget {
  const BabyBottleView({super.key});
  @override
  State<StatefulWidget> createState() => _BabyBottleState();
}

class _BabyBottleState extends State<BabyBottleView> {
  final String cacheKey = "BabyBottle";
  final DateFormat _df = DateFormat('yy-MM-dd HH:mm');

  final String host = "glite.dev.uplasm.com";
  var header = {"Content-Type": "application/json", "Authorization": "Bearer myfiction"};
  var timeout = const Duration(seconds: 10);

  DateTime _lastFeedTime = DateTime.now(); // 后台返回

  int _totalAmount = 0;

  int _lastCount = 0;

  int _selectedHour = DateTime.now().hour;
  int _selectedMin = DateTime.now().minute;
  
  final TextEditingController _countController = TextEditingController();

  List<Map<String, dynamic>> _feeded = [];
  List<Map<String, dynamic>> _mookedData = [
    {'amount': 120, 'time': '25-01-06 19:14'},
    {'amount': 90, 'time': '25-01-06 16:40'},
    {'amount': 120, 'time': '25-01-07 14:20'},
    {'amount': 120, 'time': '25-01-07 09:59'},
    {'amount': 120, 'time': '25-01-07 07:14'},
    {'amount': 90, 'time': '25-01-07 05:40'},
    {'amount': 120, 'time': '25-01-07 04:20'},
    {'amount': 120, 'time': '25-01-07 02:59'},
  ];

  bool _isKeyboardVisible = false;

  bool _isNowDay(DateTime dt){
    DateTime now = DateTime.now();
    return dt.year == now.year &&
        dt.month == now.month &&
        dt.day == now.day;
  }

  @override void initState() {
    super.initState();
    _lastFeedTime = _df.parse('25-01-07 14:20');
    _refresh();
    //_initMock();
  }
  
  void _refresh() async{
    getMapForList(cacheKey).then((kv){
      kv.sort((a,b) => (a['time'] as DateTime).compareTo(b['time']));
      _totalAmount = 0;
      _lastFeedTime = DateTime.now();
      _feeded.clear();
      setState(() {
        _feeded = kv;
        for(var f in _feeded) if(_isNowDay(f['time'])) _totalAmount += f['amount'] as int;
        if(_feeded.isNotEmpty) _lastFeedTime = _feeded[_feeded.length-1]['time'];
      });
    });
  }

  void _sync() async {
    var resp = await http.get(Uri.http(host,'/feeds'), headers:header).timeout(timeout);
    if(resp.statusCode == 200){
      List<dynamic> rList = jsonDecode(resp.body);
      if(rList.isEmpty) return;
      Map<DateTime, int> rMap = Map.fromEntries(rList.map((item)=>
          MapEntry(DateFormat('yyyy-MM-ddTHH:mm:ssZ').parse(item['FeedAt']), item['FeedAmount'])));

      getMapForList(cacheKey).then((kv){
        for(var f in kv){
          if(rMap.containsKey(f['time'] as DateTime)) rMap.remove(f['time']);
        }
      });
      if(rMap.isEmpty) return;
      rMap.forEach((k,v){
        addMapForList(cacheKey, {'time':k,'amount':v});
      });
    }
  }

  void _initMock(){
    for(Map<String,dynamic> kv in _mookedData){
      DateTime time = _df.parse(kv['time']);
      int amount = kv['amount'];
      if(_isNowDay(time)) _totalAmount += amount;
      _feeded.add({'amount':amount, 'time': time});
    }
  }

  @override
  Widget build(BuildContext context) {
    if(_feeded.isEmpty) _refresh();
    // 检查键盘是否可见
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isKeyboardVisible = bottomInset > 0;
    // 更新状态并触发重新绘制
    if (_isKeyboardVisible != isKeyboardVisible) {
      setState(() {
        _isKeyboardVisible = isKeyboardVisible;
      });
    }

    return Scaffold(
      appBar: AppBar(title: const Text('BabyBottle'),),
      resizeToAvoidBottomInset: false,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _outline(),
            const SizedBox(height: 8,),
            _putIn(),
            if(!_isKeyboardVisible) ... [
              const SizedBox(height: 8),
              _showView(),
            ],
          ],
        ),
      ),
    );
  }

  String _getHourAndMinDiff(DateTime spec){
    Duration d = DateTime.now().difference(spec);
    return "${'${d.inMinutes~/60}'.toString().padLeft(2, '0')}:${'${d.inMinutes%60}'.toString().padLeft(2, '0')}";
  }

  Widget _outline() {
    return Container(
      decoration: _boxDco(),
      padding: EdgeInsets.all(8),
      child: Column(
        children: [
          _outlineRow('距离上次', _getHourAndMinDiff(_lastFeedTime)),
          _outlineRow('今日总量', '$_totalAmount ml')
        ])
    );
  }

  Widget _outlineRow(String key, String val){
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(key),
        Text(val,style: const TextStyle(fontSize: 24, color: Colors.red),)
      ],
    );
  }

  Widget _showView(){
    return Container(
      height: MediaQuery.of(context).size.height * 0.4,
      decoration: _boxDco(),
      padding: const EdgeInsets.all(8),
      child: SingleChildScrollView(child: Column(
        children:
          _feeded.reversed.map((fed){
            return SizedBox(height: 20, child: ListTile(
              title: Text("${_df.format(fed['time'])} \t ${fed['amount']}"),
            ));
          }).toList()),
    ));
  }

  Widget _putIn(){
    return Container(
      decoration: _boxDco(),
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: DefaultTextStyle(style: const TextStyle(fontSize: 32), child: TextButton(
              onPressed: _timePicked,
              child: Text('${_selectedHour.toString().padLeft(2, '0')}:${_selectedMin.toString().padLeft(2, '0')}')),
          )),
          Expanded(
            flex: 2,
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: TextField(keyboardType: TextInputType.number, maxLength: 3,
                controller: _countController,
                onTapOutside: (event) => FocusScope.of(context).unfocus(),
              ),
            )
          ),
          const SizedBox(width: 18,),
          Expanded(
            flex: 2,
            child:ElevatedButton(onPressed: _addFeeding, child: Text('记录')),
          ),
          IconButton(onPressed: (){
            cleanMapForList(cacheKey);
            _refresh();
          }, icon: const Icon(Icons.restore_from_trash)),
          IconButton(onPressed: (){
            _sync();
            _refresh();
          }, icon: const Icon(Icons.refresh)),
        ],
      ),
    );
  }

  _addFeeding(){
    DateTime now = DateTime.now();
    _lastFeedTime = DateTime(now.year,now.month,now.day,_selectedHour,_selectedMin);
    _lastCount = int.parse(_countController.text);
    addMapForList(cacheKey, {'time':_lastFeedTime,'amount':_lastCount});
    _refresh();
    _putRemote(_lastFeedTime, _lastCount);
  }

  _putRemote(DateTime feedAt, int amount) async {
    try{
      var resp = await http.post(Uri.http(host,'/feed'), headers:header, body: jsonEncode(
        {
          "FeedAt": '${DateFormat('yyyy-MM-ddTHH:mm:ss').format(feedAt)}Z',
          "FeedAmount": amount,
          "BabyID": "default"
        }
      )).timeout(timeout);
      if(resp.statusCode == 200){
        Map<String,dynamic> r = jsonDecode(resp.body);
        print(r);
      }else{
        print(resp.body);
      }
    }catch(e){
      print(e);
    }
  }

  _boxDco(){
    return BoxDecoration(
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Theme.of(context).primaryColor, width: 1),
    );
  }

  void _timePicked() async {
    final TimeOfDay? picked = await _timeSelectDialog(context);
    if(picked != null){
      if(!_compare(TimeOfDay.now(), picked)) _showErrorDialog('时间错误', '时间超过当前时间');
      setState(() {
        _selectedHour = picked.hour;
        _selectedMin = picked.minute;
      });
    }
  }

  bool _compare(TimeOfDay td1, TimeOfDay td2){
    if(td1.hour > td2.hour) return true;
    else if(td1.hour < td2.hour) return false;
    else if(td1.minute >= td2.minute) return true;
    else return false;
  }

  Future<TimeOfDay?> _timeSelectDialog(BuildContext context){
    return showDialog(context: context,
        builder: (BuildContext context){
          return const TimeDialog();
        });
  }

  void _showErrorDialog(String title, String msg){
    showDialog(context: context,
        builder: (BuildContext context){
          return AlertDialog(
            title: Text(title),
            content: Text(msg),
            actions: [
              TextButton(onPressed: ()=>Navigator.of(context).pop(), child: const Text('关闭'))
            ],
          );
        });
  }
}

// 确保数据能正确在Dialog中回显
class TimeDialog extends StatefulWidget {
  const TimeDialog({super.key});
  @override
  State<StatefulWidget> createState() => _TimeDialogState();
}
class _TimeDialogState extends State<TimeDialog> {
  int _selectedHour = DateTime.now().hour;
  int _selectedMin = DateTime.now().minute;
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('选择时间'),
      content: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _hourSelect(),const Text(' : '),
          _minSelect()
        ],
      ),
      actions: [
        TextButton(onPressed: ()=>Navigator.of(context).pop(),
            child: const Text('取消')),
        TextButton(onPressed: ()=>Navigator.of(context).pop(TimeOfDay(hour: _selectedHour, minute: _selectedMin)),
            child: const Text('完成')),
      ],
    );
  }

  Widget _hourSelect(){
    return DropdownButton<int>(
      value: _selectedHour,
      items: List.generate(24, (index) => index).map((int hour){
        return DropdownMenuItem<int>(
            value: hour,
            child: Text(hour.toString().padLeft(2, '0'),style: const TextStyle(fontSize: 32),));
      }).toList(),
      onChanged: (int? newVal)=>setState(() {
        _selectedHour = newVal!;
      }),
    );
  }

  Widget _minSelect(){
    return DropdownButton<int>(
      value: _selectedMin,
      items: List.generate(60, (index) => index).map((int val){
        return DropdownMenuItem<int>(
            value: val,
            child: Text(val.toString().padLeft(2, '0'), style: const TextStyle(fontSize: 32),));
      }).toList(),
      onChanged: (int? newVal)=>setState(() => _selectedMin = newVal!),
    );
  }
}
