
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class ImageUploadPage extends StatefulWidget {
  const ImageUploadPage({super.key});
  @override
  State<StatefulWidget> createState() => _ImageUploadPageState();
}

class _ImageUploadPageState extends State<ImageUploadPage> {
  Uint8List? _imageBytes;

  Future<void> _pickImage() async {
    final status = await Permission.storage.request();
    if(!status.isGranted) {
      openAppSettings();
      return;
    }
    FilePickerResult? r = await FilePicker.platform.pickFiles(type: FileType.image);
    if(r != null && r.files.single.path != null){
      final file = File(r.files.single.path!);
      final bytes = await file.readAsBytes();
      setState(() {
        _imageBytes = bytes;
      });
    }
  }

  Widget _imageContainer(BuildContext context){
    return Center(
      child: ConstrainedBox(constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.8,
        maxHeight: MediaQuery.of(context).size.height * 0.6
      ),child: ClipRRect(
        borderRadius: BorderRadius.circular(10.0),
        child: Image.memory(_imageBytes!, fit: BoxFit.cover),
      ),),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Image Upload'),),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if(_imageBytes != null)
              _imageContainer(context),
            const SizedBox(height: 10,),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(onPressed: _pickImage, child: Text('Pick')),
                const SizedBox(width: 100.0,),
                ElevatedButton(onPressed: ()=>{}, child: Text('Upload')),
              ],
            )
          ],
        ),
      )
    );
  }
}