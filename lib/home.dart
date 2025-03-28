import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart'; // Import GoRouter
import 'bmi_calculator.dart';
import 'bmi_history.dart';

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final TextEditingController controlWeight = TextEditingController();
  final TextEditingController controlHeight = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String _info = "Report your data";
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _resetFields() {
    controlHeight.text = "";
    controlWeight.text = "";
    setState(() {
      _info = "Report your data";
    });
  }

  Future <void> _calculate() async {
    if (_formKey.currentState!.validate()) {
      double weight = double.parse(controlWeight.text);
      double height = double.parse(controlHeight.text) / 100;
      double imc = BMICalculator.calculateBMI(weight, height);
      String result = BMICalculator.getBMIResult(imc);

      setState(() {
        _info = result;
      });

      // Save the result to Firestore
      User? user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('bmiResults').add({
          'userId': user.uid,
          'bmi': imc,
          'result': result,
          'timestamp': DateTime.now(),
        });
      }
    }
  }

  void _signOut() async {
    try {
      await _auth.signOut(); // Sign out the user
      print("User signed out successfully");

      // Navigate to the sign-in screen after logout
      if (mounted) {
        context.pushReplacement('/sign-in'); // Use GoRouter to navigate
      }
    } catch (e) {
      print("Error signing out: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    User? user = _auth.currentUser;

    if (user == null) {
      // Redirect to the sign-in screen if the user is not logged in
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.pushReplacement('/sign-in'); // Use GoRouter's pushReplacement
      });
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "BMI CALCULATOR",
          style: TextStyle(fontFamily: "Segoe UI"),
        ),
        centerTitle: true,
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _resetFields,
          ),
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _signOut,
          ),
        ],
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(10.0, 0.0, 10.0, 0.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                Icons.person,
                size: 120.0,
                color: Colors.green,
              ),
              TextFormField(
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: "Weight (Kg)",
                  labelStyle: TextStyle(
                    color: Colors.green,
                    fontFamily: "Segoe UI",
                  ),
                ),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.green,
                  fontSize: 25.0,
                  fontFamily: "Segoe UI",
                ),
                controller: controlWeight,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Insert your weight!";
                  }
                  return null;
                },
              ),
              TextFormField(
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "Height (cm)",
                  labelStyle: TextStyle(
                    color: Colors.green,
                    fontFamily: "Segoe UI",
                  ),
                ),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.green,
                  fontSize: 25.0,
                  fontFamily: "Segoe UI",
                ),
                controller: controlHeight,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Insert your height!";
                  }
                  return null;
                },
              ),
              Padding(
                padding: EdgeInsets.only(top: 10.0, bottom: 10.0),
                child: SizedBox(
                  height: 50.0,
                  child: ElevatedButton(
                    onPressed: _calculate,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      textStyle: TextStyle(
                        fontSize: 25.0,
                        fontFamily: "Segoe UI",
                      ),
                    ),
                    child: Text(
                      "Calculate",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),
              Text(
                _info,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.green,
                  fontSize: 25.0,
                  fontFamily: "Segoe UI",
                ),
              ),
              Padding(
                padding: EdgeInsets.only(top: 10.0),
                child: ElevatedButton(
                  onPressed: () {
                    context.push('/history'); // Use GoRouter's push
                  },
                  child: Text("View History"),
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }
}