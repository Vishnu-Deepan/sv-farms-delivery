import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/shared_preferences_helper.dart';

class DeliveriesPage extends StatefulWidget {
  @override
  _DeliveriesPageState createState() => _DeliveriesPageState();
}

class _DeliveriesPageState extends State<DeliveriesPage> {
  String _deliveryPersonId = '';
  List<Map<String, dynamic>> _userSubscriptions = [];

  @override
  void initState() {
    super.initState();
    _loadDeliveryPersonId();
  }

  // Load the logged-in delivery person's ID from shared preferences
  Future<void> _loadDeliveryPersonId() async {
    print("Step 1: Loading delivery person's ID from SharedPreferences.");
    Map<String, String?> userSession = await SharedPreferencesHelper.getUserSession();
    String? deliveryPersonId = userSession['userId'];  // Get the deliveryPersonId

    print("Step 1 Complete: Retrieved delivery person ID: $deliveryPersonId");
    setState(() {
      _deliveryPersonId = deliveryPersonId!;
    });
    if (_deliveryPersonId.isNotEmpty) {
      print("Step 2: Delivery person ID found. Fetching user subscriptions...");
      _fetchUserSubscriptions();
    } else {
      print("Error: No delivery person ID found in SharedPreferences.");
    }
  }

  // Fetch user subscriptions from Firestore
  Future<void> _fetchUserSubscriptions() async {
    if (_deliveryPersonId.isEmpty) {
      print("Step 2 Skipped: Delivery person ID is empty.");
      return;
    }

    print("Step 2: Querying subscriptions collection for assignedDeliveryPerson: $_deliveryPersonId");

    try {
      QuerySnapshot subscriptionsSnapshot = await FirebaseFirestore.instance
          .collection('subscriptions')
          .where('assignedDeliveryPerson', isEqualTo: _deliveryPersonId)
          .get();

      print("Step 2 Complete: Fetched subscriptions. Count: ${subscriptionsSnapshot.docs.length}");

      if (subscriptionsSnapshot.docs.isEmpty) {
        print("No subscriptions found for delivery person ID: $_deliveryPersonId");
      } else {
        for (var subscriptionDoc in subscriptionsSnapshot.docs) {
          print("Step 3: Processing subscription ID: ${subscriptionDoc.id}");

          // Retrieve the uid field from the subscription document
          String userId = subscriptionDoc['uid'];
          print("Step 3: Retrieved UID from subscription: $userId");

          // Fetch the daily log for the user
          List<QueryDocumentSnapshot<Object?>>? dailyLog = await getUserDailyLog(userId);
          if (dailyLog != null) {
            print("Step 4: Daily log found for user $userId.");
          } else {
            print("Step 4: No daily log found for user $userId.");
          }

          _userSubscriptions.add({
            'subscription': subscriptionDoc,
            'dailyLog': dailyLog,
          });

          print("Step 5: Added user subscription and daily log to the list.");
        }
      }
      setState(() {});
    } catch (e) {
      print("Error fetching subscriptions: $e");
    }
  }

  // Fetch daily log for a specific user by UID
  Future<List<QueryDocumentSnapshot<Object?>>?> getUserDailyLog(String userId) async {
    print("Step 4: Querying dailyDeliveryLogs for user: $userId");

    try {
      QuerySnapshot dailyLogsSnapshot = await FirebaseFirestore.instance
          .collection('dailyDeliveryLogs')
          .doc(userId)
          .collection('logs')
          .get();

      print("Step 4 Complete: Fetched daily logs for user $userId. Count: ${dailyLogsSnapshot.docs.length}");

      if (dailyLogsSnapshot.docs.isNotEmpty) {
        return dailyLogsSnapshot.docs; // Return the first daily log found
      } else {
        print("Step 4 Complete: No daily logs found for user $userId.");
        return null; // No daily log found
      }
    } catch (e) {
      print("Error fetching daily log for user $userId: $e");
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    print("Step 6: Building DeliveriesPage.");

    return Scaffold(
      appBar: AppBar(title: Text('Deliveries')),
      body: _userSubscriptions.isEmpty
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: _userSubscriptions.length,
        itemBuilder: (context, index) {
          var subscription = _userSubscriptions[index]['subscription'];
          var dailyLog = _userSubscriptions[index]['dailyLog'];

          print("Step 7: Building ListTile for subscription ID: ${subscription.id}");

          if(dailyLog.length!=0) {
            return ListTile(
            title: Text('Subscription ID: ${subscription.id}'),
            subtitle: Text('Days Remaining : ${dailyLog.length}'),
          );
          }
          return null;
        },
      ),
    );
  }
}
