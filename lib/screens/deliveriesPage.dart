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
    Future.delayed(Duration(seconds: 1), ()
    {
      _loadDeliveryPersonId();
    });
  }

  // Load the logged-in delivery person's ID from shared preferences
  Future<void> _loadDeliveryPersonId() async {
    print("Step 1: Loading delivery person's ID from SharedPreferences.");
    Map<String, String?> userSession =
        await SharedPreferencesHelper.getUserSession();
    String? deliveryPersonId = userSession['userId']; // Get the deliveryPersonId

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

    print(
        "Step 2: Querying subscriptions collection for assignedDeliveryPerson: $_deliveryPersonId");

    try {
      QuerySnapshot subscriptionsSnapshot = await FirebaseFirestore.instance
          .collection('subscriptions')
          .where('assignedDeliveryPerson', isEqualTo: _deliveryPersonId)
          .where('isActivePlan', isEqualTo: true)
          .get();

      print(
          "Step 2 Complete: Fetched subscriptions. Count: ${subscriptionsSnapshot.docs.length}");

      if (subscriptionsSnapshot.docs.isEmpty) {
        print(
            "No subscriptions found for delivery person ID: $_deliveryPersonId");
      } else {
        for (var subscriptionDoc in subscriptionsSnapshot.docs) {
          print("Step 3: Processing subscription ID: ${subscriptionDoc.id}");

          // Retrieve the uid and userName from the subscription document
          String userId = subscriptionDoc['uid'];
          String userName = subscriptionDoc['userName'];
          String address = subscriptionDoc['fullAddress'];
          print(
              "Step 3: Retrieved UID: $userId, UserName: $userName, Address: $address");

          _userSubscriptions.add({
            'subscriptionId': subscriptionDoc.id,
            'userName': userName,
            'address': address,
            'morningLitres': subscriptionDoc['morningLitres'],
            'eveningLitres': subscriptionDoc['eveningLitres'],
            'remainingLitres': subscriptionDoc['remainingLitres'],
            'userPhone': subscriptionDoc['userPhone']
          });

          print("Step 5: Added user subscription details to the list.");
        }
      }
      setState(() {});
    } catch (e) {
      print("Error fetching subscriptions: $e");
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
                var subscription = _userSubscriptions[index];
                String userName = subscription['userName'];
                String subscriptionId = subscription['subscriptionId'];
                String address = subscription['address'];
                var remainingLitres = subscription['remainingLitres'];
                var morningLitres = subscription['morningLitres'];
                var eveningLitres = subscription['eveningLitres'];

                print(
                    "Step 7: Building ListTile for subscription ID: $subscriptionId");

                return Card(
                  margin:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                        16), // More rounded corners for a modern look
                  ),
                  color: Colors.grey[900], // Background color for the card
                  elevation: 8, // More elevation for a raised effect
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // User Name and Address

                        Center(
                          child: Text(
                            userName,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: Colors.lightBlueAccent,
                            ),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          address,
                          style: TextStyle(
                              fontSize: 16,
                              color: Colors.white70,
                              fontWeight: FontWeight.bold),
                        ),

                        const SizedBox(height: 12),

                        // Remaining Litres Section - Eye-catching design
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Remaining Litres:',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.orangeAccent,
                              ),
                            ),
                            Text(
                              "$remainingLitres Litres",
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Morning and Evening Litres Section - Larger text and bold
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Morning Delivery:',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.lightGreenAccent,
                                  ),
                                ),
                                Text(
                                  "$morningLitres Litres",
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Evening Delivery:',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.lightBlueAccent,
                                  ),
                                ),
                                Text(
                                  "$eveningLitres Litres",
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
