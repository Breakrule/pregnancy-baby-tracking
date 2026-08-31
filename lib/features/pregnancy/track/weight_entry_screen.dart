import 'package:flutter/material.dart';

/// Temporary placeholder — replaced entirely in Task 12.
class WeightEntryScreen extends StatelessWidget {
  const WeightEntryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Log Weight')),
      body: const Center(
        child: ElevatedButton(
          onPressed: null, // disabled until Task 12 implements the form
          child: Text('Save'),
        ),
      ),
    );
  }
}
