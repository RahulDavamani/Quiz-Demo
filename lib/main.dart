import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:xfile/xfile.dart';
void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quiz Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      debugShowCheckedModeBanner: false,
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var questions = [
    {
      'Id': '1',
      'Question': "What bends your mind every time you think about it?",
      'Answer': null
    },
    {
      'Id': '2',
      'Question': "What's something you wish you'd figured out sooner?",
      'Answer': null
    },
    {
      'Id': '3',
      'Question': "What is one of the great values that guides your life?",
      'Answer': null
    },
    {
      'Id': '4',
      'Question':
          "When was the last time you changed your opinion about something major?",
      'Answer': null
    },
    {
      'Id': '5',
      'Question':
          "Would you rather be stuck on a broken ski lift or a broken elevator?",
      'Answer': null
    },
  ];
  @override
  void initState() {
    questions.forEach((element)async {
      final colc = FirebaseFirestore.instance.collection('answers');
      if (colc.doc(element['Id']) != null) {
          var qus = await colc.doc(element['Id']).get();
        setState(()  {
          element['Answer'] = qus['Answer'];
        });
      }
    });
    super.initState();
  }

  void showAddAnswer(BuildContext ctx, String id) {
    showModalBottomSheet(
        context: ctx,
        builder: (_) {
          return Container(
              padding: EdgeInsets.symmetric(vertical: 10),
              height: 150,
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    SizedBox(height: 5),
                    Text('Add Document', style: TextStyle(fontSize: 22)),
                    SizedBox(height: 10),
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: <Widget>[
                          Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                RawMaterialButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    getAnswer('camera', id);
                                  },
                                  child: new Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                    size: 40,
                                  ),
                                  shape: new CircleBorder(),
                                  elevation: 2.0,
                                  fillColor: Colors.blue,
                                  padding: const EdgeInsets.all(10),
                                ),
                                SizedBox(height: 10),
                                Text('Camera', style: TextStyle(fontSize: 16))
                              ]),
                          Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                RawMaterialButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    getAnswer('gallery', id);
                                  },
                                  child: new Icon(
                                    Icons.photo,
                                    color: Colors.white,
                                    size: 40,
                                  ),
                                  shape: new CircleBorder(),
                                  elevation: 2.0,
                                  fillColor: Colors.blue,
                                  padding: const EdgeInsets.all(10),
                                ),
                                SizedBox(height: 10),
                                Text('Gallery', style: TextStyle(fontSize: 16))
                              ])
                        ])
                  ]));
        });
  }

  Future getAnswer(String method, String id) async {
    var video;
    final ImagePicker picker = ImagePicker();
    switch (method) {
      case 'camera':
        video = await picker.pickVideo(
          source: ImageSource.camera,
        );
        break;
      case 'gallery':
        video = await picker.pickVideo(source: ImageSource.gallery);
        break;
    }
    if (video == null) return;
    var questionn;
    questions.forEach((q) {
      if (q['Id'] == id) {
        q['Answer'] = video.toString();
        questionn = q['Question'];
      }
    });
    final ref = FirebaseStorage.instance
        .ref()
        .child('answers')
        .child('Answer$id' + '.mp4');
        // File file = video.toFile();
    await ref.putFile(File(video.path)).whenComplete(() => null);
    final videoUrl = await ref.getDownloadURL();
    await FirebaseFirestore.instance.collection('answers').doc(id).set({
      'Id': id,
      'Question': questionn,
      'Answer': videoUrl,
    });
    if (video == null) return;
    questions.forEach((q) {
      if (q['Id'] == id)
        setState(() {
          q['Answer'] = videoUrl;
        });
    });
  }

  void uploadAnswers() {
    print(questions);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text('Quiz Demo'), actions: [
          IconButton(icon: Icon(Icons.cloud_upload), onPressed: uploadAnswers)
        ]),
        body: Container(
            padding: EdgeInsets.all(15),
            child: ListView(children: [
              ...questions.map((q) {
                return Container(
                  margin: EdgeInsets.only(bottom: 10),
                  child: Card(
                      elevation: 2,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ListTile(
                            leading: Text(q['Id']),
                            minLeadingWidth: 15,
                            title: Text(q['Question']),
                          ),
                          ElevatedButton(
                            child: Text(
                                q['Answer'] == null ? 'Add Answer' : 'Change'),
                            onPressed: () => showAddAnswer(context, q['Id']),
                          ),
                          SizedBox(height: 10)
                        ],
                      )),
                );
              }).toList()
            ])));
  }
}
