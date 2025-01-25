//delivery
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/loginPage.dart';
import 'services/shared_preferences_helper.dart';
import 'widgets/homeNavBar.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  bool isLoggedIn = await SharedPreferencesHelper.isLoggedIn();
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark.copyWith(
    statusBarColor: Colors.transparent, // Transparent status bar for sleek look
    statusBarIconBrightness: Brightness.dark, // Dark icons in the status bar
  ));
  runApp(MyApp(isLoggedIn: isLoggedIn));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;

  MyApp({required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: isLoggedIn ? HomeNavBar() : LoginPage(),
    );
  }
}




