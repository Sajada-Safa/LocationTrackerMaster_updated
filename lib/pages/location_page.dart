import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:location_tracker/pages/login.dart';
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
  String statusText = '';
  bool isOnDuty = false; // Added a boolean to track duty status
  bool sendLocation = false; // Added a boolean to track location sending

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

    // Check if sendLocation flag is true before sending location
    if (sendLocation) {
      await _handleUpdateApi();
    }

    setState(() {
      _isLoading = false;
    });

    print("Latitude: $latitude, Longitude: $longitude");
  }

  int time = DateTime.now().millisecondsSinceEpoch;

  _handleUpdateApi() async {
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

    final updateApiUri =
        'https://7tonexpress.com/locationtesting/update?uuid=${widget.uuid}&duid=${widget.duid}&time=$time&lat=$latitude&lon=$longitude';
    Map<String, dynamic> data = {};

    print(updateApiUri);

    try {
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

  /// End of Updating data after a certain time code block

  /// Check internet connectivity
  ConnectivityResult _connectivityResult = ConnectivityResult.none;
  @override
  void initState() {
    handleLocation(); // Remove this line to prevent immediate location update
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

  // Add a function to handle logout
  void handleLogout() {
    // Navigate to the LoginPage and remove all previous routes from the stack
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (BuildContext context) => LoginPage(),
      ),
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(),
        title: Text('Location Tracker'),
        actions: [
          // Add a logout button as an IconButton
          IconButton(
            onPressed: () {
              handleLogout();
            },
            icon: Icon(Icons.logout), // Use the logout icon
          ),
        ],
      ),
      body: Center(
        child: Container(
          width: 300,
          height: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _isLoading
                  ? const CircularProgressIndicator()
                  : (longitude != null && longitude != null && sendLocation)
                      ? Column(
                          children: [
                            SizedBox(
                              height: 50,
                            ),
                            // Text("Latitude: $latitude"),
                            // Text("Longitude: $longitude"),
                          ],
                        )
                      : const Text(
                          'Track your location here by clicking button below.',
                        ),
              SizedBox(
                height: 20,
              ),
              Text(
                statusText,
                style: TextStyle(fontSize: 15, color: Colors.blueGrey),
              ),
              SizedBox(
                height: 18,
              ),
              ElevatedButton(
                onPressed: () async {
                  setState(() {
                    isOnDuty = !isOnDuty; // Toggle duty status
                    sendLocation = isOnDuty; // Start/stop sending location
                  });

                  if (isOnDuty) {
                    timer.cancel();
                    statusText = 'You are On Duty';
                  } else {
                    statusText = 'You are Off Duty';
                  }

                  if (sendLocation) {
                    // Start sending location when on duty
                    handleLocation();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isOnDuty ? Colors.deepOrange : Colors.blue,
                ),
                child: Text(isOnDuty ? 'OFF DUTY' : 'ON DUTY'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
