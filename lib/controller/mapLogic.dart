import 'package:cloud_firestore/cloud_firestore.dart';

class MapLogic{
  Future<List<Map<String, dynamic>>> fetchUserLocations(String deliveryPersonId) async {
    List<Map<String, dynamic>> userLocations = [];
    // Early exit if the delivery person ID is empty
    if (deliveryPersonId.isEmpty) {
      print("Delivery person ID is empty.");
      return userLocations;  // return empty list instead of null
    }

    try {
      QuerySnapshot subscriptionsSnapshot = await FirebaseFirestore.instance
          .collection('subscriptions')
          .where('assignedDeliveryPerson', isEqualTo: deliveryPersonId)
          .where('isActivePlan', isEqualTo: true)
          .get();

      // Check if no subscriptions are found
      if (subscriptionsSnapshot.docs.isEmpty) {
        print("No subscriptions found for delivery person ID: $deliveryPersonId");
        return userLocations;  // return empty list instead of null
      } else {
        // Iterate through the subscription documents
        for (var subscriptionDoc in subscriptionsSnapshot.docs) {
          // Retrieve the required data
          String userId = subscriptionDoc['uid'];
          String userName = subscriptionDoc['userName'];
          String address = subscriptionDoc['fullAddress'];
          double lat = subscriptionDoc['deliveryLocation']['latitude'];
          double lon = subscriptionDoc['deliveryLocation']['longitude'];

          userLocations.add({
            'subscriptionId': subscriptionDoc.id,
            'userName': userName,
            'address': address,
            'lat': lat,
            'lon': lon,
            'userPhone': subscriptionDoc['userPhone'],
          });
        }
        return userLocations;
      }
    } catch (e) {
      print("Error fetching subscriptions: $e");
      return userLocations;  // return empty list in case of error
    }
  }

}