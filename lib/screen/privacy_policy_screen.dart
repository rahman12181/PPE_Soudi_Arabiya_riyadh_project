import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Privacy Policy"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          "Privacy Policy content goes here...",
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
