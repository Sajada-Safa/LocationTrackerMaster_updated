// ignore_for_file: prefer_const_constructors, avoid_print, use_build_context_synchronously

import 'dart:convert';
import 'dart:io';

import 'package:android_id/android_id.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:location_tracker/pages/location_page.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  TextEditingController uidCtrl = TextEditingController();

  var passwordCtrl = TextEditingController();
  String uidText = '';
  String passwordText = '';

  Map<String, dynamic> data = {
    // 'id': '3',
  };
  handleAPi() async {
    String apiUrl =
        'https://7tonexpress.com/locationtesting/check?uuid=${userIdToShow}';

    Map<String, dynamic> data = {
      // 'id': '3',
    };

    print('post started');

    try {
      HttpClient client = HttpClient()
        ..badCertificateCallback =
            (X509Certificate cert, String host, int port) => true;

      final response = await http.post(
    Uri.parse(apiUrl),
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded',
    },
    body: data,
  );
      

      if (response.statusCode == 200) {
        /// If status 200 then save DUID in shared prefs
        setDeviceUniqueIdInSharedPrefs();
        /// If status 200 then save UUID in shared prefs
        setUUIDInSharedPrefs();


        final redirectUrl = response.headers['location'];
        print(redirectUrl);
        
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (BuildContext context) => TrackerPage(
                      uuid: uuid,
                  duid: duid,
                    )));
      } else {
        print('Request failed with status: ${response.statusCode}');
        
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  void handleLogin(String uid, String password) async {
    // bool uidExist = uidList.contains(uid);
    try {
      await handleAPi();
    } catch (e) {
      print(e);
    }
    // if (uidExist) {
    //   Navigator.push(context,
    //       MaterialPageRoute(builder: (BuildContext context) => TrackerPage()));
    //   print('This user exist');
    // } else {
    //   print("Doesn't exist");
    // }
  }

  /// Task:1 Generate Device Unique ID and Saved it
  String duid = '';
  Future<void> setDeviceUniqueIdInSharedPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'duid';

    /// Check if DUID is already saved
    if (prefs.containsKey(key)) {
      setState(() {
        duid = prefs.getString(key)!;
      });
    } else {


      /// Save the DUID in shared preference
      await prefs.setString(key, deviceIdToShow);

      setState(() {
        /// This duid is the device unique id which is stored in shared preference
        duid = deviceIdToShow;
      });
    }
  }
  /// End of Task:1

  /// Generate UUID randomly and save it to shared prefs
  String uuid = '';
  Future<void> setUUIDInSharedPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'uuid';

    /// Check if UUID is already saved
    if (prefs.containsKey(key)) {
      setState(() {
        uuid = prefs.getString(key)!;
      });
    } else {


      /// Save the DUID in shared preference
      await prefs.setString(key, userIdToShow);

      setState(() {
        /// This duid is the device unique id which is stored in shared preference
        uuid = userIdToShow;
      });
    }
  }

  String deviceIdToShow = '';
  void generateDuid() async{
    /// Generate a new DUID
    const androidId = AndroidId();
    String? deviceId = await androidId.getId();
    setState(() {
      deviceIdToShow = deviceId!;
    });
  }

  String userIdToShow = '';
  // void generateUUID() {
  //   /// Generate a new UUID
  //   String? userID = Uuid().v4();
  //   userIdToShow = userID;
  // }

  void getUUIDFromSharedPrefs() async{
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      userIdToShow = prefs.getString('uuid')!;

    });
  }

  @override
  void initState() {
    super.initState();

    generateDuid();
    getUUIDFromSharedPrefs();

    // if(userIdToShow == '') {
    //   setState(() {
    //     userIdToShow = uidCtrl.text;
    //   });
    //   setUUIDInSharedPrefs();
    // }
    // else {
    //   setState(() {
    //     userIdToShow = uuid;
    //
    //   });
    //
    //   /// Task 1: Getting the device id on app start
    //   // getDeviceUniqueId();
    // }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login Page'),
      ),
      body: Center(
        child: Container(
          width: 300,
          height: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Device Unique ID: $deviceIdToShow'),
              SizedBox(height: 20,),
              // ElevatedButton(onPressed: () async{
              //   await Clipboard.setData(
              //       ClipboardData(text: deviceIdToShow))
              //       .then((_) {
              //     ScaffoldMessenger.of(context)
              //         .showSnackBar(SnackBar(
              //         content: Text(
              //             "Code Copied")));
              //   });
              // },
              //     child: Text(
              //   'Copy'
              // ),),
              SizedBox(height: 20,),
              // Text('Enter duid'),
              // TextFormField(
              //   decoration: InputDecoration(
              //     hintText: 'Enter Device ID',
              //   ),
              //   controller: duidCtrl,
              // ),
              // SizedBox(
              //   height: 20,
              // ),
              Text('User Unique ID: $userIdToShow'),
              SizedBox(height: 20,),
              // ElevatedButton(onPressed: () async{
              //   await Clipboard.setData(
              //       ClipboardData(text: userIdToShow))
              //       .then((_) {
              //     ScaffoldMessenger.of(context)
              //         .showSnackBar(SnackBar(
              //         content: Text(
              //             "Code Copied")));
              //   });
              // },
                // child: Text(
                //     'Copy'
                // ),),
              SizedBox(height: 20,),
              Text('Enter uuid'),
              TextFormField(
                decoration: InputDecoration(
                  hintText: 'Enter User ID',
                ),
                controller: uidCtrl,
              ),
              SizedBox(height: 20,),

              Text('Enter password'),
              TextFormField(
                obscureText: true,
                decoration: InputDecoration(
                  hintText: 'Enter Password',
                ),
                controller: passwordCtrl,
              ),
              SizedBox(
                height: 50,
              ),
              ElevatedButton(
                  onPressed: () async{
                    final prefs = await SharedPreferences.getInstance();

                    setState(() {
                      userIdToShow = uidCtrl.text;

                      uidText = uidCtrl.text;
                      passwordText = passwordCtrl.text;
                    });
                    await prefs.setString('uuid', userIdToShow);

                    handleLogin(uidCtrl.text, passwordCtrl.text);
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (BuildContext context) => TrackerPage(
                              uuid: duid,
                              duid: uuid,
                            )));
                  },
                  child: Text('Log In'))
            ],
          ),
        ),
      ),
    );
  }
}
