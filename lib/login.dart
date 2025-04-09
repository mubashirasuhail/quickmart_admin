/*import 'package:flutter/material.dart';
import 'package:quick_mart_admin/home.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  void _login() {
    if (_formKey.currentState!.validate()) {
      String email = _emailController.text;
      String password = _passwordController.text;

      if (email == "admin" && password == "admin") {
       Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Invalid Credentials")),
        );
      }
    }
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
              boxShadow: [
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
    return Column(
      mainAxisSize: MainAxisSize.min,
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
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: _buildLoginForm(),
        ),
      ],
    );
  }

  /// Login Form with Validation
  Widget _buildLoginForm() {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "Login",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _emailController,
            decoration: InputDecoration(
              labelText: "Username",
              border: OutlineInputBorder(),
            ),
            validator: (value) =>
                value == null || value.isEmpty ? "Enter username" : null,
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _passwordController,
            obscureText: true,
            decoration: InputDecoration(
              labelText: "Password",
              border: OutlineInputBorder(),
            ),
            validator: (value) =>
                value == null || value.isEmpty ? "Enter password" : null,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _login,
            child: const Text("Login"),
          ),
        ],
      ),
    );
  }
}*/
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quick_mart_admin/home.dart';

// Create a Provider class to manage login state
class LoginProvider with ChangeNotifier {
  String? _errorMessage;

  String? get errorMessage => _errorMessage;

  void login(String email, String password, BuildContext context) {
    if (email == "admin" && password == "admin") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
      _errorMessage = null; // Clear any previous error
      notifyListeners();
    } else {
      _errorMessage = "Invalid Credentials";
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}

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
              boxShadow: [
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
    return Column(
      mainAxisSize: MainAxisSize.min,
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
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: _buildLoginForm(),
        ),
      ],
    );
  }

  /// Login Form with Validation
  Widget _buildLoginForm() {
    final loginProvider = Provider.of<LoginProvider>(context);

    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "Login",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: "Username",
              border: OutlineInputBorder(),
            ),
            validator: (value) =>
                value == null || value.isEmpty ? "Enter username" : null,
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _passwordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: "Password",
              border: OutlineInputBorder(),
            ),
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
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                loginProvider.login(
                  _emailController.text,
                  _passwordController.text,
                  context,
                );
              }
            },
            child: const Text("Login"),
          ),
        ],
      ),
    );
  }
}
