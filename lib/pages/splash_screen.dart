import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:location_tracker/pages/login.dart';
import 'package:location_tracker/pages/location_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    navigateToNextScreen();
  }

  void navigateToNextScreen() async {
    // Check if the user is already logged in
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
     print('IsLoggedIn: $isLoggedIn'); // Print the login status

    var uuid = await prefs.getString('uuid') ?? 'NA';
    print(uuid);
    var duid = prefs.getString('duid') ?? 'NA';
    print(duid);
    var nameText = prefs.getString('name') ?? 'NA';
    print(nameText);

    Future.delayed(Duration(seconds: 3), () {
      if (isLoggedIn) {
        // If the user is logged in, navigate to the LocationPage
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (BuildContext context) => TrackerPage(uuid: uuid, duid: duid, userNameT: nameText),
          ),
        );
      } else {
        // If the user is not logged in, navigate to the LoginPage
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (BuildContext context) => LoginPage(),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.fromARGB(255, 109, 64, 117),
              Colors.deepPurpleAccent,
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.location_pin,
              size: 80,
              color: Colors.white,
            ),
            SizedBox(
              height: 20,
            ),
            Text(
              "VEILO",
              style: TextStyle(
                fontStyle: FontStyle.italic,
                fontSize: 32,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

