import 'package:flutter/material.dart';
import '../screens/profilePage.dart';
import '../screens/deliveriesPage.dart';
import '../screens/homePage.dart';
import '../screens/mapPage.dart';

class HomeNavBar extends StatefulWidget {
  const HomeNavBar({Key? key}) : super(key: key);

  @override
  State<HomeNavBar> createState() => _HomeNavBarState();
}

class _HomeNavBarState extends State<HomeNavBar> {
  int _selectedIndex = 0;
  final List<Widget> _pages = [
    HomePage(),
    DeliveriesPage(),
    UserLocationMapPage(),
    ProfilePage(),
  ];

  // Function to directly navigate to the last page, skipping intermediate pages
  void navigateToLastPage() {
    setState(() {
      _selectedIndex = 3; // Directly set the selected index to ProfilePage
    });
  }

  // Function to handle item selection in BottomNavigationBar
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;  // Update the selected index
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,  // Display the selected page, without loading intermediate pages
      ),
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey.shade800,
        unselectedLabelStyle: TextStyle(color: Colors.grey.shade800),

        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.delivery_dining),
            label: 'Deliveries',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.location_pin),
            label: 'Map',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Account',
          ),
        ],
      ),
      // Button to navigate directly to the last page (Profile Page)
      floatingActionButton: FloatingActionButton(
        onPressed: navigateToLastPage,
        child: Icon(Icons.navigate_next),
        backgroundColor: Colors.deepPurple,
      ),
    );
  }
}
