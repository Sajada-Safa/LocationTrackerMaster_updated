import 'package:flutter/material.dart';
import 'package:location_tracker/pages/location_page.dart';
import 'package:location_tracker/pages/login.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    final isLoggedIn = prefs.containsKey('uuid');
    final isFirstTime = prefs.getBool('first_time') ?? true;

    Future.delayed(Duration(seconds: 3), () {
      if (isLoggedIn) {
        // If the user is logged in, navigate to the LocationPage
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (BuildContext context) =>
                isFirstTime ? LoginPage() : TrackerPage(uuid: 'uuid', duid: 'duid', userNameT: 'nameText'),
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
              "LOCATION TRACKER",
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
