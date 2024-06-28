import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:doctor/pages/patient_details.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MyPatient extends StatefulWidget {
  const MyPatient({Key? key}) : super(key: key);

  @override
  _MyPatientState createState() => _MyPatientState();
}

var primaryColor = Color.fromARGB(255, 61, 202, 148);

class _MyPatientState extends State<MyPatient> {
  String uid = " ";
  Future getData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String user_uid = prefs.getString('uid') ?? '';
    setState(() {
      uid = user_uid;
    });
  }

  final CollectionReference collection =
  FirebaseFirestore.instance.collection('users');
  late TextEditingController _searchController;
  String _searchText = '';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    getData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchText = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("My Patients",
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20)),
        backgroundColor: primaryColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextFormField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: "Search with patient name",
                prefixIcon: Icon(
                  Icons.search,
                  color: Colors.grey,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            SizedBox(
              height: 24,
            ),
            Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: collection
                      .doc(uid)
                      .collection('patients')
                      .where('name', isGreaterThanOrEqualTo: _searchText)
                      .where('name', isLessThan: _searchText + 'z')
                      .snapshots(),
                  builder: (BuildContext context,
                      AsyncSnapshot<QuerySnapshot> snapshot) {
                    if (snapshot.hasError) {
                      return Text('Something went wrong ${snapshot.error}');
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Text('Loading');
                    }

                    final filteredDocs = snapshot.data!.docs;

                    if (filteredDocs.isEmpty) {
                      return Text('No results found');
                    } else {
                      return ListView.builder(
                        itemCount: filteredDocs.length,
                        itemBuilder: (BuildContext context, int index) {
                          final document = filteredDocs[index];
                          return InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => Patient_Details(
                                    document: document,
                                    doctorId: uid,
                                    patientId: document.id,
                                  ),
                                ),
                              );
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
                                            document['name'].toString(),
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            document['phone'],
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.delete, color: Colors.red.shade300),
                                      onPressed: () {
                                        collection
                                            .doc(uid)
                                            .collection('patients')
                                            .doc(document.id)
                                            .delete();
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    }
                  },
                )),
          ],
        ),
      ),
    );
  }
}
