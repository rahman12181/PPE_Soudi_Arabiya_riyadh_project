import 'package:flutter/material.dart';

class RegularizationApproval  extends StatefulWidget{
  const RegularizationApproval({super.key});

  @override
  State<RegularizationApproval> createState()=> _RegularizationApprovalState();
}

class _RegularizationApprovalState  extends State<RegularizationApproval>{
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text("Regularization approval",style: TextStyle(fontSize: 30),),
      ),
    );
  }
}