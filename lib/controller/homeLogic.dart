import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../screens/loginPage.dart';
import '../services/shared_preferences_helper.dart';

class HomePageLogic {
  final BuildContext context;
  final Function setState;

  HomePageLogic(this.context, this.setState);

  String startDeliveryButtonText = "";
  bool isDayStarted = false;
  bool isStartButtonVisible = false;
  bool isLoading = true;
  List<Map<String, dynamic>> deliveryQueue = [];
  int get deliveriesToday => deliveryQueue.length;
  int get pendingDeliveries => deliveryQueue.where((delivery) => ((delivery['deliveryStatus'] == 'pending') && (delivery['skipStatus'] == 'pending'))).length;
  int get delivered => deliveryQueue.where((delivery) => ((delivery['deliveryStatus'] == 'completed') || (delivery['deliveryStatus'] == 'completed'))).length;
  late Timer _timer;
  bool isTimerStarted = false;
  String timeRemaining = "";

  Future<void> initState() async {
    await _initializeDayStatus();
    getStartDeliveryButtonText();
    fetchDeliveryQueue();
  }

  Future<void> _initializeDayStatus() async {
    try {
      // Get the user ID from Firebase Auth
      String uid = FirebaseAuth.instance.currentUser?.uid ?? "";
      print("UID: $uid");  // Debug print to show the user ID

      if (uid.isNotEmpty) {
        // Fetch user document from Firestore
        DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('deliveryPersons').doc(uid).get();
        print("User document fetched: ${userDoc.exists}");  // Check if user document exists

        if (userDoc.exists) {
          bool isDeliveryStarted = userDoc['isDeliveryStarted'] ?? false;
          print("isDeliveryStarted: $isDeliveryStarted");  // Debug print for 'isDeliveryStarted'

          // Check if it's a valid delivery time window
          bool isNotDeliveryTime = (DateTime.now().hour > 10 && DateTime.now().hour < 14) || (DateTime.now().hour > 20 && DateTime.now().hour < 2);
          print("isNotDeliveryTime: $isNotDeliveryTime");  // Debug print for time check

          // If delivery has started and it's outside of the delivery time window, end the day
          if (isDeliveryStarted && isNotDeliveryTime) {
            print("Ending the day...");  // Debug print before ending the day
            endDay();
            setState(() {
              isDeliveryStarted = false;  // Update state
              isDayStarted = false;  // Update state
            });
          } else {
            print("Starting button should be visible now.");  // Debug print when the start button should be visible
            setState(() {
              isStartButtonVisible = true;  // Show the start button
              isDayStarted = false;
            });
          }
        } else {
          print("User document does not exist.");  // Debug print if the document is not found
        }
      } else {
        print("User ID is empty.");  // Debug print if UID is empty
      }
    } catch (e) {
      print("Error fetching data: $e");  // Print any errors that occur during the process
    }
  }

  Future<void> fetchDeliveryQueue() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final uid = user.uid;

      final subscriptionSnapshot = await FirebaseFirestore.instance.collection('subscriptions').where('assignedDeliveryPerson', isEqualTo: uid).where('isActivePlan', isEqualTo: true).get();
      final currentTime = DateTime.now();
      print("fetchDeliveryQueue current time is : ${currentTime.toString()}");
      final isMorning = currentTime.hour < 12;
      print("Time is : ${currentTime.hour} and boolean is $isMorning");
      final statusField = isMorning ? 'morningDelivered' : 'eveningDelivered';
      final skipStatusField = isMorning ? 'morningSkipped' : 'eveningSkipped';

      List<Map<String, dynamic>> updatedDeliveryQueue = [];
      for (var doc in subscriptionSnapshot.docs) {
        final userName = doc['userName'];
        final fullAddress = doc['fullAddress'];
        final latitude = doc['deliveryLocation']['latitude'];
        final longitude = doc['deliveryLocation']['longitude'];
        final userId = doc['uid'];
        final deliveryLitres = isMorning ? doc['morningLitres'] : doc['eveningLitres'];

        final logSnapshot = await FirebaseFirestore.instance.collection('dailyDeliveryLogs').doc(userId).collection('logs').doc('${currentTime.year}-${currentTime.month.toString().padLeft(2, '0')}-${currentTime.day.toString().padLeft(2, '0')}').get();

        final deliveryStatus = logSnapshot.exists ? (logSnapshot[statusField] ? "completed" : "pending") : 'pending';
        final skipStatus = logSnapshot.exists ? (logSnapshot[skipStatusField] ? "completed" : "pending") : 'pending';

        updatedDeliveryQueue.add({
          'name': userName,
          'address': fullAddress,
          'lat': latitude,
          'lng': longitude,
          'deliveryStatus': deliveryStatus,
          'skipStatus': skipStatus,
          'userId': userId,
          'deliveryLitres': deliveryLitres,
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error fetching delivery queue: $e")));
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

  void logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      SharedPreferencesHelper.clearSession();
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginPage()));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error logging out: ${e.toString()}")));
    }
  }

  void showConfirmationDialog(String actionType) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(actionType == 'start' ? 'Start Day' : 'End Day'),
          content: Text(actionType == 'start' ? 'Are you sure you want to start the day?' : 'Are you sure you want to end the day?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('Cancel', style: TextStyle(color: Colors.red)),
            ),
            TextButton(
              onPressed: () {
                if (actionType == 'start') {
                  startDay();
                } else {
                  endDay();
                }
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text(actionType == 'start' ? 'Yes, Start Day' : 'Yes, End Day', style: TextStyle(color: Colors.green)),
            ),
          ],
        );
      },
    );
  }

  void startDay() {
    String? user = FirebaseAuth.instance.currentUser?.uid;
    setState(() {
      isDayStarted = true;
    });

    FirebaseFirestore.instance.collection("deliveryPersons").doc(user).update({"isDeliveryStarted": true});
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delivery Day Started!')));
  }

  void endDay() {
    String? user = FirebaseAuth.instance.currentUser?.uid;

    setState(() {
      isDayStarted = false;
    });

    FirebaseFirestore.instance.collection("deliveryPersons").doc(user).update({"isDeliveryStarted": false});
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Day has been ended successfully')));
  }

  void locateOnMap(int index) async {
    double lat = deliveryQueue[index]['lat'];
    double lng = deliveryQueue[index]['lng'];
    final mapUrl = 'https://maps.google.com/?q=$lat,$lng';

    if (await canLaunch(mapUrl)) {
      await launch(mapUrl);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Could not open map")));
    }
  }

  void markAsCompleted(int index) async {
    bool isMorningDelivery = DateTime.now().hour < 12;
    String fieldToUpdate = isMorningDelivery ? 'morningDelivered' : 'eveningDelivered';

    if (deliveryQueue[index]['userId'] == null) {
      print('Error: userId is null for the delivery at index $index');
      return;
    }

    // Confirmation dialog
    bool shouldProceed = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Confirm Delivery"),
        content: Text("Are you sure you want to mark this delivery as completed?"),
        actions: <Widget>[
          TextButton(
            child: Text("Cancel"),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          TextButton(
            child: Text("Yes"),
            onPressed: () async {
              final subscriptionSnapshot = await FirebaseFirestore.instance
                  .collection('subscriptions')
                  .where('uid', isEqualTo: deliveryQueue[index]['userId'])
                  .where('isActivePlan', isEqualTo: true)
                  .get();

              if (subscriptionSnapshot.docs.isNotEmpty) {
                final doc = subscriptionSnapshot.docs.first;

                final currentRemainingLitres = doc['remainingLitres'];
                final newRemainingLitres = currentRemainingLitres - deliveryQueue[index]["deliveryLitres"];

                await FirebaseFirestore.instance.collection('subscriptions').doc(doc.id).update({
                  'remainingLitres': newRemainingLitres,
                }).then((_) {
                  print('Successfully updated remainingLitres in Firestore');
                }).catchError((error) {
                  print('Error updating remainingLitres: $error');
                });

                Navigator.of(context).pop(true);
              }
            },
          ),
        ],
      ),
    );

    if (shouldProceed) {
      String userUid = deliveryQueue[index]['userId'];

      FirebaseFirestore.instance.collection("dailyDeliveryLogs").doc(userUid).collection("logs").doc(DateTime.now().toString().split(' ')[0]).update({
        fieldToUpdate: true,
      }).then((value) {
        print('Firestore update successful');
      }).catchError((error) {
        print('Error updating Firestore: $error');
      });

      setState(() {
        deliveryQueue[index]['deliveryStatus'] = 'completed';
      });
    }
  }

  void markAsSkipped(int index) async {
    bool isMorningDelivery = DateTime.now().hour < 12;
    String fieldToUpdate = isMorningDelivery ? 'morningSkipped' : 'eveningSkipped';

    if (deliveryQueue[index]['userId'] == null) {
      print('Error: userId is null for the delivery at index $index');
      return;
    }

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

    if (shouldProceed) {
      String userUid = deliveryQueue[index]['userId'];

      FirebaseFirestore.instance.collection("dailyDeliveryLogs").doc(userUid).collection("logs").doc(DateTime.now().toString().split(' ')[0]).update({
        fieldToUpdate: true,
      }).then((value) {
        print('Firestore update successful');
      }).catchError((error) {
        print('Error updating Firestore: $error');
      });

      setState(() {
        deliveryQueue[index]['skipStatus'] = 'completed';
      });
    }
  }

  void getStartDeliveryButtonText() {
    final currentTime = DateTime.now();
    final hour = currentTime.hour;

    if (hour >= 4 && hour < 8) {
      setState(() {
        isStartButtonVisible = true;
        startDeliveryButtonText = 'Start Morning Delivery';
      });
    } else if (hour >= 14 && hour < 19) {
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

  void dispose() {
    if (isTimerStarted) {
      _timer.cancel();
    }
  }
}
