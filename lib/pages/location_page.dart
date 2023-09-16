import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';

class TrackerPage extends StatefulWidget {
  const TrackerPage({super.key, required this.uuid, required this.duid});
  final String uuid;
  final String duid;

  @override
  State<TrackerPage> createState() => _TrackerPageState();
}

class _TrackerPageState extends State<TrackerPage> {
  bool _isLoading = false;
  double? latitude;
  double? longitude;

  //get location from device
  handleLocation() async {
    var status = await Permission.location.request();
    if (status.isGranted) {
      print('Location permission accepted');
    } else {
      print('Location permission denied');
    }
    setState(() {
      _isLoading = true;
    });

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    setState(() {
      latitude = position.latitude;
      longitude = position.longitude;
    });

    await _handleUpdateApi();

    setState(() {
      _isLoading = false;
    });

    print("Latitude: $latitude, Longitude: $longitude");
  }

  int time = DateTime.now().millisecondsSinceEpoch;

  _handleUpdateApi() async {
    final updateApiUri =
        'https://7tonexpress.com/locationtesting/update?uuid=${widget.uuid}&${widget.duid}&time=$time&lat=$latitude&lon=$longitude';
    Map<String, dynamic> data = {};

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
      } else {
        print('Request failed with status: ${response.statusCode}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  /// Update data after a certain time
  late Timer timer;
  int counter = 0;
  List<String> timeData = [];
  void startLoop() {
    // Create a timer that triggers the function every 60 seconds
    timer = Timer.periodic(Duration(seconds: 60), (timer) {
      // Call your function here
      myFunction();

      // Update the counter or check for conditions to stop the loop
      counter++;
      handleLocation();

      // For example, stop the loop after 5 iterations
      if (counter >= 10) {
        timer.cancel(); // Stop the timer/loop
      }
    });
  }

  void myFunction() {
    // Replace this with the function you want to call
    timeData.add("Function called at ${DateTime.now().millisecondsSinceEpoch}");
  }

  @override
  void dispose() {
    // Cancel the timer to avoid memory leaks when the widget is disposed
    timer.cancel();
    super.dispose();
  }

  ///End of  Updating data after a certain time code block

  /// Check internet connectivity
  ConnectivityResult _connectivityResult = ConnectivityResult.none;
  @override
  void initState() {
    _handleUpdateApi();
    handleLocation();
    startLoop();
    Connectivity().onConnectivityChanged.listen((event) {
      setState(() {
        _connectivityResult = event;
      });
      if (event == ConnectivityResult.none) {
        print('no internet');
      }
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(),
        title: Text('Location Tracker'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _isLoading
                ? const CircularProgressIndicator()
                : longitude != null && longitude != null
                    ? Column(
                        children: [
                          SizedBox(
                            height: 50,
                          ),
                          Text("Latitude: $latitude"),
                          Text("Longitude: $longitude"),
                        ],
                      )
                    : const Text(
                        'Track your location here by clicking button below.',
                      ),
            SizedBox(
              height: 20,
            ),
            ElevatedButton(
              onPressed: () async {
                handleLocation();
              },
              child: const Text('ON DUTY '),
            ),
            ElevatedButton(
                onPressed: () {
                  setState(() {
                    timer.cancel();
                  });
                },
                child: Text('OFF DUTY')),
            Expanded(
              child: ListView.builder(
                itemCount: timeData.length,
                itemBuilder: (context, index) => Text(timeData[index]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
