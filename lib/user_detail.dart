// lib/user_detail.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart'; // Import url_launcher

class UserDetailsPage extends StatefulWidget {
  const UserDetailsPage({Key? key}) : super(key: key);

  @override
  _UserDetailsPageState createState() => _UserDetailsPageState();
}

class _UserDetailsPageState extends State<UserDetailsPage> {
  final List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final QuerySnapshot<Map<String, dynamic>> snapshot =
          await FirebaseFirestore.instance.collection("users").get();
      _users.clear();
      for (var doc in snapshot.docs) {
        _users.add({...doc.data(), 'id': doc.id});
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error loading users: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
  print('Attempting to call: $phoneNumber'); // Add this line
  final Uri launchUri = Uri(
    scheme: 'tel',
    path: phoneNumber,
  );
  if (await canLaunchUrl(launchUri)) {
    await launchUrl(launchUri);
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Could not launch $phoneNumber'),
        backgroundColor: Colors.red,
      ),
    );
  }
}

Future<void> _launchWhatsApp(String phoneNumber) async {
  // Ensure the phone number includes the country code for WhatsApp.
  // Example: "919876543210" for an Indian number
  print('Attempting to launch WhatsApp for: $phoneNumber'); // Add this line
  String whatsappUrl = "whatsapp://send?phone=$phoneNumber";
  final Uri launchUri = Uri.parse(whatsappUrl);

  if (await canLaunchUrl(launchUri)) {
    await launchUrl(launchUri);
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Could not launch WhatsApp for $phoneNumber. Make sure WhatsApp is installed.'),
        backgroundColor: Colors.red,
      ),
    );
  }
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("User Details"),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _users.isEmpty
              ? const Center(child: Text("No users found."))
              : ListView.builder( // Changed to ListView.builder
                  padding: const EdgeInsets.all(16.0), // Padding for the whole list
                  itemCount: _users.length,
                  itemBuilder: (context, index) {
                    final user = _users[index];
                    final String name = user['name'] ?? 'N/A';
                    final String email = user['email'] ?? 'N/A';
                    final String location = user['location'] ?? 'N/A';
                    final String phone = user['phone'] ?? 'N/A';

                    return Card(
                      elevation: 4,
                      margin: const EdgeInsets.only(bottom: 16.0), // Add margin between cards for spacing
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row( // Use Row to arrange content horizontally
                          children: [
                            Expanded( // User details take most of the available space
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Email: $email',
                                    style: const TextStyle(fontSize: 14),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    'Location: $location',
                                    style: const TextStyle(fontSize: 14),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    'Phone: $phone',
                                    style: const TextStyle(fontSize: 14),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16), // Space between details and icons
                            Column( // Icons arranged vertically on the right
                              mainAxisAlignment: MainAxisAlignment.center, // Center icons vertically
                              children: [
                                // Call Button
                                GestureDetector(
                                  onTap: () => _makePhoneCall(phone),
                                  child: Image.asset(
                                    'assets/images/call.png', // Your call icon path
                                    width: 30,
                                    height: 30,
                                    errorBuilder: (context, error, stackTrace) =>
                                        const Icon(Icons.call, color: Colors.blue, size: 30), // Fallback icon
                                  ),
                                ),
                                const SizedBox(height: 12), // Spacing between icons
                                // WhatsApp Button
                                GestureDetector(
                                  onTap: () => _launchWhatsApp(phone),
                                  child: Image.asset(
                                    'assets/images/wtsap.jpg', // Your WhatsApp icon path
                                    width: 40,
                                    height: 40,
                                    errorBuilder: (context, error, stackTrace) =>
                                        const Icon(Icons.chat, color: Colors.green, size: 30), // Fallback icon
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}