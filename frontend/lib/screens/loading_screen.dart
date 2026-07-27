import 'package:flutter/material.dart';

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: CircularProgressIndicator(
          constraints: BoxConstraints.tight(Size(90, 90)),
          strokeWidth: 9,
        ),
      ),
    );
  }
}
