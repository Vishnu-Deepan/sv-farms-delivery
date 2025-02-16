import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sv_farms_delivery/screens/loginPage.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfilePageLogic {
  final BuildContext context;
  final Function setState;

  // Variables to hold user data
  String name = "";
  String email = "";
  String phone = "";
  String area = "";
  bool isLoading = true;

  ProfilePageLogic(this.context, this.setState);

  // Fetch user data from Firestore using logged-in user's ID
  Future<void> fetchUserData() async {
    try {
      // Get the current logged-in user's ID
      String uid = FirebaseAuth.instance.currentUser?.uid ?? "";

      // Fetch user data from the Firestore collection
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('deliveryPersons')
          .doc(uid)
          .get();

      // Update state with the fetched data
      if (userDoc.exists) {
        setState(() {
          name = userDoc['name'] ?? 'N/A';
          email = userDoc['email'] ?? 'N/A';
          phone = userDoc['phone'] ?? 'N/A';
          area = userDoc['area'] ?? 'N/A';
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      // Handle error if needed (e.g., show a Snackbar)
    }
  }

  // Logout functionality
  void logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      // Optionally clear session or navigate to the login page
      Navigator.pushReplacement(context, MaterialPageRoute<void>(
        builder: (BuildContext context) => const LoginPage(),
      ),);  // Navigate to login page
    } catch (e) {
      // Handle error during logout if needed
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error logging out: $e')),
      );
    }
  }

  // Contact Admin functionality (e.g., open email or support page)
  void contactAdmin() async{
    // Implement contact admin logic (e.g., open email, support chat, etc.)

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Contacting Admin...')),
    );
    final String supportPhoneNumber =
        'tel:+919080700123'; // Actual support number
    Uri supportPhoneNumberUrl = Uri.parse(supportPhoneNumber);

      if (await canLaunchUrl(supportPhoneNumberUrl)) {
        await launchUrl(supportPhoneNumberUrl);
      } else {
        throw 'Could not launch $supportPhoneNumber';
      }


  }
}
