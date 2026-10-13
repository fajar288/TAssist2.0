import 'package:flutter/material.dart';

class LearningPlaceholderPage extends StatelessWidget {
  const LearningPlaceholderPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Learning'),
        centerTitle: true,
      ),
      body: const Center(
        child: Text(
          'fitur belum tersedia',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}