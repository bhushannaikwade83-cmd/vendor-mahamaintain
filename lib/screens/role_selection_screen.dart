import 'package:flutter/material.dart';
import '../config/app_theme.dart';

class RoleSelectionScreen extends StatefulWidget {
  final Function(String) onRoleSelected;

  const RoleSelectionScreen({
    required this.onRoleSelected,
    Key? key,
  }) : super(key: key);

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  String? _selectedRole;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
        );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _selectRole(String role) {
    setState(() => _selectedRole = role);
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        widget.onRoleSelected(role);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmall = screenWidth < 380;

    return Scaffold(
      backgroundColor: Colors.white,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Header with gradient
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [AppTheme.saffron, AppTheme.saffronDark],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.saffron.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + (isSmall ? 24 : 40),
                    bottom: isSmall ? 48 : 64,
                    left: 24,
                    right: 24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      AnimatedScale(
                        scale: 1,
                        duration: const Duration(milliseconds: 600),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(28),
                          child: Image.asset(
                            'images/logo.jpeg',
                            width: isSmall ? 160 : 200,
                            height: isSmall ? 160 : 200,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: isSmall ? 160 : 200,
                                height: isSmall ? 160 : 200,
                                color: Colors.white,
                                child: Center(
                                  child: Text(
                                    '🏢',
                                    style: TextStyle(
                                      fontSize: isSmall ? 60 : 80,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      SizedBox(height: isSmall ? 20 : 28),
                      Text(
                        'MahaMaintain Pro',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isSmall ? 26 : 32,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                      SizedBox(height: isSmall ? 8 : 12),
                      Text(
                        'महाराष्ट्र का विश्वास',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: isSmall ? 13 : 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                // Role Selection Content
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmall ? 20 : 24,
                    vertical: isSmall ? 32 : 48,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Who are you?',
                        style: TextStyle(
                          fontSize: isSmall ? 24 : 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                          letterSpacing: -0.5,
                        ),
                      ),
                      SizedBox(height: isSmall ? 8 : 12),
                      Text(
                        'Choose your role to get started',
                        style: TextStyle(
                          fontSize: isSmall ? 13 : 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      SizedBox(height: isSmall ? 40 : 56),
                      // Vendor Card
                      _buildRoleCard(
                        title: 'I\'m a Vendor',
                        subtitle: 'Offer your services',
                        emoji: '🏢',
                        role: 'vendor',
                        isSelected: _selectedRole == 'vendor',
                        isSmall: isSmall,
                        onTap: () => _selectRole('vendor'),
                      ),
                      SizedBox(height: isSmall ? 16 : 20),
                      // Individual Customer Card
                      _buildRoleCard(
                        title: 'I\'m an Individual',
                        subtitle: 'Book services for your home',
                        emoji: '👤',
                        role: 'individual',
                        isSelected: _selectedRole == 'individual',
                        isSmall: isSmall,
                        onTap: () => _selectRole('individual'),
                      ),
                      SizedBox(height: isSmall ? 16 : 20),
                      // Society Card
                      _buildRoleCard(
                        title: 'I\'m from Society',
                        subtitle: 'Manage society services',
                        emoji: '🏘️',
                        role: 'society',
                        isSelected: _selectedRole == 'society',
                        isSmall: isSmall,
                        onTap: () => _selectRole('society'),
                      ),
                      SizedBox(height: isSmall ? 32 : 48),
                      Text(
                        'By continuing, you agree to our Terms & Privacy Policy',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: isSmall ? 11 : 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard({
    required String title,
    required String subtitle,
    required String emoji,
    required String role,
    required bool isSelected,
    required bool isSmall,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppTheme.saffron, AppTheme.saffronDark],
                )
              : LinearGradient(
                  colors: [Colors.white, Colors.grey.shade50],
                ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.saffron : Colors.grey.shade200,
            width: isSelected ? 2.5 : 1.5,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: AppTheme.saffron.withOpacity(0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
              )
            else
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        padding: EdgeInsets.symmetric(
          vertical: isSmall ? 20 : 24,
          horizontal: isSmall ? 16 : 20,
        ),
        child: Row(
          children: [
            // Emoji Container
            Container(
              width: isSmall ? 56 : 64,
              height: isSmall ? 56 : 64,
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withOpacity(0.25)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  emoji,
                  style: TextStyle(
                    fontSize: isSmall ? 28 : 32,
                  ),
                ),
              ),
            ),
            SizedBox(width: isSmall ? 16 : 20),
            // Text Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: isSmall ? 16 : 18,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : Colors.black,
                      letterSpacing: -0.3,
                    ),
                  ),
                  SizedBox(height: isSmall ? 4 : 6),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: isSmall ? 12 : 13,
                      color: isSelected ? Colors.white70 : Colors.grey.shade600,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            // Arrow Icon
            AnimatedScale(
              scale: isSelected ? 1.2 : 1.0,
              duration: const Duration(milliseconds: 300),
              child: Container(
                width: isSmall ? 40 : 44,
                height: isSmall ? 40 : 44,
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withOpacity(0.25)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Icon(
                    isSelected ? Icons.check_circle : Icons.arrow_forward,
                    color: isSelected ? Colors.white : Colors.grey.shade400,
                    size: isSmall ? 20 : 22,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
