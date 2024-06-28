import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:doctor/main.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

class Patient_Details extends StatefulWidget {
  Patient_Details(
      {required this.document,
      required this.patientId,
      required this.doctorId});

  final String patientId;
  final String doctorId;
  final DocumentSnapshot document;

  @override
  State<Patient_Details> createState() => _Patient_DetailsState();
}

class _Patient_DetailsState extends State<Patient_Details> {
  final TextEditingController _temperatureController = TextEditingController();
  final TextEditingController _bloodController = TextEditingController();
  final TextEditingController _glucoseMeterController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  File? _image;

  void _addRates() {
    final docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.doctorId)
        .collection('patients')
        .doc(widget.patientId);

    final updatedRates = {
      'Temperature': _temperatureController.text.isNotEmpty
          ? _temperatureController.text
          : widget.document['rates']['Temperature'],
      'blood': _bloodController.text.isNotEmpty
          ? _bloodController.text
          : widget.document['rates']['blood'],
      'glucose': _glucoseMeterController.text.isNotEmpty
          ? _glucoseMeterController.text
          : widget.document['rates']['glucose'],
    };

    docRef.update({
      'rates': updatedRates,
    }).then((_) {
      setState(() {
        _temperatureController.text = updatedRates['Temperature'];
        _bloodController.text = updatedRates['blood'];
        _glucoseMeterController.text = updatedRates['glucose'];
      });

      Navigator.pop(context);
    }).catchError((error) {
      print('Error updating data: $error');
    });
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> _uploadScan() async {
    if (_image == null) return;

    setState(() {
      // Show loading indicator or other UI changes
    });

    try {
      final request =
          http.MultipartRequest('POST', Uri.parse('YOUR_SERVER_URL'));
      request.files
          .add(await http.MultipartFile.fromPath('image', _image!.path));
      final response = await request.send();

      if (response.statusCode == 200) {
        final responseData = await http.Response.fromStream(response);
        final prediction = responseData.body;

        final scanData = {
          'image': 'image_url', // Replace with the actual image URL
          'prediction': prediction,
          'notes': _notesController.text,
          'timestamp': Timestamp.now(),
        };

        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.doctorId)
            .collection('patients')
            .doc(widget.patientId)
            .update({
          'scans': FieldValue.arrayUnion([scanData])
        });

        setState(() {
          _image = null;
          _notesController.clear();
        });
      } else {
        // Handle server error
      }
    } catch (error) {
      print('Error uploading scan: $error');
    }

    setState(() {
      // Hide loading indicator or other UI changes
    });
  }

  var primaryColor = Color.fromARGB(255, 61, 202, 148);

  TextStyle primaryText() =>
      TextStyle(color: primaryColor, fontSize: 20, fontWeight: FontWeight.bold);

  @override
  Widget build(BuildContext context) {
    String birthStr = "${widget.document["date_of_birth"]}";
    DateTime birthDate = DateFormat('MM/dd/yyyy').parse(birthStr);
    Duration difference = DateTime.now().difference(birthDate);
    int age = (difference.inDays / 365.25).floor();

    return Scaffold(
      appBar: AppBar(
        title: Text("Patient Details",
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20)),
        backgroundColor: primaryColor,
        leading: MaterialButton(
          child: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Container(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10)),
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: Colors.white,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.document["name"],
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.w500),
                            ),
                            SizedBox(width: 16),
                            Text(
                              widget.document["phone"],
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 16,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10)),
                          child: Column(
                            children: [
                              Image.asset("assets/age.png",
                                  width: 40, height: 40, color: primaryColor),
                              SizedBox(height: 4,),
                              Text("$age Years",
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.black87)),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 24,
                      ),
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10)),
                          child: Column(
                            children: [
                              Image.asset("assets/genders.png",
                                  width: 40, height: 40, color: primaryColor),
                              SizedBox(height: 4,),
                              Text(widget.document["gender"],
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.black87)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),
            Row(
              children: [
                Image.asset("assets/bandage-38.png",
                    width: 32, height: 32, color: primaryColor),
                SizedBox(width: 10),
                Text("Normal Rates", style: primaryText()),
                TextButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            contentPadding:
                                EdgeInsets.symmetric(horizontal: 12),
                            title: Text("Edit Rates"),
                            content: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(height: 10),
                                  Text("Enter new values for medical rates:"),
                                  SizedBox(height: 20),
                                  TextFormField(
                                    controller: _glucoseMeterController,
                                    decoration: InputDecoration(
                                      labelText: "Glucose Meter",
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 10),
                                  TextFormField(
                                    controller: _bloodController,
                                    decoration: InputDecoration(
                                      labelText: "Blood Pressure Gauge",
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 10),
                                  TextFormField(
                                    controller: _temperatureController,
                                    decoration: InputDecoration(
                                      labelText: "Temperature",
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 20),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                        child: Text(
                                          "Cancel",
                                          style: TextStyle(color: Colors.red),
                                        ),
                                      ),
                                      SizedBox(width: 10),
                                      ElevatedButton(
                                        onPressed: _addRates,
                                        child: Text("Save"),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                    child: Text(
                      "Edit",
                      style: TextStyle(color: Colors.black54, fontSize: 18),
                    )),
              ],
            ),
            SizedBox(height: 24),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10)),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10)),
                      child: Column(
                        children: [
                          Image.asset("assets/glucose-meter.png",
                              width: 50, height: 50),
                          SizedBox(
                            height: 16,
                          ),
                          Text(widget.document["rates"]["glucose"],
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: primaryColor)),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10)),
                      child: Column(
                        children: [
                          Image.asset("assets/blood-pressure-gauge.png",
                              width: 50, height: 50),
                          SizedBox(
                            height: 16,
                          ),
                          Text(widget.document["rates"]["blood"],
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: primaryColor)),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10)),
                      child: Column(
                        children: [
                          Image.asset("assets/Temperature-measuring.png",
                              width: 50, height: 50),
                          SizedBox(
                            height: 16,
                          ),
                          Text(widget.document["rates"]["Temperature"],
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: primaryColor)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),
            Row(
              children: [
                Image.asset("assets/document.png",
                    width: 32, height: 32, color: primaryColor),
                SizedBox(width: 10),
                Text("Medical Records", style: primaryText()),
              ],
            ),
            SizedBox(height: 24),
            Expanded(
              child: ListView.builder(
                itemCount: widget.document["scans"].length,
                itemBuilder: (context, index) {
                  var record = widget.document["scans"][index];
                  return Container(
                    decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${record["prediction"]}',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: primaryColor),
                          ),
                          SizedBox(height: 10),
                          Image.network(
                            record["image"],
                            height: 150,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                          SizedBox(height: 10),
                          Text(
                            'Scan Date: ${DateFormat('MM/dd/yyyy').format(record["timestamp"].toDate())}',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
