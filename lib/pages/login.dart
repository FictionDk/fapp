import 'dart:convert';

import 'package:fapp/utils/cached.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class LoginView extends StatefulWidget {
  const LoginView({super.key});
  @override
  State<StatefulWidget> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginView> {
  String _username = '';
  String _password = '';
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override void initState() {
    super.initState();
    getString('_usr').then((u) => _usernameController.text = u);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login'),),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Welcome to login'),
            const SizedBox(height: 26),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 19),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _entryField('account', isPwd: false, controller: _usernameController),
                  _entryField('password', isPwd: true, controller: _passwordController),
                  ElevatedButton(onPressed: (){
                    _username = _usernameController.text;
                    _password = _passwordController.text;
                    save('_usr', _usernameController.text);
                    _doLogin(_username, _password).then((v){
                      if(v == '') {
                        Navigator.pushNamed(context, 'index');
                      } else {
                        _showErrorDialog(v);
                      }
                    });
                  }, child: Text('Login'))
                ],
              )
            )
          ],
        ),
      ),
    );
  }

  Widget _entryField(String title, {bool isPwd = false, TextEditingController ? controller, onChanged}){
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      height: 46,
      child: TextField(
        obscureText: isPwd,
        controller: controller,
        onChanged: onChanged,
        autocorrect: false,
      ),
    );
  }

  void _showErrorDialog(String msg){
    showDialog(context: context,
        builder: (BuildContext context){
          return AlertDialog(
            title: Text('Login failed'),
            content: Text(msg),
            actions: [
              TextButton(onPressed: ()=>Navigator.of(context).pop(), child: Text('Confirm'))
            ],
          );
        });
  }

  Future<String> _doLogin(String usr, String pwd) async {
    if(usr == '') return 'account can not be null';
    if(pwd == '') return 'password can not be null';

    var url = Uri.http('imes.dev.uplasm.com','/rfid/sys/login');

    var resp = await http.post(url, body: jsonEncode({
      "username": usr,
      "password": pwd,
    }), headers: {
      "Content-Type": "application/json",
      "Accept": "application/json",
    }).timeout(const Duration(seconds: 10));

    if(resp.statusCode == 200){
      var jd = jsonDecode(resp.body);
      if(jd['code'] == '0' && jd['data']['token'] != null){
        save('_token', jd['data']['token']);
        return '';
      }else{
        return jd['msg'] ?? 'Login failed';
      }
    }else{
      return jsonDecode(resp.body)['message'] ?? 'Network err, code= ${resp.statusCode}';
    }
  }
}