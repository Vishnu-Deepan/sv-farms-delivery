// delivery

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shimmer/shimmer.dart';
import '../controller/loginLogic.dart';
import '../widgets/homeNavBar.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final LoginLogic _loginLogic = LoginLogic();  // Initialize LoginLogic

  bool _isLoggingIn = false;  // Flag to control the shimmer effect

  @override
  void initState() {
    super.initState();

    //AUTO LOG IN FOR FASTER TESTING(DELETE AFTER TESTING)
    // _autoLoginTest();

  }

  // AUTO LOGIN FOR TESTING STARTS HERE
  // Future<void> _autoLoginTest() async {
  //   try {
  //     final String _testEmail = 'delivery1@svfarms.com';
  //     final String _testPassword = 'delivery1';
  //     // Use hardcoded credentials for testing (comment this out for production)
  //     final email = _testEmail;
  //     final password = _testPassword;
  //
  //     UserCredential userCredential = await  FirebaseAuth.instance.signInWithEmailAndPassword(
  //       email: email,
  //       password: password,
  //     );
  //
  //     final user = userCredential.user;
  //     if (user != null) {
  //       // Save user session
  //       await SharedPreferencesHelper.saveUserSession(
  //         user.uid,
  //         user.email!
  //       );
  //       Fluttertoast.showToast(msg: "Logged in successfully!");
  //
  //       // Navigate to Home/Dashboard after successful login
  //       Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HomePage()));
  //     }
  //   } catch (e) {
  //     Fluttertoast.showToast(msg: "Login failed. Error: $e");
  //   }
  // }
  // AUTO LOGIN FOR TESTING UNTILL THIS



  // Method to handle the login process
  void _login() async {
    setState(() {
      _isLoggingIn = true;  // Start shimmer effect when login begins
    });

    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    _loginLogic.loginUser(
      email: email,
      password: password,
      onSuccess: () {
        setState(() {
          _isLoggingIn = false;  // Stop shimmer effect when login is successful
        });
        Fluttertoast.showToast(msg: "Logged in successfully!");
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) => HomeNavBar()));
      },
      onFailure: (errorMessage) {
        setState(() {
          _isLoggingIn = false;  // Stop shimmer effect on failure
        });
        Fluttertoast.showToast(msg: errorMessage);
      },
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Image.asset('assets/logo.png', height: 90),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.only(top: 20, bottom: 10),
                child: Text(
                  "Delivery Person LOGIN",
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                    letterSpacing: 2.0,
                    shadows: [
                      Shadow(
                        blurRadius: 10.0,
                        offset: Offset(3.0, 3.0),
                        color: Colors.grey.withValues(alpha: 0.5),
                      ),
                    ],
                  ),
                ),
              ),
              Text(
                'Fresh Milk, Daily Delivered',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 40),

              // Email Input Field
              _buildTextField(_emailController, 'Enter your email'),
              SizedBox(height: 20),

              // Password Input Field
              _buildTextField(_passwordController, 'Enter your password', obscureText: true),
              SizedBox(height: 20),

              // Login Button with shimmer effect
              _isLoggingIn
                  ? Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: Container(
                  width: double.infinity,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Center(
                    child: Text(
                      'Logging In...',
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  ),
                ),
              )
                  : Container(
                width: double.infinity,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: TextButton(
                  onPressed: _login, // This should be your register method
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 15, horizontal: 40),
                  ),
                  child: Text(
                    'Login',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),



            ],
          ),
        ),
      ),
    );
  }

  // Reusable text field widget
  Widget _buildTextField(TextEditingController controller, String hintText, {bool obscureText = false, TextInputType keyboardType = TextInputType.text}) {
    return TextField(
      style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900),
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.black54, fontWeight: FontWeight.w600),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30.0),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      ),
    );
  }
}
