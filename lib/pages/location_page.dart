import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Add this import for MethodChannel
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:location_tracker/pages/login.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TrackerPage extends StatefulWidget {
  const TrackerPage({
    Key? key,
    required this.uuid,
    required this.duid,
    required String userNameT,
  }) : super(key: key);

  final String uuid;
  final String duid;

  @override
  State<TrackerPage> createState() => _TrackerPageState();
}

class _TrackerPageState extends State<TrackerPage> with WidgetsBindingObserver {
  bool _isLoading = false;
  double? latitude;
  double? longitude;
  String statusText = '';
  bool isOnDuty = false;
  bool sendLocation = false;

  static const String dutyStatusKey = 'duty_status';
  static const String lastLoginTimestampKey = 'last_login_timestamp';

  Future<void> handleLocation() async {
    try {
      var status = await Permission.location.request();
      if (status.isGranted) {
        print('Location permission accepted');
      } else {
        print('Location permission denied');
        return;
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

      if (sendLocation) {
        await _handleUpdateApi();
      }

      setState(() {
        _isLoading = false;
      });

      print("Latitude: $latitude, Longitude: $longitude");
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<void> _handleUpdateApi() async {
    try {
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

      final time = DateTime.now().millisecondsSinceEpoch;

      final updateApiUri =
          'https://7tonexpress.com/locationtesting/update?uuid=${widget.uuid}&duid=${widget.duid}&time=$time&lat=$latitude&lon=$longitude';
      Map<String, dynamic> data = {};

      print(updateApiUri);

      final response = await http.post(
        Uri.parse(updateApiUri),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: data,
      );

      if (response.statusCode == 200) {
        // Location sent successfully
      } else {
        print('Request failed with status: ${response.statusCode}');
      }
    } catch (e) {
      print('Error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> updateDutyStatus(bool status) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(dutyStatusKey, status);
  }

  Future<bool> getDutyStatus() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(dutyStatusKey) ?? false;
  }

  Future<void> setLastLoginTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
        lastLoginTimestampKey, DateTime.now().millisecondsSinceEpoch);
  }

  Future<int?> getLastLoginTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(lastLoginTimestampKey);
  }

  late Timer timer;
  List<String> timeData = [];

  void startLoop() {
    timer = Timer.periodic(Duration(seconds: 15), (timer) {
      if (sendLocation) {
        handleLocation();
      }
    });
  }

  @override
  void initState() {
    super.initState();

    // Check if the user has been logged in for more than 15 days
    getLastLoginTimestamp().then((lastLoginTimestamp) {
      if (lastLoginTimestamp != null) {
        final fifteenDaysAgo = DateTime.now().subtract(Duration(days: 15));
        if (DateTime.fromMillisecondsSinceEpoch(lastLoginTimestamp)
            .isBefore(fifteenDaysAgo)) {
          // Automatically log out the user
          handleLogout();
        }
      }
    });

    // Retrieve the duty status from shared preferences
    getDutyStatus().then((status) {
      setState(() {
        isOnDuty = status;
        sendLocation = status;
        if (isOnDuty) {
          statusText = 'You are On Duty';
          handleLocation();
        } else {
          statusText = 'You are Off Duty';
        }
      });
    });

    // Set the last login timestamp
    setLastLoginTimestamp();

    // Check for connectivity changes
    ConnectivityResult _connectivityResult = ConnectivityResult.none;

    Connectivity().onConnectivityChanged.listen((event) {
      setState(() {
        _connectivityResult = event;
      });
      if (event == ConnectivityResult.none) {
        print('no internet');
      }
    });

    // Start the periodic location update timer
    startLoop();

    // Register a callback to execute when the app is in the background or terminated
    WidgetsBinding.instance?.addObserver(this);

    // Set up MethodChannel for running background tasks
    const MethodChannel backgroundChannel =
        MethodChannel('com.example/background_location');
    backgroundChannel.setMethodCallHandler((call) async {
      if (call.method == 'onBackgroundLocation') {
        final Map<dynamic, dynamic> args = call.arguments;
        final double latitude = args['latitude'];
        final double longitude = args['longitude'];
        final int time = args['time'];
        // You can handle the background location data here
        // For example, send it to your server
        await _handleBackgroundLocation(latitude, longitude, time);
      }
    });
  }

  Future<void> _handleBackgroundLocation(
      double latitude, double longitude, int time) async {
    final updateApiUri =
        'https://7tonexpress.com/locationtesting/update?uuid=${widget.uuid}&duid=${widget.duid}&time=$time&lat=$latitude&lon=$longitude';
    Map<String, dynamic> data = {};

    try {
      final response = await http.post(
        Uri.parse(updateApiUri),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: data,
      );

      if (response.statusCode == 200) {
        // Location sent successfully
      } else {
        print('Request failed with status: ${response.statusCode}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  // Add a function to handle logout
  void handleLogout() async {
    // Clear the last login timestamp
    clearLastLoginTimestamp();

    // Clear the duty status
    await updateDutyStatus(false);

    setState(() {
      isOnDuty = false;
      sendLocation = false;
      statusText = '';
    });

    // Navigate to the LoginPage and remove all previous routes from the stack
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (BuildContext context) => LoginPage(),
      ),
      (Route<dynamic> route) => false,
    );

    // Clear the isLoggedIn flag in shared preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
  }

  // Function to clear the last login timestamp
  void clearLastLoginTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(lastLoginTimestampKey);
  }

  // Function to start/stop duty and location tracking
  void toggleDuty() async {
    setState(() {
      isOnDuty = !isOnDuty;
      sendLocation = isOnDuty;

      if (isOnDuty) {
        statusText = 'You are On Duty';
        handleLocation();
      } else {
        statusText = 'You are Off Duty';
      }
    });

    // Update duty status in shared preferences
    await updateDutyStatus(isOnDuty);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Location Tracker'),
        actions: [
          IconButton(
            onPressed: () {
              handleLogout();
            },
            icon: Icon(Icons.logout),
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
                  : (longitude != null && latitude != null && sendLocation)
                      ? Column(
                          children: [
                            SizedBox(
                              height: 50,
                            ),
                            // Text("Latitude: $latitude"),
                            // Text("Longitude: $longitude"),
                            // Text("Time: ${DateTime.now().millisecondsSinceEpoch}"),
                          ],
                        )
                      : const Text(
                          ' ',
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
                onPressed: () {
                  toggleDuty(); // Toggle duty and location tracking
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

  @override
  void dispose() {
    // Cancel the timer when the widget is disposed
    timer.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Function to start periodic location updates

    void startLoop() {
      timer = Timer.periodic(Duration(seconds: 15), (timer) {
        if (sendLocation) {
          handleLocation();
        }
      });
    }

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      // App is in the background or terminated

      // Retrieve latitude and longitude
      handleLocation();
    }
  }
}
