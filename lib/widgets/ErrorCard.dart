import 'package:flutter/material.dart';

class ErrorCard extends StatelessWidget {
  final String errorMessage;
  
  const ErrorCard({
    Key? key,
    required this.errorMessage,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.red.shade50,
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 48,
            ),
            const SizedBox(height: 16),
            const Text(
              'Error Loading Prayer Times',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Please check your internet connection and location settings.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}