import 'package:flutter/material.dart';
import 'vendor_dashboard_screen.dart';
import 'society_dashboard_screen.dart';
import 'home_screen.dart';

class DashboardScreen extends StatefulWidget {
  final String userRole;
  final VoidCallback onLogout;

  const DashboardScreen({
    required this.userRole,
    required this.onLogout,
    Key? key,
  }) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  Widget build(BuildContext context) {
    // Route to appropriate dashboard based on user role
    if (widget.userRole == 'vendor') {
      return const VendorDashboardScreen();
    } else if (widget.userRole == 'society') {
      return const SocietyDashboardScreen();
    } else {
      // Default to individual/user dashboard
      return HomeScreen(onLogout: widget.onLogout);
    }
  }
}
