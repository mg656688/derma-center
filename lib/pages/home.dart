import 'package:doctor/pages/newpatient.dart';
import 'package:doctor/pages/profile.dart';
import 'package:doctor/pages/skin_detector.dart';
import 'package:flutter/material.dart';
import 'mypatient.dart';

class HomeSection extends StatefulWidget {
  const HomeSection({Key? key}) : super(key: key);

  @override
  State<HomeSection> createState() => _HomeSectionState();
}

class _HomeSectionState extends State<HomeSection> {
  int _index = 0;
  final screens = const [
    NewPatient(),
    SkinDetector(),
    MyPatient(),
    Profile(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: SafeArea(
        child: buildBottomNavigationBar(),
      ),
      body: screens[_index],
    );
  }

  Widget buildBottomNavigationBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      margin: const EdgeInsets.only(bottom: 15, top: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
      ),
      child: BottomNavigationBar(
        backgroundColor: Colors.green,
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey, // Set color for unselected items
        elevation: 0,
        currentIndex: _index,
        onTap: (value) {
          setState(() {
            _index = value;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.person_add, size: 30),
            label: "Add Patient",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.medical_services_outlined, size: 30),
            label: "Skin Detector",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_outlined, size: 30),
            label: "My Patients",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person, size: 30),
            label: "Profile",
          ),
        ],
      ),
    );
  }
}



// Project Overview:
// The Dermatology Center App aims to provide dermatology doctors with a comprehensive tool to track patients' medical records efficiently. It allows doctors to manage existing patient information, add new patients, and utilize a skin disease detector AI model to recognize skin diseases from images. Additionally, the app enables doctors to store scans for each patient if needed, along with the predicted disease.
//
// Key Features:
//
// •	Patient Management:
// Registration form for adding new patients.
// Database of patients' medical histories.
// Ability to view and edit patient details.
// Online chat functionality for communication with patients.
// Skin Disease Detector:
//
// •	Integration of an AI model for skin disease detection.
// Capability to upload patient skin images for analysis.
// Display of predicted diseases based on image analysis results.
//
// •	Scans Storage:
// Functionality to store scans and images for each patient.
// Association of scans with patient records for easy reference.
// Option to view, update, or delete stored scans as necessary.
//
// •	Appointment Management:
// Schedule and manage appointments with patients.
// Notification system for appointment reminders.
// Ability to cancel or reschedule appointments as needed.
//
// •	User Interface and Experience:
// Intuitive and user-friendly interface for seamless navigation.
// Responsive design to support both smartphones and tablets.
// Customizable settings to tailor the app to individual preferences.
//
// •	Security and Privacy:
// Implementation of robust security measures to safeguard patient data.
// Compliance with healthcare regulations and standards (e.g., HIPAA).
// User authentication and authorization to ensure data confidentiality.
//
// •	Development Approach:
// Initial Planning and Research:
// Conduct thorough research on dermatology practice workflows and requirements.
// Define user personas and user stories to guide development.
//
// •	Prototyping and Design:
//
// Create wireframes and prototypes to visualize app features and interactions.
// Design user interfaces following best practices and design guidelines.
//
//
//
// •	Backend Development:
// Set up a secure backend infrastructure to store and manage patient data.
// Integrate APIs for AI model integration and image processing.
//
// •	Frontend Development:
// Develop frontend components using appropriate frameworks (e.g., Flutter for cross-platform compatibility).
// Implement UI elements for patient management, appointment scheduling, and scan storage.
//
// •	Testing and Quality Assurance:
// Conduct comprehensive testing to identify and resolve any bugs or issues.
// Perform usability testing with real users to gather feedback and make improvements.
// Deployment and Maintenance:
// Deploy the app-to-app stores (e.g., Apple App Store, Google Play Store).
// Provide ongoing maintenance and support to ensure smooth operation and updates.
//
//
// Technologies and Tools:
// Programming Languages: Dart (for Flutter framework), Python (for AI model), SQL (for database)
// Frameworks: Flutter, TensorFlow (for AI model)
// Database: Firebase Fire store (for cloud-based storage)
// Development Tools: Android Studio, Xcode, TensorFlow Lite
//
//
// Estimated Timeline:
// Project Duration: 6 months
// Milestones: Planning & Design (1 month), Development & Testing (4 months), Deployment & Maintenance (1 month)
//
// Project Team:
// Project Manager
// UI/UX Designer
// Flutter Developer
// Backend Developer
// AI Specialist
// Quality Assurance Engineer
