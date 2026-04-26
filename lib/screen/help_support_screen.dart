import 'package:flutter/material.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Help & Support"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          "Help and support content goes here...",
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
