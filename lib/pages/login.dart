import 'package:flutter/material.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});
  @override
  State<StatefulWidget> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginView> {
  String _username = '';
  String _password = '';
  TextEditingController _usernameController = new TextEditingController();
  TextEditingController _passwordController = new TextEditingController();

  @override void initState() {
    super.initState();
    _usernameController.text = _username;
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
                  _entryField('account', isPwd: false,controller: _usernameController, onChanged: (v) => {
                    setState(() {
                      _username = v;
                    })
                  }),
                  _entryField('password', isPwd: true, controller: _passwordController, onChanged: (v) => {
                    setState(() {
                      _password = v;
                    })
                  }),
                  ElevatedButton(onPressed: (){
                    print('$_username,$_password');
                    _usernameController.text = _username;
                    _passwordController.text = _password;
                    Navigator.pushNamed(context, 'index');
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

}