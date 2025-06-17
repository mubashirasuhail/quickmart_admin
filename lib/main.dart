// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import FirebaseAuth
import 'package:quick_mart_admin/color.dart';

import 'package:quick_mart_admin/login.dart'; // Your LoginScreen
import 'package:quick_mart_admin/home.dart';
import 'package:quick_mart_admin/login_provider.dart'; // Your HomeScreen


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Initialize Firebase first
  runApp(
    MultiProvider(
      providers: [
        // Provide LoginProvider throughout the app's lifecycle
        ChangeNotifierProvider(create: (_) => LoginProvider()),
        // Add other providers here if your app uses them, e.g.:
        // ChangeNotifierProvider(create: (_) => ProductProvider()),
        // ChangeNotifierProvider(create: (_) => OrderProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quickmart Admin',
      debugShowCheckedModeBanner: false, // Set to false to remove the debug banner
      theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: AppColors.darkgreen),
        useMaterial3: true,
      ),
      // Determine the initial route based on authentication status
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(), // Listen to auth state changes
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // Show a loading indicator while checking auth state
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }
          if (snapshot.hasData) {
            // User is logged in, navigate to HomeScreen
            return const HomeScreen();
          } else {
            // User is not logged in, navigate to LoginScreen
            return const LoginScreen();
          }
        },
      ),
      // Define named routes for easier navigation (optional but good practice)
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
      },
    );
  }
}