import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
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

class _TrackerPageState extends State<TrackerPage> {
  bool _isLoading = false;
  double? latitude;
  double? longitude;
  String statusText = '';
  bool isOnDuty = false;
  bool sendLocation = false;
  int currentTime = 0; // Initialize with 0
  String unsendLocation = '';
  late SharedPreferences prefs;

  final LocationSettings locationSettings = AndroidSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 0,
    forceLocationManager: true,
    intervalDuration: const Duration(seconds: 10),
    //(Optional) Set foreground notification config to keep the app alive
    //when going to the background
    foregroundNotificationConfig: const ForegroundNotificationConfig(
    notificationText:
    "Veilo app will continue to receive your location even when you aren't using it",
  notificationTitle: "Running in Background",
  enableWakeLock: true,
  )
  );


  static const String dutyStatusKey = 'duty_status';
  static const String lastLoginTimestampKey = 'last_login_timestamp';

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
      desiredAccuracy: LocationAccuracy.medium,
    );


    print(position);

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
  }

  _handleUpdateApi() async {
     var tempLocationPrefs = await prefs.getString('UNSEND_LOCATION') ?? '';
    setState(() {
      _isLoading = true;
    });

    if(tempLocationPrefs != ''){
      setState(() {
        unsendLocation = tempLocationPrefs;
      });
    }

    print('@@@@@@@@@@@@@@@@@ $tempLocationPrefs');

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    setState(() {
      latitude = position.latitude;
      longitude = position.longitude;
    });

    final time = DateTime.now().millisecondsSinceEpoch;

    final updateApiUri =
        'https://minmaxopt.com/update?uuid=${widget.uuid}&duid=${widget.duid}&time=$time&lat=$latitude&lon=$longitude';
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
      print(response.persistentConnection);

      if (response.statusCode == 200) {
        // Location sent successfully
      } else {
        print('Request failed with status: ${response.statusCode}');
      }
    } catch (e) {
      var recentLocation = 'time=$time&lat=$latitude&lon=$longitude';
        if(unsendLocation == ''){
          setState(() {
            unsendLocation = recentLocation;
            print(' nothing found ');
          });
        }else{
          setState(() {
            unsendLocation = '$unsendLocation|$recentLocation';
            print(' found ');
          });
        }
        await prefs.setString('UNSEND_LOCATION', unsendLocation);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> updateDutyStatus(bool status) async {
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
  void initState(){
    super.initState();
    _setupInitState();

    StreamSubscription<Position> positionStream = Geolocator.getPositionStream(locationSettings: locationSettings).listen(
            (Position? position) {
              print('##################################');
          print(position == null ? 'Unknown' : '${position.latitude.toString()}, ${position.longitude.toString()}');
        }
    );

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

ConnectivityResult _connectivityResult = ConnectivityResult.none;

Connectivity().onConnectivityChanged.listen((event) {
  setState(() {
    _connectivityResult = event;
  });
  if (event == ConnectivityResult.none) {
    print('No internet');
  } else if (event == ConnectivityResult.wifi || event == ConnectivityResult.mobile) {
    print('Internet connected');
    if (unsendLocation.isNotEmpty) {
      // Call the sync function when there's an internet connection
      _handleLocationSync();
    }
  }
});

    // Start the periodic location update timer
    startLoop();

    // Ensure that the user is logged in and set isLoggedIn to true in shared preferences
    setLoggedInFlag();
  }

  // Function to handle logout
  void handleLogout() async {
    // Clear the last login timestamp
    SharedPreferences.getInstance().then((prefs) {
      prefs.clear();
    });
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

  // Function to set the isLoggedIn flag to true in shared preferences
  void setLoggedInFlag() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', true);
  }

   void _handleLocationSync() async {
    var unsendLocationArray = unsendLocation.split('|');
    bool locationUpdated = true;

    for (var loc in unsendLocationArray) {
      final updateApiUri =
          'https://minmaxopt.com/update?uuid=${widget.uuid}&duid=${widget.duid}&$loc';
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
          print(updateApiUri);
        } else {
          print('Request failed with status: ${response.statusCode}');
        }
      } catch (e) {
        print(e);
        locationUpdated = false;
      }
    }

    // On success
    if (locationUpdated) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Location synced successfully'),
          backgroundColor: Colors.green,
        ),
      );
      setState(() {
        unsendLocation = '';
      });
      await prefs.setString('UNSEND_LOCATION', unsendLocation);
    }
  }

    void _setupInitState() async {
    prefs = await SharedPreferences.getInstance();
    var dutyStatusPrefs = await prefs.getBool(dutyStatusKey) ?? false;

    setState(() {
      isOnDuty = dutyStatusPrefs;
      sendLocation = dutyStatusPrefs;
      
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Veilo'),
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
              SizedBox(
                height: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
