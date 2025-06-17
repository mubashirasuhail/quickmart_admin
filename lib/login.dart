// lib/login.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Import the provider package
import 'package:quick_mart_admin/button.dart'; // Your custom button widget
import 'package:quick_mart_admin/home.dart'; // Your HomeScreen
import 'package:quick_mart_admin/login_provider.dart';
import 'package:quick_mart_admin/textfield.dart'; // Your custom textfield widget
// Import your LoginProvider



class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    bool isWeb = screenWidth > 600;

    return Scaffold(
      body: Center(
        child: isWeb ? _buildWebLayout() : _buildMobileLayout(),
      ),
    );
  }

  /// Web Layout: Image on the left, login box with shadow on the right
  Widget _buildWebLayout() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Left-side image (No shadow)
        Expanded(
          child: Image.asset(
            "assets/images/supermarkt.jpg", // Replace with your image
            fit: BoxFit.cover,
          ),
        ),

        // Right-side login box with shadow
        Expanded(
          child: Container(
            width: 400,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: _buildLoginForm(),
          ),
        ),
      ],
    );
  }

  /// Mobile Layout: Image on top, login box with shadow below
  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      // Ensured SingleChildScrollView wraps the content
      child: Column(
        children: [
          // Top image (No shadow)
          Image.asset(
            "assets/images/supermarkt.jpg", // Replace with your image
            height: 200,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 20),

          // Login box with shadow
          Container(
            width: 350,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: _buildLoginForm(),
          ),
          // Added a small SizedBox at the bottom to provide some scrollable space
          // when the keyboard appears, preventing the last element from being hidden.
          const SizedBox(height: 50),
        ],
      ),
    );
  }

  /// Login Form with Validation
  Widget _buildLoginForm() {
    // Watch for changes in LoginProvider's state (e.g., errorMessage, isLoading)
    final loginProvider = Provider.of<LoginProvider>(context);

    return Form(
      key: _formKey,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: 10.0), // Applied consistent horizontal padding
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Login",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            // Using MyTextfield for Username
            MyTextfield(
              controller: _emailController,
              labelText: "Username",
              icon: Icons.person, // Added an icon for username
              height: 60,
              width: double.infinity,
              validator: (value) =>
                  value == null || value.isEmpty ? "Enter username" : null,
            ),
            const SizedBox(height: 10),
            // Using MyTextfield for Password
            MyTextfield(
              controller: _passwordController,
              labelText: "Password",
              obscureText: true,
              icon: Icons.lock, // Added an icon for password
              height: 60,
              width: double.infinity,
              validator: (value) =>
                  value == null || value.isEmpty ? "Enter password" : null,
            ),
            const SizedBox(height: 20),
            if (loginProvider.errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  loginProvider.errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            // Conditionally show loading indicator or login button
            loginProvider.isLoading
                ? const CircularProgressIndicator() // Show spinner when loading
                : Mybutton(
                    buttonText: "Login",
                    height: 60, // Ensure height consistency
                    width: double.infinity, // Ensure width consistency
                    onTap: () async {
                      // Check if form is valid before attempting login
                      if (_formKey.currentState!.validate()) {
                        await loginProvider.login(
                          _emailController.text,
                          _passwordController.text,
                        );
                        // After login attempt, check if there's no error message
                        if (loginProvider.errorMessage == null) {
                          // Only navigate if login was successful
                          // Use context.go if you're using go_router or named routes
                          Navigator.pushReplacement(
                            context, // Use current context for navigation
                            MaterialPageRoute(
                                builder: (context) => const HomeScreen()),
                          );
                        }
                      }
                    },
                  ),
          ],
        ),
      ),
    );
  }
}