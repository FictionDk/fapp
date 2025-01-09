import 'dart:convert';

import 'package:fapp/utils/cached.dart';
import 'package:fapp/utils/device.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:async';

class BabyBottleView extends StatefulWidget {
  const BabyBottleView({super.key});
  @override
  State<StatefulWidget> createState() => _BabyBottleState();
}

class _BabyBottleState extends State<BabyBottleView> {
  final String cacheKey = "BabyBottle";
  final DateFormat _df = DateFormat('yy-MM-dd HH:mm');
  Timer? _timer;

  final String host = "glite.dev.uplasm.com";
  var header = {"Content-Type": "application/json", "Authorization": "Bearer myfiction"};
  var timeout = const Duration(seconds: 10);

  bool _picked = false;
  bool _showOptButton = false;
  DateTime _lastFeedTime = DateTime.now();
  int _totalAmount = 0;
  int _lastCount = 0;
  int _selectedHour = DateTime.now().hour;
  int _selectedMin = DateTime.now().minute;
  
  final TextEditingController _countController = TextEditingController();

  List<Map<String, dynamic>> _feeded = [];

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
    getDeviceInfo().then((kv)=> setState(() {
      header.addAll(kv);
    }));
    print("=====================> Init");
    _startTimer();
    //_initMock();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(Duration(minutes: 1), (Timer timer) {
      print("=====================> Start refresh");
      _refresh();
    });
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
        if(!_picked){
          _selectedHour = DateTime.now().hour;
          _selectedMin = DateTime.now().minute;
        }else{
          _picked = false;//避免一直都不被刷新
        }
      });
    });
  }

  void _sync() async {
    print(header);
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

  _isBlow(){
    DateTime now = DateTime.now();
    DateTime page = DateTime(now.year,now.month,now.day,now.hour,now.minute);
    Duration d = now.difference(page);
    print('blow================>${d},${d.inMinutes},${d.inSeconds}');
  }

  @override
  Widget build(BuildContext context) {
    print("==============> $_showOptButton");
    _isBlow();
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
    // 根据字体大小控制自适应
    final textScale = MediaQuery.of(context).textScaler;
    final adaptiveHeight = textScale.scale(28.0);

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
            if(_showOptButton) ... [
              const SizedBox(height: 8),
              _optButtonRow(),
            ],
            if(!_isKeyboardVisible || !_showOptButton) ... [
              const SizedBox(height: 8),
              _showView(adaptiveHeight),
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

  Widget _showView(adaptiveHeight){
    return Container(
      height: MediaQuery.of(context).size.height * 0.3,
      decoration: _boxDco(),
      padding: const EdgeInsets.all(8),
      child: SingleChildScrollView(child: Column(
        children:
          _feeded.reversed.map((fed){
            return SizedBox(height: adaptiveHeight, child: ListTile(
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
            flex: 3,
            child: DefaultTextStyle(style: const TextStyle(fontSize: 32), child: TextButton(
              onPressed: _timePicked,
              child: Text('${_selectedHour.toString().padLeft(2, '0')}:${_selectedMin.toString().padLeft(2, '0')}')),
          )),
          Expanded(
            flex: 3,
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: TextField(keyboardType: TextInputType.number,
                controller: _countController,
                onTapOutside: (event) => FocusScope.of(context).unfocus(),
              ),
            )
          ),
          const SizedBox(width: 18,),
          Expanded(
            flex: 2,
            child:GestureDetector(
              onTapDown: (TapDownDetails d){_handleTapDown(d);},
              onTapUp: (TapUpDetails d){_handleTapUp(d);},
              onTapCancel: (){_handleTapCancel();},
              child: const Text('记录'),
                //onPressed: _addFeeding, child: Text('记录')
            ),
          ),
        ],
      ),
    );
  }

  Timer? _longPressTimer;
  bool _isLongPressTriggered = false;
  void _handleTapDown(TapDownDetails d){
    _longPressTimer = Timer(const Duration(seconds: 5), (){
      if(mounted) {
        setState(() {
          _isLongPressTriggered = true;
          _showOptButton = true;
        });
      }
    });
  }
  void _handleTapUp(TapUpDetails d){
    if(!_isLongPressTriggered){
      _addFeeding();
    }
    _handleTapCancel();
  }
  void _handleTapCancel(){
    _longPressTimer?.cancel();
    _longPressTimer = null;
    setState(() {
      _isLongPressTriggered = false;
    });
  }

  _optButtonRow(){
    return Container(
      decoration: _boxDco(),
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          IconButton(onPressed: (){
            cleanMapForList(cacheKey);
            _refresh();
          }, icon: const Icon(Icons.restore_from_trash)),
          IconButton(onPressed: (){
          _sync();
          _refresh();
          }, icon: const Icon(Icons.refresh)),
          IconButton(onPressed: (){
            setState(() {
              _showOptButton = false;
            });
          }, icon: const Icon(Icons.close))
        ]
      )
    );
  }


  _addFeeding(){
    DateTime now = DateTime.now();
    _lastFeedTime = DateTime(now.year,now.month,now.day,_selectedHour,_selectedMin);
    try{
      _lastCount = int.parse(_countController.text);
    }catch(e){
    }
    if(_lastCount == 0) return;

    addMapForList(cacheKey, {'time':_lastFeedTime,'amount':_lastCount});
    _refresh();
    _putRemote(_lastFeedTime, _lastCount);
  }

  _putRemote(DateTime feedAt, int amount) async {
    print(header);
    try{
      var resp = await http.post(Uri.http(host,'/feed'), headers:header, body: jsonEncode(
        {
          "FeedAt": '${DateFormat('yyyy-MM-ddTHH:mm:ss').format(feedAt)}Z',
          "FeedAmount": amount,
          "BabyID": "default"
        }
      )).timeout(timeout);
      if(resp.statusCode == 200){
        print(jsonDecode(resp.body));
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
        _picked = true;
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
          SizedBox(
            width: 18,
            child: _hourSelect()
          ),const Text(' : '),
          SizedBox(
            width: 18,
            child: _minSelect()
          )
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
            child: Text(hour.toString().padLeft(2, '0'),style: const TextStyle(fontSize: 24),));
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
            child: Text(val.toString().padLeft(2, '0'), style: const TextStyle(fontSize: 24),));
      }).toList(),
      onChanged: (int? newVal)=>setState(() => _selectedMin = newVal!),
    );
  }
}
