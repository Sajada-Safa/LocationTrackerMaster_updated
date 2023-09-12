// ignore_for_file: prefer_const_constructors, unused_local_variable, prefer_const_declarations, use_build_context_synchronously

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class TrackerPage extends StatefulWidget {
  const TrackerPage({super.key, required this.uuid});
  final String uuid;

  @override
  State<TrackerPage> createState() => _TrackerPageState();
}

class _TrackerPageState extends State<TrackerPage> {
  
  _handleUpdateApi() async {
    final updateApiUri =
        'https://7tonexpress.com/locationtesting/update?uuid=0268957591&duid=245634567&time=1694452506051&lat=22.3384&lon=91.83168';
    Map<String, dynamic> data = {
      // 'id': '3',
    };

    print('post started');

    try {
      HttpClient client = HttpClient()
        ..badCertificateCallback =
            (X509Certificate cert, String host, int port) => true;
final response = await http.post(
   Uri.parse(updateApiUri),
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded',
    },
    body: data,
  );
      
      if (response.statusCode == 200) {
       
        // Navigator.push(
        //     context,
        //     MaterialPageRoute(
        //         builder: (BuildContext context) => TrackerPage()));
      } else {
        print('Request failed with status: ${response.statusCode}');
        
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    _handleUpdateApi();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(),
        title: Text('Location Tracker'),
      ),
    );
  }
}
