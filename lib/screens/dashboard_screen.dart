import 'package:flutter/material.dart';
import 'partner_dashboard.dart';

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
    return const PartnerDashboard();
  }
}
