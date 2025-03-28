import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BMIHistoryScreen extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Map<String, dynamic>>> _fetchBMIResults() async {
    User? user = _auth.currentUser;
    if (user == null) {
      print("User is not logged in");
      return [];
    }

    try {
      final snapshot = await _firestore
          .collection('bmiResults')
          .where('userId', isEqualTo: user.uid)
          .orderBy('timestamp', descending: true)
          .get();

      if (snapshot.docs.isEmpty) {
        print("No BMI results found for user: ${user.uid}");
        return [];
      }

      print("Fetched ${snapshot.docs.length} BMI results");
      return snapshot.docs.map((doc) {
        print("Document data: ${doc.data()}");
        return doc.data();
      }).toList();
    } catch (e) {
      print("Error fetching BMI results: $e");
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("BMI History"),
        backgroundColor: Colors.green,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchBMIResults(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            print("FutureBuilder error: ${snapshot.error}");
            return Center(child: Text("Error loading data"));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text("No BMI results found"));
          }

          var bmiResults = snapshot.data!;

          return ListView.builder(
            itemCount: bmiResults.length,
            itemBuilder: (context, index) {
              var data = bmiResults[index];
              return ListTile(
                title: Text("BMI: ${data['bmi'].toStringAsFixed(2)}"),
                subtitle: Text("Result: ${data['result']}"),
                trailing: Text(
                  "${data['timestamp'].toDate()}",
                  style: TextStyle(fontSize: 12),
                ),
              );
            },
          );
        },
      ),
    );
  }
}