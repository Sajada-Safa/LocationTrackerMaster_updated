// ignore_for_file: prefer_const_constructors, avoid_print, use_build_context_synchronously

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:location_tracker/pages/location_page.dart';
import 'package:http/http.dart' as http;

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  var uidCtrl = TextEditingController();
  var passwordCtrl = TextEditingController();
  String uidText = '';
  String passwordText = '';

  Map<String, dynamic> data = {
    // 'id': '3',
  };
  handleAPi() async {
    String apiUrl =
        'https://7tonexpress.com/locationtesting/check?uuid=${uidCtrl.text}';

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
        final redirectUrl = response.headers['location'];
        print(redirectUrl);
        
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (BuildContext context) => TrackerPage(
                      uuid: uidCtrl.text,
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
              Text('Enter uuid'),
              TextFormField(
                decoration: InputDecoration(
                  hintText: 'Enter User ID',
                ),
                controller: uidCtrl,
              ),
              SizedBox(
                height: 20,
              ),
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
                  onPressed: () {
                    setState(() {
                      uidText = uidCtrl.text;
                      passwordText = passwordCtrl.text;
                    });
                    handleLogin(uidCtrl.text, passwordCtrl.text);
                  },
                  child: Text('Log In'))
            ],
          ),
        ),
      ),
    );
  }
}
