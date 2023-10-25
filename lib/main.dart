import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:location_tracker/pages/location_page.dart';
import 'package:location_tracker/pages/login.dart';
import 'package:location_tracker/pages/splash_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  HttpOverrides.global = MyHttpOverrides(); // Set custom HttpOverrides

  runApp(const MyApp());
}

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Veilo',
      theme: ThemeData(
        primaryColor: Color.fromARGB(255, 101, 71, 145),
        primarySwatch: Colors.deepPurple,
      ),
      home: SplashScreen(),
    );
  }
}
