import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:doctor/main.dart';
import 'package:doctor/pages/home.dart';
import 'package:doctor/pages/login_section.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/image_picker.dart';

class Profile extends StatefulWidget {
  const Profile({Key? key}) : super(key: key);

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  final User? _user = FirebaseAuth.instance.currentUser;
  String? _userName = ""; // Initialize with an empty string

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    // Fetch the user's name from Firestore based on their UID
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(_user!.uid).get();
      setState(() {
        _userName = userDoc.get('name'); // Retrieve the 'name' field from Firestore
      });
    } catch (e) {
      if (kDebugMode) {
        print("Error fetching user name: $e");
      }
      setState(() {
        _userName = "User Name"; // Fallback or default value
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("My profile",
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20)),
        backgroundColor: primaryColor,
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 20, bottom: 15),
            child: CircleAvatar(
              radius: 62,
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: CircleAvatar(
                radius: 60,
                foregroundImage: NetworkImage(_user?.photoURL ?? 'https://firebasestorage.googleapis.com/v0/b/agriplant-c66c1.appspot.com/o/images%2Fistockphoto-1337144146-612x612.jpg?alt=media&token=96b5e4b2-27d5-4f1a-8fde-2635d67f999f'), // Replace with your dummy image URL
              ),
            ),
          ),
          Center(
            child: Text(
              _userName ?? "User Name", // Display the fetched user name
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          Center(
            child: Text(
              _user?.email ?? "user@example.com",
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          const SizedBox(height: 25),
          ListTile(
            title: const Text("Settings"),
            leading: const Icon(IconlyLight.bag),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => HomeSection(),
                ),
              );
            },
          ),
          ListTile(
            title: const Text("About us"),
            leading: const Icon(IconlyLight.infoSquare),
            onTap: () {},
          ),
          ListTile(
            title: const Text("Logout"),
            leading: const Icon(IconlyLight.logout),
            onTap: () async {
              await _logout();
              // Navigate to the home page
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const login_section(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}


Future<void> _logout() async {
  final GoogleSignIn googleSignIn = GoogleSignIn();
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;

  try {
    await googleSignIn.signOut();
    await firebaseAuth.signOut();
    // Additional cleanup or navigation if needed
  } catch (error) {
    if (kDebugMode) {
      print("Error during logout: $error");
    }
  }
}