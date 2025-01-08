import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  bool isLoading = true;

  List<Map<String, dynamic>> deliveryQueue = [];
  int get deliveriesToday => deliveryQueue.length;
  int get pendingDeliveries => deliveryQueue
      .where((delivery) => ((delivery['deliveryStatus'] == 'pending') &&
          (delivery['skipStatus'] == 'pending')))
      .length;
  int get delivered => deliveryQueue
      .where((delivery) => ((delivery['deliveryStatus'] == 'completed') ||
          (delivery['deliveryStatus'] == 'completed')))
      .length;

  late Timer _timer;
  bool isTimerStarted = false;
  String timeRemaining = "";

  @override
  void initState() {
    super.initState();
    _initializeDayStatus();
    getStartDeliveryButtonText();
    fetchDeliveryQueue();
  }

  @override
  void dispose() {
    if (isTimerStarted)
      _timer
          .cancel(); // Dispose of the timer when the page is removed from the stack
    super.dispose();
  }

  Future<void> _initializeDayStatus() async {
    try {
      // Get the current user's UID
      String uid = FirebaseAuth.instance.currentUser?.uid ?? "";

      if (uid.isNotEmpty) {
        // Get the document for the current user from Firestore
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('deliveryPersons')
            .doc(uid)
            .get();

        if (userDoc.exists) {
          // Get the value of 'isDeliveryStarted' from the document
          bool isDeliveryStarted = userDoc['isDeliveryStarted'] ?? false;

          // Set the value to isDayStarted
          setState(() {
            isDayStarted = isDeliveryStarted;
          });
        }
      }
    } catch (e) {
      print("Error fetching data: $e");
    }
  }

  Future<void> fetchDeliveryQueue() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return;
      }
      final uid = user.uid;

      // Fetch subscriptions with isActivePlan = true
      final subscriptionSnapshot = await FirebaseFirestore.instance
          .collection('subscriptions')
          .where('assignedDeliveryPerson', isEqualTo: uid)
          .where('isActivePlan', isEqualTo: true)
          .get();

      // Fetch the daily delivery log based on the time
      final currentTime = DateTime.now();
      final isMorning = currentTime.hour < 12;
      final statusField = isMorning ? 'morningDelivered' : 'eveningDelivered';
      final skipStatusField = isMorning ? 'morningSkipped' : 'eveningSkipped';

      List<Map<String, dynamic>> updatedDeliveryQueue = [];

      for (var doc in subscriptionSnapshot.docs) {
        final userName = doc['userName'];
        final fullAddress = doc['fullAddress'];
        final latitude = doc['deliveryLocation']['latitude'];
        final longitude = doc['deliveryLocation']['longitude'];
        final userId = doc['uid'];
        final deliveryLitres =
            isMorning ? doc['morningLitres'] : doc['eveningLitres'];

        print("The document Id is ${doc.id}");
        // Fetch today's log to determine the delivery status
        final logSnapshot = await FirebaseFirestore.instance
            .collection('dailyDeliveryLogs')
            .doc(userId)
            .collection('logs')
            .doc(
                '${currentTime.year}-${currentTime.month.toString().padLeft(2, '0')}-${currentTime.day.toString().padLeft(2, '0')}')
            .get();

        final deliveryStatus = logSnapshot.exists
            ? (logSnapshot[statusField] ? "completed" : "pending")
            : 'pending';
        final skipStatus = logSnapshot.exists
            ? (logSnapshot[skipStatusField] ? "completed" : "pending")
            : 'pending';

        updatedDeliveryQueue.add({
          'name': userName,
          'address': fullAddress,
          'lat': latitude,
          'lng': longitude,
          'deliveryStatus': deliveryStatus,
          'skipStatus': skipStatus,
          'userId': userId,
          'deliveryLitres': deliveryLitres
        });
      }

      setState(() {
        deliveryQueue = updatedDeliveryQueue;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Error fetching delivery queue: $e"),
      ));
    }
  }


  // Function to show the confirmation dialog with dynamic action
  void _showConfirmationDialog(String actionType) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(actionType == 'start' ? 'Start Day' : 'End Day'),
          content: Text(
            actionType == 'start'
                ? 'Are you sure you want to start the day?'
                : 'Are you sure you want to end the day?',
          ),
          actions: [
            // Cancel button
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.red),
              ),
            ),
            // Confirm button
            TextButton(
              onPressed: () {
                if (actionType == 'start') {
                  startDay();
                } else {
                  endDay();
                }
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text(
                actionType == 'start' ? 'Yes, Start Day' : 'Yes, End Day',
                style: TextStyle(color: Colors.green),
              ),
            ),
          ],
        );
      },
    );
  }

  // Start Day function
  void startDay() {
    String? user = FirebaseAuth.instance.currentUser?.uid;
    setState(() {
      isDayStarted = true;
    });

    FirebaseFirestore.instance
        .collection("deliveryPersons")
        .doc(user)
        .update({"isDeliveryStarted": true});

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Delivery Day Started!')));
  }

  // End Day function
  void endDay() {
    String? user = FirebaseAuth.instance.currentUser?.uid;

    setState(() {
      isDayStarted = false;
    });

    FirebaseFirestore.instance
        .collection("deliveryPersons")
        .doc(user)
        .update({"isDeliveryStarted": false});

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Day has been ended successfully')));
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

  void markAsCompleted(int index) async {
    bool isMorningDelivery = DateTime.now().hour < 12;
    String fieldToUpdate =
        isMorningDelivery ? 'morningDelivered' : 'eveningDelivered';

    // Debug print statements
    print('markAsCompleted called');
    print('Current time is: ${DateTime.now()}');
    print('Is it morning delivery? $isMorningDelivery');
    print("Litres reduced: ${deliveryQueue[index]["deliveryLitres"]}");
    print('Field to update: $fieldToUpdate');

    // Check if the uid is not null before proceeding
    if (deliveryQueue[index]['userId'] == null) {
      print('Error: userId is null for the delivery at index $index');
      return; // Exit the function or handle the error appropriately
    }

    // Confirmation dialog
    bool shouldProceed = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Confirm Delivery"),
        content:
            Text("Are you sure you want to mark this delivery as completed?"),
        actions: <Widget>[
          TextButton(
            child: Text("Cancel"),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          TextButton(
            child: Text("Yes"),
            onPressed: () async {
              // Fetch the subscription document where the assignedDeliveryPerson is $uid
              final subscriptionSnapshot = await FirebaseFirestore.instance
                  .collection('subscriptions')
                  .where('uid', isEqualTo: deliveryQueue[index]['userId'])
                  .where('isActivePlan', isEqualTo: true)
                  .get();

              if (subscriptionSnapshot.docs.isNotEmpty) {
                // Get the first matching document
                final doc = subscriptionSnapshot.docs.first;

                // Retrieve the current value of remainingLitres
                final currentRemainingLitres = doc['remainingLitres'];
                print('Current remainingLitres: $currentRemainingLitres');

                // Calculate the new remainingLitres after subtracting deliveryLitres
                print(
                    'Delivered litres: ${deliveryQueue[index]["deliveryLitres"]}');
                final newRemainingLitres = currentRemainingLitres -
                    deliveryQueue[index]["deliveryLitres"];
                print('New remainingLitres: $newRemainingLitres');

                // Update the remainingLitres field in Firestore
                await FirebaseFirestore.instance
                    .collection('subscriptions')
                    .doc(doc.id)
                    .update({
                  'remainingLitres': newRemainingLitres,
                }).then((_) {
                  print('Successfully updated remainingLitres in Firestore');
                }).catchError((error) {
                  print('Error updating remainingLitres: $error');
                });

                // Pop the current screen with 'true'
                Navigator.of(context).pop(true);
              } else {
                // Handle the case where no document was found
                print(
                    "No subscription found for the assigned delivery person.");
              }
            },
          ),
        ],
      ),
    );

    print(
        'Confirmation dialog result: $shouldProceed'); // Debugging dialog result

    if (shouldProceed) {
      // If confirmed, update Firestore
      String userUid = deliveryQueue[index]['userId'];
      print('User UID: $userUid');

      FirebaseFirestore.instance
          .collection("dailyDeliveryLogs")
          .doc(userUid)
          .collection("logs")
          .doc(DateTime.now().toString().split(' ')[0]) // Today's date
          .update({
        fieldToUpdate: true,
      }).then((value) {
        print('Firestore update successful');
      }).catchError((error) {
        print('Error updating Firestore: $error');
      });

      // Update the status locally
      setState(() {
        if (deliveryQueue[index]['deliveryStatus'] == 'pending') {
          print('Updating local status to completed');
          deliveryQueue[index]['deliveryStatus'] = 'completed';
        }
      });

      print(
          'Updated delivery status: ${deliveryQueue[index]['deliveryStatus']}');
    }
  }

  void markAsSkipped(int index) async {
    bool isMorningDelivery = DateTime.now().hour < 12;
    String fieldToUpdate =
        isMorningDelivery ? 'morningSkipped' : 'eveningSkipped';

    // Debug print statements
    print('markAsSkipped called');
    print('Current time is: ${DateTime.now()}');
    print('Is it morning delivery? $isMorningDelivery');
    print('Field to update: $fieldToUpdate');

    // Check if the uid is not null before proceeding
    if (deliveryQueue[index]['userId'] == null) {
      print('Error: userId is null for the delivery at index $index');
      return; // Exit the function or handle the error appropriately
    }

    // Confirmation dialog
    bool shouldProceed = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Confirm Skip"),
        content: Text("Are you sure you want to skip this delivery?"),
        actions: <Widget>[
          TextButton(
            child: Text("Cancel"),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          TextButton(
            child: Text("Yes"),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    print(
        'Confirmation dialog result: $shouldProceed'); // Debugging dialog result

    if (shouldProceed) {
      // If confirmed, update Firestore
      String userUid = deliveryQueue[index]['userId'];
      print('userId: $userUid');

      FirebaseFirestore.instance
          .collection("dailyDeliveryLogs")
          .doc(userUid)
          .collection("logs")
          .doc(DateTime.now().toString().split(' ')[0]) // Today's date
          .update({
        fieldToUpdate: true, // Indicate the delivery was skipped
      }).then((value) {
        print('Firestore update successful');
      }).catchError((error) {
        print('Error updating Firestore: $error');
      });

      // Update the status locally
      setState(() {
        if (deliveryQueue[index]['skipStatus'] == 'pending') {
          print('Updating local status to completed (skipped)');
          deliveryQueue[index]['skipStatus'] =
              'completed'; // Mark as completed (skipped)
        }
      });

      print('Updated delivery status: ${deliveryQueue[index]['skipStatus']}');
    }
  }

  // This method checks the current time and sets the appropriate button text
  void getStartDeliveryButtonText() {
    final currentTime = DateTime(2025, 01, 07, 5, 15);
    // final currentTime = DateTime.now();
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
      isTimerStarted = true;
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
      nextDeliveryTime =
          DateTime(currentTime.year, currentTime.month, currentTime.day, 5, 0);
    } else if (currentTime.hour < 7) {
      nextDeliveryTime =
          DateTime(currentTime.year, currentTime.month, currentTime.day, 5, 0);
    } else if (currentTime.hour < 15) {
      nextDeliveryTime =
          DateTime(currentTime.year, currentTime.month, currentTime.day, 15, 0);
    } else {
      nextDeliveryTime = DateTime(
          currentTime.year, currentTime.month, currentTime.day + 1, 5, 0);
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
              if (isStartButtonVisible)
                Center(
                  child: ElevatedButton(
                    onPressed: () => _showConfirmationDialog('start'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      padding:
                          EdgeInsets.symmetric(vertical: 15, horizontal: 30),
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
                'Today\'s Deliveries',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: isLoading
                    ? Center(child: CircularProgressIndicator())
                    : deliveryQueue.isEmpty
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                                    color:
                                                        Colors.lightBlueAccent,
                                                  ),
                                                ),
                                                const SizedBox(height: 5),
                                                Text(
                                                  deliveryQueue[index]
                                                      ['address'],
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
                                              if ((deliveryQueue[index]
                                                          ['deliveryStatus'] ==
                                                      'pending') &&
                                                  (deliveryQueue[index]
                                                          ['skipStatus'] ==
                                                      'pending'))
                                                ElevatedButton.icon(
                                                  onPressed: () =>
                                                      locateOnMap(index),
                                                  icon: Icon(
                                                    Icons.navigation_outlined,
                                                    color: Colors.white,
                                                  ),
                                                  label: Text(
                                                    'Open in\nGoogle Map',
                                                    textAlign: TextAlign.center,
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                  ),
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                            vertical: 10,
                                                            horizontal: 12),
                                                    backgroundColor:
                                                        Colors.blueAccent,
                                                    textStyle:
                                                        TextStyle(fontSize: 14),
                                                  ),
                                                ),
                                              if ((deliveryQueue[index]
                                                          ['deliveryStatus'] ==
                                                      'completed') ||
                                                  (deliveryQueue[index]
                                                          ['skipStatus'] ==
                                                      'completed')) ...[
                                                Icon(Icons.done_all,
                                                    color: Colors.green,
                                                    size: 30),
                                                const SizedBox(height: 8),
                                                Text('Completed',
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.w800,
                                                        color: Colors.green)),
                                              ],
                                            ],
                                          ),
                                        ],
                                      ),
                                      // Highlight the "Milk to be delivered" with processing
                                      if ((deliveryQueue[index]
                                                  ["deliveryLitres"] !=
                                              null) &&
                                          (deliveryQueue[index]
                                                  ['deliveryStatus'] ==
                                              'pending') &&
                                          (deliveryQueue[index]['skipStatus'] ==
                                              'pending')) ...[
                                        const SizedBox(height: 12),
                                        Center(
                                          child: Text(
                                            _convertLitresToReadableFormat(
                                                deliveryQueue[index]
                                                    ["deliveryLitres"]),
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 20,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                        ),
                                      ],
                                      // Buttons for the status of delivery
                                      if ((deliveryQueue[index]
                                                  ['deliveryStatus'] ==
                                              'pending') &&
                                          (deliveryQueue[index]['skipStatus'] ==
                                              'pending')) ...[
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
                                              label: Text(
                                                'Completed',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w900,
                                                ),
                                              ),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.green,
                                                padding: EdgeInsets.symmetric(
                                                    vertical: 10,
                                                    horizontal: 12),
                                                textStyle:
                                                    TextStyle(fontSize: 14),
                                              ),
                                            ),
                                            ElevatedButton.icon(
                                              onPressed: () =>
                                                  markAsSkipped(index),
                                              icon: Icon(
                                                  Icons.skip_next_outlined,
                                                  color: Colors.white),
                                              label: Text(
                                                'Skipped',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w900,
                                                ),
                                              ),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.red,
                                                padding: EdgeInsets.symmetric(
                                                    vertical: 10,
                                                    horizontal: 12),
                                                textStyle:
                                                    TextStyle(fontSize: 14),
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
                  onPressed: () => _showConfirmationDialog('end'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    padding: EdgeInsets.symmetric(vertical: 15, horizontal: 30),
                    textStyle: TextStyle(fontSize: 18),
                  ),
                  child: const Text(
                    'End Day',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
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
              color: Colors.teal, fontSize: 16, fontWeight: FontWeight.bold),
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

// Function to convert deliveryLitres to a readable format
String _convertLitresToReadableFormat(double litres) {
  if (litres == 0.25) {
    return "250ml";
  } else if (litres == 0.5) {
    return "500ml";
  } else if (litres == 0.75) {
    return "750ml";
  } else if (litres == 1) {
    return "1l";
  } else if (litres == 1.5) {
    return "1.5l";
  } else if (litres == 2) {
    return "2l";
  } else {
    return "${(litres * 1000).toStringAsFixed(0)}ml"; // For any other value
  }
}
