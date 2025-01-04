import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/shared_preferences_helper.dart';
import 'loginPage.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String startDeliveryButtonText = "";
  bool isDayStarted = false;
  bool isStartButtonVisible = false;

  List<Map<String, dynamic>> deliveryQueue = [
    {
      'name': 'John Doe',
      'address': '123 Main St',
      'lat': 40.7128,
      'lng': -74.0060,
      'status': 'pending'
    },
    {
      'name': 'Jane Smith',
      'address': '456 Oak St',
      'lat': 34.0522,
      'lng': -118.2437,
      'status': 'pending'
    },
    {
      'name': 'Sam Wilson',
      'address': '789 Pine St',
      'lat': 51.5074,
      'lng': -0.1278,
      'status': 'completed'
    },
  ];

  int get deliveriesToday => deliveryQueue.length;
  int get pendingDeliveries =>
      deliveryQueue.where((delivery) => delivery['status'] == 'pending').length;
  int get delivered => deliveryQueue
      .where((delivery) => delivery['status'] == 'completed')
      .length;

  late Timer _timer;
  String timeRemaining = "";

  @override
  void initState() {
    super.initState();
    getStartDeliveryButtonText();
  }

  @override
  void dispose() {
    _timer.cancel(); // Dispose of the timer when the page is removed from the stack
    super.dispose();
  }

  void startDay() {
    setState(() {
      isDayStarted = true;
    });
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Delivery Day Started!')));
  }

  void endDay() {
    setState(() {
      isDayStarted = false;
    });
  }

  Future<void> locateOnMap(int index) async {
    double lat = deliveryQueue[index]['lat'];
    double lng = deliveryQueue[index]['lng'];
    final mapUrl = 'https://maps.google.com/?q=$lat,$lng';

    if (await canLaunch(mapUrl)) {
      await launch(mapUrl);
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Could not open map")));
    }
  }

  void markAsCompleted(int index) {
    setState(() {
      if (deliveryQueue[index]['status'] == 'pending') {
        deliveryQueue[index]['status'] = 'completed';
      }
    });
  }

  void markAsSkipped(int index) {
    setState(() {
      if (deliveryQueue[index]['status'] == 'pending') {
        deliveryQueue[index]['status'] = 'completed';
      }
    });
  }

  // This method checks the current time and sets the appropriate button text
  void getStartDeliveryButtonText() {
    final currentTime = DateTime. parse('2025-01-04 05:18:04Z');
    final hour = currentTime.hour;

    if (hour >= 5 && hour < 7) {
      setState(() {
        isStartButtonVisible = true;
        startDeliveryButtonText = 'Start Morning Delivery';
      });
    } else if (hour >= 15 && hour < 17) {
      setState(() {
        isStartButtonVisible = true;
        startDeliveryButtonText = 'Start Evening Delivery';
      });
    } else {
      setState(() {
        isStartButtonVisible = false;
      });
      startCountdownTimer();
    }
  }

  void startCountdownTimer() {
    // Get the next delivery start time and initialize the timer
    final nextDeliveryTime = getNextDeliveryTime();
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      final remainingTime = nextDeliveryTime.difference(DateTime.now());
      if (remainingTime.inSeconds <= 0) {
        setState(() {
          timeRemaining = "Delivery Time Now!";
        });
        _timer.cancel();
      } else {
        setState(() {
          timeRemaining = formatDuration(remainingTime);
        });
      }
    });
  }

  DateTime getNextDeliveryTime() {
    final currentTime = DateTime.now();
    DateTime nextDeliveryTime;

    if (currentTime.hour < 5) {
      nextDeliveryTime = DateTime(currentTime.year, currentTime.month, currentTime.day, 5, 0);
    } else if (currentTime.hour < 7) {
      nextDeliveryTime = DateTime(currentTime.year, currentTime.month, currentTime.day, 5, 0);
    } else if (currentTime.hour < 15) {
      nextDeliveryTime = DateTime(currentTime.year, currentTime.month, currentTime.day, 15, 0);
    } else {
      nextDeliveryTime = DateTime(currentTime.year, currentTime.month, currentTime.day + 1, 5, 0);
    }

    return nextDeliveryTime;
  }

  String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;
    return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      appBar: AppBar(
        backgroundColor: Colors.grey[900],
        actions: [
          IconButton(
            onPressed: () async {
              try {
                await FirebaseAuth.instance.signOut();
                SharedPreferencesHelper.clearSession();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => LoginPage()),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Error logging out: ${e.toString()}")),
                );
              }
            },
            icon: Icon(Icons.logout_rounded),
          ),
        ],
        title: const Text('SV Farms Delivery',
            style: TextStyle(color: Colors.white)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isDayStarted) ...[
              if (isStartButtonVisible) Center(
                child: ElevatedButton(
                  onPressed: startDay,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    padding: EdgeInsets.symmetric(vertical: 15, horizontal: 30),
                    textStyle: TextStyle(fontSize: 18),
                  ),
                  child: Text(
                    startDeliveryButtonText,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
            if (isDayStarted) ...[
              Text(
                'Dashboard Overview',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildDashboardStat(
                      'Today\'s Deliveries', '$deliveriesToday'),
                  _buildDashboardStat(
                      'Pending Deliveries', '$pendingDeliveries'),
                  _buildDashboardStat('Delivered', '$delivered'),
                ],
              ),
              const SizedBox(height: 30),
              Text(
                'Delivery Queue',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: deliveryQueue.isEmpty
                    ? Center(
                    child: Text("No Deliveries Today",
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)))
                    : ListView.builder(
                  itemCount: deliveryQueue.length,
                  itemBuilder: (context, index) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      color: Colors.grey[850],
                      elevation: 8,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  flex: 2,
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        deliveryQueue[index]['name'],
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.lightBlueAccent,
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        deliveryQueue[index]['address'],
                                        style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.white),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  mainAxisAlignment:
                                  MainAxisAlignment.center,
                                  children: [
                                    if (deliveryQueue[index]['status'] == 'pending')
                                      ElevatedButton.icon(
                                        onPressed: () => locateOnMap(index),
                                        icon: Icon(
                                          Icons.navigation_outlined,
                                          color: Colors.white,
                                        ),
                                        label: Text(
                                          'Open in\nGoogle Map',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          padding: EdgeInsets.symmetric(
                                              vertical: 10,
                                              horizontal: 12),
                                          backgroundColor:
                                          Colors.blueAccent,
                                          textStyle:
                                          TextStyle(fontSize: 14),
                                        ),
                                      ),
                                    if (deliveryQueue[index]['status'] == 'completed') ...[
                                      Icon(Icons.done_all,
                                          color: Colors.green, size: 30),
                                      const SizedBox(height: 8),
                                      Text('Completed',
                                          style: TextStyle(
                                              fontWeight: FontWeight.w800,
                                              color: Colors.green)),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                            if (deliveryQueue[index]['status'] == 'pending') ...[
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: () =>
                                        markAsCompleted(index),
                                    icon: Icon(Icons.check_circle,
                                        color: Colors.white),
                                    label: Text('Completed',style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                    ),),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      padding: EdgeInsets.symmetric(
                                          vertical: 10, horizontal: 12),
                                      textStyle: TextStyle(fontSize: 14),
                                    ),
                                  ),
                                  ElevatedButton.icon(
                                    onPressed: () => markAsSkipped(index),
                                    icon: Icon(Icons.skip_next_outlined,
                                        color: Colors.white),
                                    label: Text('Skipped',style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                    ),),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      padding: EdgeInsets.symmetric(
                                          vertical: 10, horizontal: 12),
                                      textStyle: TextStyle(fontSize: 14),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: endDay,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    padding: EdgeInsets.symmetric(vertical: 15, horizontal: 30),
                    textStyle: TextStyle(fontSize: 18),
                  ),
                  child: const Text('End Day',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),),
                ),
              ),
            ],
            if (!isStartButtonVisible) ...[
              Spacer(),
              Center(
                child: Text(
                  "Next Delivery Slot\nStarts in\n\n$timeRemaining",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              Spacer(),

            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardStat(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
              color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 5),
        Text(
          value,
          style: TextStyle(
              color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
