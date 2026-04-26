import 'package:flutter/material.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("About Us"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          "About us information goes here...",
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
