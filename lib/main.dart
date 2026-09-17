import 'package:flutter/material.dart';

void main() {
  runApp(const BokkYoonApp());
}

class BokkYoonApp extends StatelessWidget {
  const BokkYoonApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bokk Yoon',
      debugShowCheckedModeBanner: false,
      home: const Scaffold(
        body: Center(child: Text('Bokk Yoon')),
      ),
    );
  }
}