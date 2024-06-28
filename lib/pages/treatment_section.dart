import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;

class TreatmentSection extends StatefulWidget {
  final String prediction;
  const TreatmentSection({required this.prediction, super.key});

  @override
  State<TreatmentSection> createState() => _TreatmentSectionState();
}

class _TreatmentSectionState extends State<TreatmentSection> {

  bool isLoading = true;
  late String skinDiseasePhotoUrl;
  late String diseaseName;
  late String description;
  late List<String> symptoms;
  late String treatment;

  @override
  void initState() {
    super.initState();
    getSkinDiseaseData(widget.prediction);
  }

  Future<void> getSkinDiseaseData(String prediction) async {
    var db = await mongo.Db.create(
        "mongodb+srv://admin:admin1234@together.cvq6ffb.mongodb.net/skin?retryWrites=true&w=majority");
    await db.open();

    var collection = db.collection("derma_center");
    var diseaseData =
    await collection.findOne(mongo.where.eq("disease_name", prediction));
    await db.close();

    if (diseaseData != null) {
      setState(() {
        skinDiseasePhotoUrl = diseaseData['image_url'] as String;
        diseaseName = diseaseData['disease_name'] as String;
        description = diseaseData['description'] as String;
        symptoms = (diseaseData['symptoms'] as String).split(',').map((s) => s.trim()).toList();
        treatment = diseaseData['treatment'] as String;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    } else {
      return Scaffold(
        appBar: AppBar(
          title: Text(diseaseName),
        ),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Skin Disease Photo
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
                child: Image.network(
                  skinDiseasePhotoUrl,
                  width: double.infinity,
                  height: 210,
                  fit: BoxFit.cover,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Disease Description
                    _buildInfo("Description", description),
                    const SizedBox(height: 16,),
                    // Symptoms
                    _buildSection("Symptoms", symptoms),
                    const SizedBox(height: 16,),
                    // Treatment
                    _buildInfo("Treatment", treatment),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildSection(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: items.map((item) => _buildInfoItem(item)).toList(),
        ),
      ],
    );
  }

  Widget _buildInfoItem(String content) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(0, 4, 0, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '• ',
            style: TextStyle(
              fontSize: 16,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(
              content,
              textAlign: TextAlign.start,
              style: const TextStyle(
                fontSize: 16,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfo(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        _buildInfoItem(content),
      ],
    );
  }
}
