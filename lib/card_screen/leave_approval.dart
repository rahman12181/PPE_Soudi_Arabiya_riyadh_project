import 'package:flutter/material.dart';

class LeaveApproval extends StatefulWidget{
  const LeaveApproval({super.key});

  @override
  State<LeaveApproval> createState()=> _LeaveApprovalState();
}

class _LeaveApprovalState extends State<LeaveApproval>{
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
       body: Center(
        child: Text("Leave approval Screen",style: TextStyle(fontSize: 30),)
       )
    );
  }
}