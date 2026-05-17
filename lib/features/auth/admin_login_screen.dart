// separate login page for the admin with email checks
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:moodwalls/features/auth/auth_provider.dart';
import 'package:moodwalls/core/custom_button.dart';
import 'package:moodwalls/core/custom_textfield.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _confirmedManual = false;

  @override
  void initState() {
    super.initState();
    // clear autofilled credentials on load
    _emailController.clear();
    _passwordController.clear();
  }

  void _login() async {
    if (!_confirmedManual) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please confirm you are a human by checking the box.')),
      );
      return;
    }

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    setState(() {
      _isLoading = true;
    });
    
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.login(email, password);
      
      // wait for user data to be fetched
      // if user is not admin then access is denied
      // check explicitly here for better ux
      
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login Failed: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Access'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade50, Colors.white],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.admin_panel_settings,
                  size: 80,
                  color: Colors.blueAccent,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Administrator Login',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Please enter your secure credentials',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 40),
                CustomTextField(
                  controller: _emailController,
                  hintText: 'Admin Email',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  enableSuggestions: false,
                  autocorrect: false,
                  autofillHints: const [], // disable autofill hints
                ),
                const SizedBox(height: 20),
                CustomTextField(
                  controller: _passwordController,
                  hintText: 'Admin Password',
                  icon: Icons.lock_outline,
                  isPassword: true,
                  enableSuggestions: false,
                  autocorrect: false,
                  autofillHints: const [], // disable autofill hints
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Checkbox(
                      value: _confirmedManual,
                      onChanged: (val) => setState(() => _confirmedManual = val ?? false),
                    ),
                    const Expanded(
                      child: Text(
                        'I confirm this is a manual login attempt',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                CustomButton(
                  text: 'Login as Admin',
                  onPressed: _confirmedManual ? _login : () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please check the confirmation box first.')),
                    );
                  },
                  isLoading: _isLoading,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
