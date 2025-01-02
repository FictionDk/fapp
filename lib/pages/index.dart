import 'package:flutter/material.dart';

class IndexView extends StatelessWidget {
  const IndexView({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("HomePage"),),
      body: ListView(
        children: [
          ElevatedButton(onPressed: (){
            Navigator.pushNamed(context, 'rank');
          }, child: Text('Car Selling rank')),
          ElevatedButton(onPressed: (){
            Navigator.pushNamed(context, 'login');
          }, child: Text('Return Login'))
        ],
      ),
    );
  }

}