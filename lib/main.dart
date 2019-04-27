import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_database/ui/firebase_animated_list.dart';
import 'package:file_picker/file_picker.dart';

void main() => runApp(MyApp());

var _color = Colors.transparent.withOpacity(0.25), _db;
TextEditingController _text;

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        home: MyHomePage(), theme: ThemeData(brightness: Brightness.dark));
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  void initState() {
    super.initState();
    _text = TextEditingController(text: "");
    _db = FirebaseDatabase.instance
        .reference()
        .child('messages')
        .orderByChild('date');
  }

  void _sendMessage({String text, String url}) {
    _db
        .reference()
        .push()
        .set({"text": text, "url": url, "date": DateTime.now().toString()});
    setState(() {
      _text.clear();
    });
  }

  void _pickFile() async {
    File file = await FilePicker.getFile(type: FileType.IMAGE);
    if (file != null) {
      StorageReference storage = FirebaseStorage.instance
          .ref()
          .child("img_${Random().nextInt(999)}.gif");
      var url =
          await (await storage.putFile(file).onComplete).ref.getDownloadURL();
      _sendMessage(url: url.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Container(
            decoration: BoxDecoration(
                gradient: LinearGradient(
                    colors: [Color(0xAA00dbde), Color(0xBBfc00ff)])),
            child: Column(children: [
              Expanded(
                  child: FirebaseAnimatedList(
                      reverse: true,
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      sort: (a, b) => b.key.compareTo(a.key),
                      query: _db,
                      itemBuilder: (_, snapshot, animation, i) {
                        return Chat(snapshot: snapshot, animation: animation);
                      },
                      defaultChild: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.signal_wifi_off,
                                size: 160, color: _color),
                            Text("No internet connection!",
                                style: TextStyle(fontSize: 18))
                          ]))),
              Padding(
                  padding: EdgeInsets.all(4),
                  child: Material(
                      borderRadius: BorderRadius.circular(26),
                      color: _color,
                      child: TextFormField(
                          controller: _text,
                          maxLines: null,
                          keyboardType: TextInputType.multiline,
                          textInputAction: TextInputAction.newline,
                          decoration: InputDecoration(
                              contentPadding: EdgeInsets.symmetric(
                                  vertical: 14, horizontal: 18),
                              prefixIcon: IconButton(
                                  icon: Icon(Icons.image),
                                  onPressed: () => _pickFile()),
                              suffixIcon: IconButton(
                                  icon: Icon(Icons.send),
                                  onPressed: () => (_text.text.isNotEmpty)
                                      ? _sendMessage(text: _text.text)
                                      : {}),
                              hintText: "Enter Text",
                              border: InputBorder.none))))
            ])));
  }
}

class Chat extends StatelessWidget {
  Chat({this.snapshot, this.animation});

  final Animation animation;
  final DataSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return SizeTransition(
        sizeFactor: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: Container(
            child: Row(children: [
          Expanded(
              child: Column(children: [
            Padding(padding: EdgeInsets.only(top: 28)),
            snapshot.value['url'] != null
                ? FadeInImage.assetNetwork(
                    placeholder: 'img/loading.gif',
                    image: snapshot.value['url'],
                  )
                : Text(snapshot.value['text']),
            Text(snapshot.value['date'],
                style: TextStyle(
                    fontSize: 9, color: Colors.black54, wordSpacing: 220))
          ]))
        ])));
  }
}
