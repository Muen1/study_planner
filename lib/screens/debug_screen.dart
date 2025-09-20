import 'package:flutter/material.dart';
import 'debug_screen.dart'; // Import the debug screen

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'App Settings',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            // Example setting
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text('Enable Notifications'),
                Switch(value: true, onChanged: null), // dummy switch
              ],
            ),
            const SizedBox(height: 40),

            // BUTTON TO OPEN DEBUG SCREEN
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DebugScreen()),
                );
              },
              child: const Text('View Stored Data (Debug)'),
            ),
          ],
        ),
      ),
    );
  }
}

