import 'package:flutter/material.dart';
import 'package:location_tracker/main.dart';
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
    navigateToLoginPage(); // Start the navigation after 3 seconds
  }

  // Function to navigate to the login page
  void navigateToLoginPage() {
    Future.delayed(Duration(seconds: 5), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (BuildContext context) => LoginPage(),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors:[Color.fromARGB(255, 109, 64, 117),Colors.deepPurpleAccent]
             //begin: Alignment.topRight,
             //end: Alignment.bottomLeft,
            )
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.location_pin,
            size:80,
            color: Colors.white,
            ),
            SizedBox(
              height: 20
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
