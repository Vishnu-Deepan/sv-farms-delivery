import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart'; // Import geolocator
import 'package:url_launcher/url_launcher.dart';
import '../controller/mapLogic.dart';
import '../widgets/homeNavBar.dart';


class UserLocationMapPage extends StatefulWidget {
  @override
  _UserLocationMapPageState createState() => _UserLocationMapPageState();
}

class _UserLocationMapPageState extends State<UserLocationMapPage> {
  late Future<List<Map<String, dynamic>>> userLocations;
  late Stream<Position> _positionStream; // Stream for live location
  late Position _currentPosition; // To hold the current position
  bool _locationServiceEnabled = false; // Location service status
  late bool _permissionGranted; // Check for permission granted

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(seconds: 1), ()
    {
      _initializeLocationService(); // Initialize location service
      // Fetch user locations based on delivery person ID
      String deliveryPersonId = FirebaseAuth.instance.currentUser?.uid ?? "";
      userLocations = MapLogic().fetchUserLocations(deliveryPersonId);
    });
  }

  // Initialize location service and permissions (force permission if not granted)
  void _initializeLocationService() async {
    // Check if location services are enabled
    _locationServiceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!_locationServiceEnabled) {
      print("Location services are disabled.");
      return;
    }

    // Request permission if not granted
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();  // Force request permission
    }

    // Handle location permission
    if (permission == LocationPermission.deniedForever) {
      // Permission is denied forever, force redirect to another screen
      print("Location permission denied forever.");
      _forceNavigateToHome();
    } else if (permission == LocationPermission.denied) {
      // Handle the case where permission is denied, force re-request
      print("Location permission denied. Requesting permission again.");
      _forceNavigateToHome();
    } else {
      // Permission granted, continue with location updates
      _permissionGranted = true;
      _positionStream = Geolocator.getPositionStream(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10, // Update location every 10 meters
        ),
      );

      // Listen to location changes
      _positionStream.listen((Position position) {
        setState(() {
          _currentPosition = position;
        });
      });
    }
  }

  // Forcefully navigate to HomeNavBar if permission is not granted
  void _forceNavigateToHome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => HomeNavBar()), // Replace with your HomeNavBar screen
    );
  }

  // Function to show a custom bottom sheet
  void _showUserDetails(BuildContext context, Map<String, dynamic> location) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        width: MediaQuery.of(context).size.width,
        padding: EdgeInsets.all(16),
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              location['userName'],
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Address:',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            SizedBox(height: 3),
            Text(
              '${location['address']}',
              style: TextStyle(fontSize: 18, color: Colors.black, fontWeight: FontWeight.w800),
            ),
            SizedBox(height: 8),
            Text(
              'Phone:',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            SizedBox(height: 3),
            Row(children: [
              TextButton(
                onPressed: () async {
                  final phone = location['userPhone'];
                  final url = 'tel:+91$phone';  // Creating a tel: URL
                  if (await canLaunch(url)) {
                    await launch(url);  // Launch the phone dialer
                  } else {
                    // Handle if the URL can't be launched
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Could not launch phone dialer'),
                    ));
                  }
                }, child: Text(  '${location['userPhone']}',
                style: TextStyle(fontSize: 18, color: Colors.blue, fontWeight: FontWeight.w800),),
              ),
              Text("Tap to call"),
            ],),

            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Close'),
            ),
          ],
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("User Locations Map")),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: userLocations,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text("No user locations found."));
          } else {
            List<Map<String, dynamic>> locations = snapshot.data!;

            // Calculate the average latitude and longitude
            double totalLat = 0.0;
            double totalLon = 0.0;

            for (var location in locations) {
              totalLat += location['lat'];
              totalLon += location['lon'];
            }

            double avgLat = totalLat / locations.length;
            double avgLon = totalLon / locations.length;

            // Create a list of markers with a custom bottom sheet for details
            List<Marker> markers = locations.map((location) {
              return Marker(
                point: LatLng(location['lat'], location['lon']),
                width: 80,
                height: 80,
                child: GestureDetector(
                  onTap: () {
                    _showUserDetails(context, location);
                  },
                  child: Icon(
                    Icons.location_on,
                    color: Colors.red,
                    size: 40,
                  ),
                ),
              );
            }).toList();

            // Add current live location marker
            Marker liveLocationMarker = Marker(
              point: _currentPosition != null
                  ? LatLng(_currentPosition.latitude, _currentPosition.longitude)
                  : LatLng(avgLat, avgLon), // Fallback to average if no location
              width: 80,
              height: 80,
              child: Icon(
                Icons.my_location,
                color: Colors.blue,
                size: 30,
              ),
            );

            markers.add(liveLocationMarker);

            return FlutterMap(
              options: MapOptions(
                initialCenter: LatLng(avgLat, avgLon), // Set center to the average lat/lon
                initialZoom: 12.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png", // OpenStreetMap tiles
                  subdomains: ['a', 'b', 'c'],
                ),
                MarkerLayer(
                  markers: markers,
                ),
              ],
            );
          }
        },
      ),
    );
  }
}
