import 'package:flutter/material.dart';

class SlideAnimation extends StatefulWidget {
  final Widget child;
  final Duration duration;

  const SlideAnimation({
    super.key,
     required this.child,
     this.duration=const Duration(milliseconds: 1500),
    });

  @override
  State<StatefulWidget> createState() => _SlideAnimationState();
}

class _SlideAnimationState extends State<SlideAnimation> with
SingleTickerProviderStateMixin{

  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  
  @override
  void initState(){
    super.initState();
    _controller=AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _offsetAnimation=Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }
  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _offsetAnimation,
      child: widget.child,
    );
  }
}

