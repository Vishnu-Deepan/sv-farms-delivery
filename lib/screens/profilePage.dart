import 'package:flutter/material.dart';

import '../controller/profilePageLogic.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late ProfilePageLogic _logic;  // Create an instance of the logic class

  @override
  void initState() {
    super.initState();
    _logic = ProfilePageLogic(context, setState);  // Initialize logic
    _logic.fetchUserData();  // Fetch user data
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            onPressed: () => _logic.logout(), // Logout action
            icon: const Icon(Icons.logout),
            color: Colors.white
            ,
          ),
        ],
      ),
      body: _logic.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Picture (Optional)
              Center(
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.grey[200],
                  child: Icon(
                    Icons.person,
                    size: 80,
                    color: Colors.teal,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Profile Info Section
              _buildProfileInfo("Name", _logic.name),
              const SizedBox(height: 20),
              _buildProfileInfo("Email", _logic.email),
              const SizedBox(height: 20),
              _buildProfileInfo("Phone", _logic.phone),
              const SizedBox(height: 20),
              _buildProfileInfo("Delivery Area", _logic.area),
              const SizedBox(height: 40),

              // Contact Admin Button
              Center(
                child: ElevatedButton(
                  onPressed: () => _logic.contactAdmin(), // Handle contact admin
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 60),
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text("Contact Admin",style: TextStyle(color: Colors.white),),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper function to build profile information text with better styling
  Widget _buildProfileInfo(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Text(
          "$label: ",
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.teal,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              color: Colors.black87,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
