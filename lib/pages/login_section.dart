import 'package:doctor/main.dart';
import 'package:doctor/pages/home.dart';
import 'package:doctor/pages/mypatient.dart';
import 'package:doctor/pages/reset_password.dart';
import 'package:doctor/pages/signup_section.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

class login_section extends StatefulWidget {
  const login_section({super.key});

  @override
  State<login_section> createState() => _login_sectionState();
}

class _login_sectionState extends State<login_section> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String? _email, _password;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 20.0),
                child: Image.asset("assets/login_photo.jpeg"),
              ),
              SizedBox(
                height: 40,
              ),
              Row(
                children: [
                  Text(
                    "Login",
                    style: TextStyle(fontFamily: 'Poppins',fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                  Padding(padding: EdgeInsets.only(left: 10)),
                ],
              ),
              SizedBox(
                height: 32,
              ),
              Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
                          }
                          if (!RegExp(r'\S+@\S+\.\S+').hasMatch(value)) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                        onSaved: (value) {
                          _email = value!.trim();
                        },
                        decoration: InputDecoration(
                          hintText: "Enter your email",
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      TextFormField(
                        obscureText: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          return null;
                        },
                        onSaved: (value) {
                          _password = value!.trim();
                        },
                        decoration: InputDecoration(
                          hintText: "Enter your password",
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  )),
              SizedBox(
                height: 30,
              ),
              SizedBox(
                width: double.infinity,
                child: CustomButton(
                  text: "Log in",
                  onPressed: _submit,
                ),
              ),
              Row(
                textDirection: TextDirection.rtl,
                children: [
                  TextButton(
                    child: Text(
                      "Forget Password?",
                      style: TextStyle(color: primaryColor),
                    ),
                    onPressed: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => Reset_Password()));
                    },
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Expanded(
                    child: FilledButton.tonalIcon(
                      onPressed: () => signUpWithGoogle(context),
                      icon: const Icon(IconlyLight.login),
                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all<Color>(Colors.grey.shade200),
                        foregroundColor: MaterialStateProperty.all<Color>(Colors.black), // Set text and icon color
                      ),
                      label: const Text("Continue with Google"),
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Don't have account?",
                    style: TextStyle(color: Colors.grey),
                  ),
                  TextButton(
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => SignupSection()));
                      },
                      child: Text(
                        "Sign Up",
                        style: TextStyle(
                            color: primaryColor,
                            fontWeight: FontWeight.bold),
                      )),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      try {
        UserCredential userCredential = await FirebaseAuth.instance
            .signInWithEmailAndPassword(email: _email!, password: _password!);
        User? user = FirebaseAuth.instance.currentUser;
        String uid = user!.uid;
        SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.setBool('isUserLoggedIn', true);
        prefs.setString("uid", uid);
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) => HomeSection()));
      } on FirebaseAuthException catch (e) {
        if (e.code == 'user-not-found') {
          print("User doesn't exist");
        } else if (e.code == 'wrong-password') {
          print('Password is incorrect');
        }
      }
    }
  }
}


Future<UserCredential?> signUpWithGoogle(BuildContext context) async {
  try {
    final GoogleSignInAccount? googleSignInAccount = await GoogleSignIn().signIn();
    final GoogleSignInAuthentication googleSignInAuthentication =
    await googleSignInAccount!.authentication;

    final OAuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleSignInAuthentication.accessToken,
      idToken: googleSignInAuthentication.idToken,
    );

    final UserCredential userCredential =
    await FirebaseAuth.instance.signInWithCredential(credential);

    // Navigate to the home page
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => HomeSection(),
      ),
    );

    return userCredential;
  } catch (e) {
    // Handle any errors during the sign-in process
    if (kDebugMode) {
      print("Error signing in with Google: $e");
    }
    return null;
  }
}