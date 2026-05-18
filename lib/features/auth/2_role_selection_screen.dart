// [FLOW STEP 2] 2_role_selection_screen.dart - Role Selection: Choose between User Login or Admin Login
import 'package:flutter/material.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFFE0F7FA),
              const Color(0xFFB2EBF2),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.wallpaper_rounded,
                    size: 80,
                    color: Color(0xFF4A90E2),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'MoodWalls',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Select your role to continue',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                  const SizedBox(height: 60),
                  _buildRoleButton(
                    context,
                    title: 'Login as User',
                    icon: Icons.person_outline,
                    color: const Color(0xFF4A90E2),
                    onTap: () => Navigator.pushNamed(context, '/login'),
                  ),
                  const SizedBox(height: 20),
                  _buildRoleButton(
                    context,
                    title: 'Login as Admin',
                    icon: Icons.admin_panel_settings_outlined,
                    color: const Color(0xFF2C3E50),
                    onTap: () => Navigator.pushNamed(context, '/admin-login'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleButton(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      width: double.infinity,
      height: 70,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.15),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Row(
              children: [
                Icon(icon, size: 28, color: color),
                const SizedBox(width: 20),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const Spacer(),
                Icon(Icons.arrow_forward_ios, size: 18, color: color.withValues(alpha: 0.5)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
