import 'package:chat_app/controlers/user_controler.dart';
import 'package:chat_app/screens/SignInPages/loging_screen.dart';
import 'package:chat_app/screens/main_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:logger/logger.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final UserController _userController = UserController();
  final Logger _logger = Logger();

  String? _username;
  String? _mobileNumber;
  String? _email;
  String? _password;
  String? _bio;
  String? _location;
  final List<String> _interests = [];
  String? _errorMessage;

  Future<void> _signUp(context) async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      try {
        await _userController.signUp(
          username: _username!,
          mobileNumber: _mobileNumber!,
          email: _email!,
          password: _password!,
          bio: _bio ?? '',
          location: _location ?? '',
          interests: _interests,
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      } catch (error) {
        setState(() {
          _errorMessage = error.toString();
        });
      }
    } else {
      _logger.w("Form validation failed.");
    }
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA), // Soft background color
      // Light background for consistency
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: SizedBox(
            width: double.infinity,
            height: size.height,
            child: Stack(
              alignment: Alignment.center,
              children: <Widget>[
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    // Add the logo at the top
                    Padding(
                      padding: const EdgeInsets.only(top: 40, bottom: 20),
                      child: Image.asset(
                        "assets/new_logo.png", // Path to your logo in the assets folder
                        height: 240, // Adjust the height as needed
                      ),
                    ),

                    // Title: REGISTER
                    Container(
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Text(
                        "REGISTER",
                        style: GoogleFonts.acme(
                          fontWeight: FontWeight.bold,
                          color: Colors.purpleAccent,
                          fontSize: 42,
                        ),
                        textAlign: TextAlign.left,
                      ),
                    ),
                    SizedBox(height: size.height * 0.03),

                    // Username Field
                    Container(
                      alignment: Alignment.center,
                      margin: const EdgeInsets.symmetric(horizontal: 40),
                      child: TextFormField(
                        decoration:
                            const InputDecoration(labelText: "UserName"),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your username';
                          }
                          return null;
                        },
                        onSaved: (value) {
                          _username = value;
                        },
                      ),
                    ),
                    SizedBox(height: size.height * 0.03),

                    // Mobile Number Field
                    Container(
                      alignment: Alignment.center,
                      margin: const EdgeInsets.symmetric(horizontal: 40),
                      child: TextFormField(
                        keyboardType: TextInputType.number,
                        decoration:
                            const InputDecoration(labelText: "Mobile Number"),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your mobile number';
                          }
                          return null;
                        },
                        onSaved: (value) {
                          _mobileNumber = value;
                        },
                      ),
                    ),
                    SizedBox(height: size.height * 0.03),

                    // Email Field
                    Container(
                      alignment: Alignment.center,
                      margin: const EdgeInsets.symmetric(horizontal: 40),
                      child: TextFormField(
                        decoration: const InputDecoration(labelText: "Email"),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
                          }
                          return null;
                        },
                        onSaved: (value) {
                          _email = value;
                        },
                      ),
                    ),
                    SizedBox(height: size.height * 0.03),

                    // Password Field
                    Container(
                      alignment: Alignment.center,
                      margin: const EdgeInsets.symmetric(horizontal: 40),
                      child: TextFormField(
                        decoration:
                            const InputDecoration(labelText: "Password"),
                        obscureText: true,
                        validator: (value) {
                          if (value == null || value.length < 6) {
                            return 'Password must be at least 6 characters long';
                          }
                          return null;
                        },
                        onSaved: (value) {
                          _password = value;
                        },
                      ),
                    ),

                    // Error Message
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 40, vertical: 10),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    SizedBox(height: size.height * 0.05),
                    // Sign Up Button
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: ElevatedButton(
                        onPressed: () {
                          _signUp(
                              context); // Calls the _signUp method defined in your class
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purpleAccent, // Button color
                          padding: const EdgeInsets.symmetric(
                              vertical: 14), // Button height
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(12), // Rounded corners
                          ),
                          minimumSize: const Size(
                              double.infinity, 50), // Full-width button
                        ),
                        child: const Text(
                          "Sign Up",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white, // Text color
                          ),
                        ),
                      ),
                    ),

                    // Already Have an Account? Sign In
                    Container(
                      alignment: Alignment.centerRight,
                      margin: const EdgeInsets.symmetric(
                          horizontal: 50, vertical: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          const Text(
                            "Already Have an Account?  ",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const LoginScreen(),
                                ),
                              );
                            },
                            child: const Text(
                              "Sign In",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.purpleAccent,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
