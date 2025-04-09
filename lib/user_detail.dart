import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserDetailsPage extends StatefulWidget {
  const UserDetailsPage({Key? key}) : super(key: key);

  @override
  _UserDetailsPageState createState() => _UserDetailsPageState();
}

class _UserDetailsPageState extends State<UserDetailsPage> {
  List<Map<String, dynamic>> _users = [];
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
        _users.add(doc.data());
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("User Details"), // Changed title to "User Details"
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _users.isEmpty
              ? const Center(child: Text("No users found."))
              : ListView.builder(
                  itemCount: _users.length,
                  itemBuilder: (context, index) {
                    final user = _users[index];
                    return ListTile(
                      title: Text(user['name'] ?? 'N/A'),
                      subtitle: Text(user['email'] ?? 'N/A'),
                      trailing: ElevatedButton(
                        child: const Text("View Details"), // Changed button text
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  IndividualUserDetailsScreen(userData: user), // Using a new name for the individual details screen
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
    );
  }
}

class IndividualUserDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> userData;

  const IndividualUserDetailsScreen({Key? key, required this.userData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Individual User Details"), // More specific title
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Name: ${userData['name'] ?? 'N/A'}",
                style: const TextStyle(fontSize: 18)),
            Text("Email: ${userData['email'] ?? 'N/A'}",
                style: const TextStyle(fontSize: 18)),
            Text("Location: ${userData['location'] ?? 'N/A'}",
                style: const TextStyle(fontSize: 18)),
            Text("Phone: ${userData['phone'] ?? 'N/A'}",
                style: const TextStyle(fontSize: 18)),
            // Add more details as needed
          ],
        ),
      ),
    );
  }
}