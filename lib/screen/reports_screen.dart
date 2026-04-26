import 'package:flutter/material.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Reports"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          "Reports screen content goes here...",
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
