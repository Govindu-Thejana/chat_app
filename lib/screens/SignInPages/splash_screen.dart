import 'package:chat_app/providers/user_provider.dart';
import 'package:chat_app/screens/SignInPages/loging_screen.dart';
import 'package:chat_app/screens/SignInPages/sign_up.dart';
import 'package:chat_app/screens/main_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    listenauthState();
  }

  Future<void> listenauthState() async {
    FirebaseAuth.instance.authStateChanges().listen((User? user) async {
      if (!mounted) return; // Ensure widget is still in the widget tree

      if (user == null) {
        Logger().i('User is currently signed out!');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      } else {
        try {
          Logger().i('User is signed in!');
          Logger().i(user);

          // Update user online status
          await Provider.of<UserProvider>(context, listen: false)
              .updateUserOnlineStatus(user.uid, true);

          // Fetch user data
          Map<String, dynamic>? userInfo = await fetchUserData(user.uid);

          if (!mounted) return; // Ensure widget is still in the widget tree

          if (userInfo != null) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomePage()),
            );
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const SignUpPage()),
            );
          }
        } catch (e) {
          Logger().e('An error occurred: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('An error occurred: $e')),
            );
          }
          await FirebaseAuth.instance.signOut();
        }
      }
    });
  }

  Future<Map<String, dynamic>?> fetchUserData(String uid) async {
    DocumentSnapshot doc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (doc.exists) {
      return doc.data() as Map<String, dynamic>?;
    } else {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Center(
            child: Container(
              width: 500.0,
              height: 500.0,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/new_logo.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const CupertinoActivityIndicator(
            color: Color.fromARGB(255, 23, 22, 22),
            radius: 12,
          )
        ],
      ),
    );
  }
}
