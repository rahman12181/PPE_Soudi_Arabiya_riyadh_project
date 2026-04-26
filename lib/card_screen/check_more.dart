import 'package:flutter/material.dart';

class CheckMore extends StatefulWidget {
  const CheckMore({super.key});

  @override
  State<CheckMore> createState()=> _CheckMore();
}

class _CheckMore extends State<CheckMore>{
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text("see more screen",style:  TextStyle(fontSize: 30),),
      ),
    );
  }
}