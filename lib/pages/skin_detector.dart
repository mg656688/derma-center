import 'dart:convert';
import 'dart:io';

import 'package:doctor/pages/treatment_section.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/image_picker.dart';

class SkinDetector extends StatefulWidget {
  const SkinDetector({super.key});

  @override
  State<SkinDetector> createState() => _SkinDetectorState();
}

class _SkinDetectorState extends State<SkinDetector> {
  String uid = "";
  bool isLoading = false;
  String prediction = '';
  final ImagePicker picker = ImagePicker();
  File? _image;
  String imageUrl = '';

  @override
  void initState() {
    super.initState();
    getData();
  }

  Future getData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String user_uid = prefs.getString('uid') ?? '';
    setState(() {
      uid = user_uid;
    });
  }

  Future getImage(ImageSource media) async {
    var pickedImage = await picker.pickImage(source: media);
    if (pickedImage != null) {
      setState(() {
        _image = File(pickedImage.path);
      });
    }
  }

  Future<String> uploadImageToFirebaseStorage(File imageFile) async {
    try {
      String fileName = 'images/${DateTime.now().millisecondsSinceEpoch}.jpg';
      var ref = FirebaseStorage.instance.ref().child(fileName);
      var uploadTask = ref.putFile(imageFile);
      await uploadTask.whenComplete(() => null);
      String downloadURL = await ref.getDownloadURL();
      return downloadURL;
    } catch (e) {
      print('Error uploading image: $e');
      return '';
    }
  }

  Future uploadImageToServer(File imageFile) async {
    if (kDebugMode) {
      print("Attempting to connect to server...");
    }
    String downloadURL = await uploadImageToFirebaseStorage(imageFile);
    if (downloadURL.isEmpty) {
      print("Failed to upload image to Firebase Storage");
      return;
    }
    setState(() {
      imageUrl = downloadURL;
    });
    var request = http.MultipartRequest(
        'POST', Uri.parse('http://192.168.1.16:5000/DermaApp'));
    if (kDebugMode) {
      print("Connection established.");
    }
    request.files.add(await http.MultipartFile.fromPath('fileup', imageFile.path));

    var response = await request.send();

    if (response.statusCode == 200) {
      print('Image uploaded successfully!');
    } else {
      print('Image upload failed with status code ${response.statusCode}');
    }

    final responseJson = await response.stream
        .bytesToString()
        .then((value) => json.decode(value));
    var pred = responseJson['prediction'];
    setState(() {
      prediction = pred;
    });
    print(prediction);
  }

  void _saveScan(DocumentSnapshot patient) async {
    if (_image == null || prediction.isEmpty || imageUrl.isEmpty) {
      return;
    }
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('patients')
          .doc(patient.id)
          .update({
        'scans': FieldValue.arrayUnion([
          {
            'image': imageUrl,
            'prediction': prediction,
            'timestamp': Timestamp.now(),
          }
        ])
      });

      setState(() {
        prediction = '';
        _image = null;
        imageUrl = '';
      });

      Navigator.pop(context);
    } catch (error) {
      print('Error uploading scan: $error');
    }
  }

  Future<List<DocumentSnapshot>> _fetchPatients() async {
    try {
      var snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('patients')
          .get();

      return snapshot.docs;
    } catch (e) {
      print("Error fetching patients: $e");
      return [];
    }
  }

  void myAlert() {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            title: const Text(
              'Please choose an image',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            content: SizedBox(
              height: MediaQuery.of(context).size.height / 8,
              child: Column(
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(150, 40),
                      backgroundColor: primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      getImage(ImageSource.gallery);
                    },
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(color: Colors.white, Icons.image),
                        SizedBox(width: 12),
                        Text(
                          'From Gallery',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(150, 40),
                      backgroundColor: primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      getImage(ImageSource.camera);
                    },
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(color: Colors.white, Icons.camera),
                        SizedBox(width: 12),
                        Text(
                          'From Camera',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Derma Center",
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20)),
        backgroundColor: primaryColor,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 32),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Skin Disease Detector",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Please upload a clear skin image",
                    style: TextStyle(fontWeight: FontWeight.w400, fontSize: 16, color: Colors.grey.shade400),
                  ),
                  SizedBox(height: 32),
                  DottedBorder(
                    dashPattern: [10, 6],
                    color: primaryColor,
                    borderType: BorderType.RRect,
                    radius: Radius.circular(12),
                    strokeWidth: 2,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          image: _image != null
                              ? DecorationImage(
                            image: FileImage(_image!),
                            fit: BoxFit.cover,
                          )
                              : null,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 6,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: _image == null
                            ? Center(
                          child: IconButton(
                            icon: Icon(
                              Icons.add_a_photo,
                              color: primaryColor,
                              size: 40,
                            ),
                            onPressed: myAlert,
                          ),
                        )
                            : null,
                      ),
                    ),
                  ),
                  SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _image != null
                        ? () {
                      if (_image != null) {
                        uploadImageToServer(_image!);
                      }
                    }
                        : null,
                    style: ElevatedButton.styleFrom(
                      primary: _image != null ? primaryColor : Colors.grey,
                      onPrimary: Colors.white,
                      elevation: 5,
                      padding: EdgeInsets.symmetric(horizontal: 60, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      "Scan",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
                    ),
                  ),
                  SizedBox(height: 20),
                  if (prediction.isNotEmpty)
                    Card(
                      color: Colors.white,
                      elevation: 4,
                      margin: EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          children: [
                            Text(
                              "Disease",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                  color: primaryColor),
                            ),
                            SizedBox(height: 8),
                            Text(
                              prediction,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                                color: Colors.black,
                              ),
                            ),
                            SizedBox(height: 8),
                            ElevatedButton(
                              onPressed:  () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => TreatmentSection(prediction: prediction),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                primary: _image != null ? primaryColor : Colors.grey,
                                onPrimary: Colors.white,
                                elevation: 5,
                                padding: EdgeInsets.symmetric(horizontal: 36, vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                "Show Treatment",
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  SizedBox(height: 32),
                  if (prediction.isNotEmpty)
                    ElevatedButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: Text("Select Patient"),
                              content: Container(
                                width: double.maxFinite,
                                child: FutureBuilder<List<DocumentSnapshot>>(
                                  future: _fetchPatients(),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState == ConnectionState.waiting) {
                                      return Center(child: CircularProgressIndicator());
                                    } else if (snapshot.hasError) {
                                      return Center(child: Text("Error: ${snapshot.error}"));
                                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                                      return Center(child: Text("No patients found."));
                                    } else {
                                      List<DocumentSnapshot> patients = snapshot.data!;
                                      return SizedBox(
                                        height: 400,
                                        child: ListView.builder(
                                          itemCount: patients.length,
                                          itemBuilder: (context, index) {
                                            var patient = patients[index];
                                            return InkWell(
                                              onTap: () {
                                                _saveScan(patient);
                                              },
                                              child: Card(
                                                color: primaryColor,
                                                elevation: 1,
                                                margin: EdgeInsets.symmetric(vertical: 8),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(15),
                                                ),
                                                child: Padding(
                                                  padding: EdgeInsets.all(12),
                                                  child: Row(
                                                    crossAxisAlignment: CrossAxisAlignment.center,
                                                    children: [
                                                      Container(
                                                        padding: EdgeInsets.all(10),
                                                        decoration: BoxDecoration(
                                                          color: Colors.white.withOpacity(0.3),
                                                          borderRadius: BorderRadius.circular(50),
                                                        ),
                                                        child: Icon(Icons.person, color: Colors.white),
                                                      ),
                                                      SizedBox(width: 20),
                                                      Expanded(
                                                        child: Column(
                                                          crossAxisAlignment: CrossAxisAlignment.start,
                                                          children: [
                                                            Text(
                                                              patient['name'],
                                                              style: TextStyle(
                                                                color: Colors.white,
                                                                fontWeight: FontWeight.bold,
                                                                fontSize: 16,
                                                              ),
                                                            ),
                                                            SizedBox(height: 4),
                                                            Text(
                                                              patient['phone'],
                                                              style: TextStyle(
                                                                color: Colors.white,
                                                                fontSize: 14,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ),
                            );
                          },
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        primary: Colors.amber,
                        onPrimary: Colors.white,
                        elevation: 5,
                        padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        "Save Scan",
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}








// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:doctor/main.dart';
// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
//
// class Patient_Details extends StatefulWidget {
//   Patient_Details({required this.document});
//
//   final DocumentSnapshot document;
//
//   @override
//   State<Patient_Details> createState() => _Patient_DetailsState();
// }
//
// class _Patient_DetailsState extends State<Patient_Details> {
//   final TextEditingController _temperatureController = TextEditingController();
//   final TextEditingController _bloodController = TextEditingController();
//   final TextEditingController _glucoseMeterController = TextEditingController();
//
//   void _addRates() {
//     FirebaseFirestore.instance
//         .collection('users')
//         .doc(widget.document.id)
//         .update({
//       'rates': {
//         'Temperature': _temperatureController.text,
//         'blood': _bloodController.text,
//         'glucose': _glucoseMeterController.text,
//       },
//     }).then((value) {
//       Navigator.pop(context);
//     }).catchError((error) {
//       print('Error adding data: $error');
//     });
//   }
//
//   var primaryColor = Color.fromARGB(255, 61, 202, 148);
//
//   TextStyle primaryText() =>
//       TextStyle(color: primaryColor, fontSize: 20, fontWeight: FontWeight.bold);
//
//   @override
//   Widget build(BuildContext context) {
//     String birthStr = "${widget.document["date_of_birth"]}";
//     DateTime birthDate = DateFormat('MM/dd/yyyy').parse(birthStr);
//     Duration difference = DateTime.now().difference(birthDate);
//     int age = (difference.inDays / 365.25).floor();
//
//     return Scaffold(
//       body: Container(
//         padding: EdgeInsets.all(10),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 MaterialButton(
//                   child: Icon(Icons.arrow_back),
//                   onPressed: () {
//                     Navigator.of(context).pop();
//                   },
//                 ),
//                 Expanded(
//                   child: Center(
//                     child: Text(
//                       "Patient Details",
//                       style:
//                       TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
//                     ),
//                   ),
//                 )
//               ],
//             ),
//             SizedBox(height: 20),
//             Padding(
//               padding: const EdgeInsets.all(8.0),
//               child: Row(
//                 children: [
//                   Text("Personal Info", style: primaryText()),
//                 ],
//               ),
//             ),
//             Container(
//               padding: EdgeInsets.all(16),
//               decoration: BoxDecoration(
//                   color: Colors.green.withOpacity(0.2),
//                   borderRadius: BorderRadius.circular(10)),
//               child: Column(
//                 children: [
//                   Row(
//                     children: [
//                       CircleAvatar(
//                         radius: 32,
//                         backgroundColor: Colors.white,
//                       ),
//                       Padding(
//                         padding: const EdgeInsets.only(left: 16.0),
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(
//                               widget.document["name"],
//                               style: TextStyle(
//                                   fontSize: 18, fontWeight: FontWeight.w500),
//                             ),
//                             SizedBox(width: 16),
//                             Text(
//                               widget.document["phone"],
//                               style: TextStyle(
//                                   fontSize: 18, fontWeight: FontWeight.w500),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                   SizedBox(
//                     height: 16,
//                   ),
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.start,
//                     children: [
//                       Expanded(
//                         child: Container(
//                           padding: EdgeInsets.all(16),
//                           decoration: BoxDecoration(
//                               color: Colors.white,
//                               borderRadius: BorderRadius.circular(10)),
//                           child: Column(
//                             children: [
//                               Image.asset("assets/age.png",
//                                   width: 40, height: 40, color: primaryColor),
//                               Text("$age Years",
//                                   style: TextStyle(
//                                       fontSize: 16,
//                                       fontWeight: FontWeight.w700,
//                                       color: Colors.black87)),
//                             ],
//                           ),
//                         ),
//                       ),
//                       SizedBox(
//                         width: 24,
//                       ),
//                       Expanded(
//                         child: Container(
//                           padding: EdgeInsets.all(16),
//                           decoration: BoxDecoration(
//                               color: Colors.white,
//                               borderRadius: BorderRadius.circular(10)),
//                           child: Column(
//                             children: [
//                               Image.asset("assets/genders.png",
//                                   width: 40, height: 40, color: primaryColor),
//                               Text(widget.document["gender"],
//                                   style: TextStyle(
//                                       fontSize: 16,
//                                       fontWeight: FontWeight.w700,
//                                       color: Colors.black87)),
//                             ],
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//             SizedBox(height: 24),
//             Row(
//               children: [
//                 Image.asset("assets/bandage-38.png",
//                     width: 32, height: 32, color: primaryColor),
//                 SizedBox(width: 10),
//                 Text("Normal Rates", style: primaryText()),
//                 TextButton(
//                     onPressed: () {
//                       showDialog(
//                         context: context,
//                         builder: (BuildContext context) {
//                           return AlertDialog(
//                             contentPadding: EdgeInsets.symmetric(horizontal: 12),
//                             title: Text("Edit Rates"),
//                             content: SingleChildScrollView(
//                               child: Column(
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 mainAxisSize: MainAxisSize.min,
//                                 children: [
//                                   SizedBox(height: 10),
//                                   Text("Enter new values for medical rates:"),
//                                   SizedBox(height: 20),
//                                   TextFormField(
//                                     controller: _glucoseMeterController,
//                                     decoration: InputDecoration(
//                                       labelText: "Glucose Meter",
//                                       border: OutlineInputBorder(
//                                         borderRadius: BorderRadius.circular(10),
//                                       ),
//                                     ),
//                                   ),
//                                   SizedBox(height: 10),
//                                   TextFormField(
//                                     controller: _bloodController,
//                                     decoration: InputDecoration(
//                                       labelText: "Blood Pressure Gauge",
//                                       border: OutlineInputBorder(
//                                         borderRadius: BorderRadius.circular(10),
//                                       ),
//                                     ),
//                                   ),
//                                   SizedBox(height: 10),
//                                   TextFormField(
//                                     controller: _temperatureController,
//                                     decoration: InputDecoration(
//                                       labelText: "Temperature",
//                                       border: OutlineInputBorder(
//                                         borderRadius: BorderRadius.circular(10),
//                                       ),
//                                     ),
//                                   ),
//                                   SizedBox(height: 20),
//                                   Row(
//                                     mainAxisAlignment: MainAxisAlignment.end,
//                                     children: [
//                                       TextButton(
//                                         onPressed: () {
//                                           Navigator.of(context).pop();
//                                         },
//                                         child: Text(
//                                           "Cancel",
//                                           style: TextStyle(color: Colors.red),
//                                         ),
//                                       ),
//                                       SizedBox(width: 10),
//                                       ElevatedButton(
//                                         onPressed: _addRates,
//                                         child: Text("Save"),
//                                       ),
//                                     ],
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           );
//                         },
//                       );
//                     },
//                     child: Text(
//                       "Edit",
//                       style: TextStyle(color: Colors.black54, fontSize: 18),
//                     )),
//               ],
//             ),
//             SizedBox(height: 24),
//             Container(
//               padding: EdgeInsets.all(16),
//               decoration: BoxDecoration(
//                   color: Colors.green.withOpacity(0.2),
//                   borderRadius: BorderRadius.circular(10)),
//               child: Row(
//                 children: [
//                   Expanded(
//                     child: Container(
//                       padding: EdgeInsets.all(16),
//                       decoration: BoxDecoration(
//                           color: Colors.white,
//                           borderRadius: BorderRadius.circular(10)),
//                       child: Column(
//                         children: [
//                           Image.asset("assets/glucose-meter.png",
//                               width: 50, height: 50),
//                           SizedBox(
//                             height: 16,
//                           ),
//                           Text(widget.document["rates"]["glucose"],
//                               style: TextStyle(
//                                   fontSize: 18,
//                                   fontWeight: FontWeight.bold,
//                                   color: primaryColor)),
//                         ],
//                       ),
//                     ),
//                   ),
//                   SizedBox(width: 10),
//                   Expanded(
//                     child: Container(
//                       padding: EdgeInsets.all(16),
//                       decoration: BoxDecoration(
//                           color: Colors.white,
//                           borderRadius: BorderRadius.circular(10)),
//                       child: Column(
//                         children: [
//                           Image.asset("assets/blood-pressure-gauge.png",
//                               width: 50, height: 50),
//                           SizedBox(
//                             height: 16,
//                           ),
//                           Text(widget.document["rates"]["blood"],
//                               style: TextStyle(
//                                   fontSize: 18,
//                                   fontWeight: FontWeight.bold,
//                                   color: primaryColor)),
//                         ],
//                       ),
//                     ),
//                   ),
//                   SizedBox(width: 10),
//                   Expanded(
//                     child: Container(
//                       padding: EdgeInsets.all(16),
//                       decoration: BoxDecoration(
//                           color: Colors.white,
//                           borderRadius: BorderRadius.circular(10)),
//                       child: Column(
//                         children: [
//                           Image.asset("assets/Temperature-measuring.png",
//                               width: 50, height: 50),
//                           SizedBox(
//                             height: 16,
//                           ),
//                           Text(widget.document["rates"]["Temperature"],
//                               style: TextStyle(
//                                   fontSize: 18,
//                                   fontWeight: FontWeight.bold,
//                                   color: primaryColor)),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             SizedBox(height: 24),
//             Row(
//               children: [
//                 Image.asset("assets/document.png",
//                     width: 32, height: 32, color: primaryColor),
//                 SizedBox(width: 10),
//                 Text("Medical Records", style: primaryText()),
//               ],
//             ),
//             Expanded(
//               child: ListView.builder(
//                 itemCount: widget.document["medical_records"].length,
//                 itemBuilder: (context, index) {
//                   var record = widget.document["medical_records"][index];
//                   return ListTile(
//                     leading: Container(
//                       padding: EdgeInsets.all(10),
//                       decoration:
//                       BoxDecoration(color: primaryColor, borderRadius: BorderRadius.circular(15)),
//                       child: Icon(Icons.camera),
//                     ),
//                     title: Text(record["title"]),
//                     subtitle: Text(record["date"]),
//                     trailing: Text(
//                       record["prediction"],
//                       style: TextStyle(fontSize: 14),
//                     ),
//                   );
//                 },
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
