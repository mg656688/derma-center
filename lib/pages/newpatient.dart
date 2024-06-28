import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:doctor/main.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'mypatient.dart';

class NewPatient extends StatefulWidget {
  const NewPatient({Key? key});

  @override
  State<NewPatient> createState() => _NewPatientState();
}

class _NewPatientState extends State<NewPatient> {

  String uid = " ";
  bool isLoading = false;
  late String prediction = '';
  final ImagePicker picker = ImagePicker();
  File? _image;


  Future getData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String user_uid = prefs.getString('uid') ?? '';
    setState(() {
      uid = user_uid;
    });
  }

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _birthController = TextEditingController();
  final TextEditingController _numberController = TextEditingController();



  // Add a date format for displaying the date
  final DateFormat _dateFormat = DateFormat('MM/dd/yyyy');

  Future<void> _pickDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (pickedDate != null) {
      setState(() {
        _birthController.text = _dateFormat.format(pickedDate);
      });
    }
  }



  Future<void> _submit() async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('patients')
          .add({
        'name': _nameController.text,
        'date_of_birth': _birthController.text,
        'phone': _numberController.text,
        'gender': _selectGender,
        'doctor_uid': uid,
        'rates': {
          'Temperature': "0",
          'blood': "0",
          'glucose': "0",
        },
        'scans': [] // Initialize scans as an empty array
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Patient added successfully')));
    } on FirebaseFirestore catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e as String)));
    }
  }


  String _selectGender = "Male";

  void runPhoto() {
    _image == null ? Icon(Icons.abc) : FileImage(_image!);
  }


  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Derma Center",
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20)),
        backgroundColor: primaryColor,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: 32,
          ),
          Text(
              style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18),
              'Add new patient'
          ),
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            keyboardType: TextInputType.name,
                            controller: _nameController,
                            validator: (value) {
                              if (value!.isEmpty) {
                                return 'Please enter patient name';
                              }
                              return null;
                            },
                            decoration: InputDecoration(
                              hintText: "Enter patient name",
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                      10)),
                            ),
                          ),
                          SizedBox(
                            height: 10,
                          ),
                          // Update birth date field to use the date picker
                          TextFormField(
                            controller: _birthController,
                            readOnly: true,
                            onTap: () => _pickDate(context),
                            validator: (value) {
                              if (value!.isEmpty) {
                                return 'Please enter patient date of birth ';
                              }
                              return null;
                            },
                            decoration: InputDecoration(
                              hintText: "MM/DD/YYYY",
                              labelText: "Enter Date of birth",
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10)),
                              suffixIcon: Icon(Icons.calendar_today),
                            ),
                          ),
                          SizedBox(
                            height: 10,
                          ),
                          TextFormField(
                            keyboardType: TextInputType.number,
                            controller: _numberController,
                            validator: (value) {
                              if (value!.isEmpty) {
                                return 'please enter patient number';
                              }
                              return null;
                            },
                            decoration: InputDecoration(
                              hintText: "Enter phone number",
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                      10)),
                            ),
                          ),
                          SizedBox(
                            height: 10,
                          ),

                        ],
                      )),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Expanded(
                        child: RadioListTile(
                          title: Text(
                            'Male',
                            style: TextStyle(
                                color: _selectGender == "Male"
                                    ? primaryColor
                                    : Colors.grey),
                          ),
                          activeColor: primaryColor,
                          value: "Male",
                          groupValue: _selectGender,
                          onChanged: (newValue) {
                            setState(() {
                              _selectGender = newValue!;
                            });
                          },
                        ),
                      ),
                      Expanded(
                        child: RadioListTile(
                          title: Text(
                            'Female',
                            style: TextStyle(
                                color: _selectGender == "Female"
                                    ? Colors.deepPurpleAccent
                                    : Colors.grey),
                          ),
                          activeColor: Colors.deepPurpleAccent,
                          value: "Female",
                          groupValue: _selectGender,
                          onChanged: (newValue) {
                            setState(() {
                              _selectGender = newValue!;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 32,),
                  CustomButton(
                    text: "Add patient",
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        return _submit();
                      }
                    },
                  )
                ],
              ),
            ),

          ),
        ],
      ),
    );
  }
}

