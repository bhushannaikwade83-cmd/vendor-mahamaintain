import 'package:flutter/material.dart';
import '../config/app_theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.saffron,
        title: const Text('👤 My Profile'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile Header
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey[300],
                    child: const Text('👤', style: TextStyle(fontSize: 50)),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Bhushan Naikwade',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const Text(
                    '+91 9876543210',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Column(
                        children: const [
                          Text('28', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text('Bookings'),
                        ],
                      ),
                      Column(
                        children: const [
                          Text('⭐ 4.8', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text('Rating'),
                        ],
                      ),
                      Column(
                        children: const [
                          Text('₹12,450', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text('Spent'),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildSettingsTile('📧 Email', 'bhushan@example.com'),
          _buildSettingsTile('🏠 Address', 'Shri Ramdev Park CHS, Mumbai'),
          _buildSettingsTile('💳 Payment Methods', 'Manage cards & accounts'),
          _buildSettingsTile('🔔 Notifications', 'Notification settings'),
          _buildSettingsTile('📱 About', 'Version 1.0.0'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile(String title, String subtitle) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward),
        onTap: () {},
      ),
    );
  }
}
