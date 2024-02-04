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
  TextEditingController nameCtrl = TextEditingController();

  Map<String, String> userNames = {}; // Store user names

  String uidText = '';
  String passwordText = '';
  String nameText = '';

  Map<String, dynamic> data = {};

  String duid = '';
  String uuid = '';
  String deviceIdToShow = '';
  String userIdToShow = '';

  Text userNameText = Text('');

  get responseStatusCode => null;

  Future<void> setDeviceUniqueIdInSharedPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'duid';

    if (prefs.containsKey(key)) {
      setState(() {
        duid = prefs.getString(key)!;
      });
    } else {
      await prefs.setString(key, deviceIdToShow);
      setState(() {
        duid = deviceIdToShow;
      });
    }
  }

  Future<void> setUUIDInSharedPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'uuid';

    if (prefs.containsKey(key)) {
      setState(() {
        uuid = prefs.getString(key)!;
      });
    } else {
      await prefs.setString(key, userIdToShow);
      setState(() {
        uuid = userIdToShow;
      });
    }
  }

  void generateDuid() async {
    const androidId = AndroidId();
    String? deviceId = await androidId.getId();
    setState(() {
      deviceIdToShow = deviceId!;
    });
  }

  void getUUIDFromSharedPrefs() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      userIdToShow = prefs.getString('uuid')!;
    });
  }

  void getNameFromSharedPrefs() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      nameText = prefs.getString('name') ?? '';
      userNameText = Text('User Name: $nameText');
    });
  }

  Future<void> saveNameInSharedPreferences(String name) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'name';

    await prefs.setString(key, name);
  }

  Future<void> handleAPi() async {
    String apiUrl =
        'https://veilolab.com/map/check?uuid=$userIdToShow&name=$nameText';

    Map<String, dynamic> data = {};

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
        setDeviceUniqueIdInSharedPrefs();
        setUUIDInSharedPrefs();

        final redirectUrl = response.headers['location'];
        print(redirectUrl);

        // After successful login, navigate to the LocationPage and clear the navigation stack.
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (BuildContext context) => TrackerPage(
              uuid: uuid,
              duid: duid,
              userNameT: nameText,
            ),
          ),
          (route) => false,
        );
      } else if (response.statusCode == 404) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Wrong ID. Please try again.'),
          ),
        );
      } else {
        print('Request failed with status: ${response.statusCode}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  void handleLogin(String uid, String name) async {
    try {
      // Update the nameText variable when handling login
      setState(() {
        nameText = nameCtrl.text;
      });
      await handleAPi();
    } catch (e) {
      print(e);
    }

    userNames[uuid] = nameCtrl.text; // Store the user name in the map
    await saveNameInSharedPreferences(nameCtrl.text);
  }

  @override
  void initState() {
    super.initState();

    generateDuid();
    getUUIDFromSharedPrefs();
    getNameFromSharedPrefs();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Veilo'),
      ),
      body: Center(
        child: Container(
          width: 300,
          height: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              TextFormField(
                decoration: InputDecoration(
                  hintText: 'Enter ID',
                ),
                controller: uidCtrl,
              ),
              SizedBox(height: 20),
              TextFormField(
                decoration: InputDecoration(
                  hintText: 'Enter Name',
                ),
                controller: nameCtrl,
              ),
              SizedBox(height: 50),
              Align(
                alignment: Alignment.center,
                child: ElevatedButton(
                  onPressed: () async {
                    final prefs = await SharedPreferences.getInstance();

                    setState(() {
                      userIdToShow = uidCtrl.text;
                      uidText = uidCtrl.text;
                      passwordText = nameCtrl.text;
                    });
                    await prefs.setString('uuid', userIdToShow);

                    // Handle login here
                    handleLogin(uidCtrl.text, nameCtrl.text);
                  },
                  child: Text('Log In'),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
