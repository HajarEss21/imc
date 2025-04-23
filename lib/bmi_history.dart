import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class BMIHistoryScreen extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  BMIHistoryScreen({super.key});

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

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id, // Needed for deletion
          'bmi': (data['bmi'] as num?)?.toDouble() ?? 0.0,
          'result': data['result'] ?? '',
          'timestamp': (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
        };
      }).toList();
    } catch (e) {
      print("Error fetching BMI results: $e");
      return [];
    }
  }

  void _confirmAndDelete(BuildContext context, String docId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.confirmDeleteTitle),
        content: Text(AppLocalizations.of(context)!.confirmDeleteMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _firestore.collection('bmiResults').doc(docId).delete();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(AppLocalizations.of(context)!.deletedSuccessfully)),
              );
            },
            child: Text(AppLocalizations.of(context)!.someLocalizedString, style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final local = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(local.bmiHistoryTitle),
        backgroundColor: Colors.green,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>( 
        future: _fetchBMIResults(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text(local.errorLoadingData));
          }

          final bmiResults = snapshot.data ?? [];

          if (bmiResults.isEmpty) {
            return Center(child: Text(local.noHistoryMessage));
          }

          return ListView.builder(
            itemCount: bmiResults.length,
            itemBuilder: (context, index) {
              final result = bmiResults[index];
              return ListTile(
                title: Text("${local.bmiLabel}: ${result['bmi'].toStringAsFixed(2)}"),
                subtitle: Text("${local.resultLabel}: ${result['result']}"),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      result['timestamp'].toString(),
                      style: const TextStyle(fontSize: 12),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _confirmAndDelete(context, result['id']),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
