import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'bmi_calculator.dart';
import 'language_provider.dart';

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final TextEditingController controlWeight = TextEditingController();
  final TextEditingController controlHeight = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String _info = "";
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _info = AppLocalizations.of(context)!.reportData;
      });
    });
  }

  void _resetFields() {
    controlHeight.text = "";
    controlWeight.text = "";
    setState(() {
      _info = AppLocalizations.of(context)!.reportData;
    });
  }

  Future<void> _calculate() async {
    if (_formKey.currentState!.validate()) {
      double weight = double.parse(controlWeight.text);
      double height = double.parse(controlHeight.text) / 100;
      double imc = BMICalculator.calculateBMI(weight, height);
      String result = BMICalculator.getBMIResult(imc); // Pass context for translations

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
      await _auth.signOut();
      print("User signed out successfully");

      if (mounted) {
        context.pushReplacement('/sign-in');
      }
    } catch (e) {
      print("Error signing out: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    User? user = _auth.currentUser;
    final localizations = AppLocalizations.of(context)!;
    final languageProvider = Provider.of<LanguageProvider>(context);

    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.pushReplacement('/sign-in');
      });
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          localizations.appTitle,
          style: TextStyle(fontFamily: "Segoe UI", fontSize: 24),
        ),
        centerTitle: true,
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _resetFields,
          ),
          IconButton(
            icon: Icon(Icons.language),
            onPressed: () {
              _showLanguageDialog(context, languageProvider);
            },
          ),
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _signOut,
          ),
        ],
      ),
      backgroundColor: Colors.grey[200],
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                Icons.person,
                size: 120.0,
                color: Colors.teal,
              ),
              SizedBox(height: 20),
              _buildTextField(localizations.weight, controlWeight, "weight"),
              SizedBox(height: 20),
              _buildTextField(localizations.height, controlHeight, "height"),
              SizedBox(height: 20),
              Padding(
                padding: EdgeInsets.only(top: 10.0, bottom: 10.0),
                child: SizedBox(
                  height: 50.0,
                  child: ElevatedButton(
                    onPressed: _calculate,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      textStyle: TextStyle(
                        fontSize: 20.0,
                        fontFamily: "Segoe UI",
                      ),
                    ),
                    child: Text(
                      localizations.calculate,
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20),
              Text(
                _info,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.teal,
                  fontSize: 25.0,
                  fontFamily: "Segoe UI",
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  context.push('/history');
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                child: Text(localizations.viewHistory),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, String field) {
    return TextFormField(
      keyboardType: TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: Colors.teal,
          fontFamily: "Segoe UI",
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
      ),
      textAlign: TextAlign.center,
      style: TextStyle(
        color: Colors.teal,
        fontSize: 25.0,
        fontFamily: "Segoe UI",
      ),
      controller: controller,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return field == "weight" ? AppLocalizations.of(context)!.insertWeight : AppLocalizations.of(context)!.insertHeight;
        }
        return null;
      },
    );
  }

  void _showLanguageDialog(BuildContext context, LanguageProvider languageProvider) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.language),
          content: Container(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: languageProvider.languages.length,
              itemBuilder: (context, index) {
                final language = languageProvider.languages[index];
                return ListTile(
                  title: Text(language['name']),
                  onTap: () {
                    languageProvider.setLocale(language['locale']);
                    Navigator.pop(context);
                    setState(() {
                      _info = AppLocalizations.of(context)!.reportData;
                    });
                  },
                  trailing: languageProvider.locale.languageCode == language['locale'].languageCode
                      ? Icon(Icons.check, color: Colors.teal)
                      : null,
                );
              },
            ),
          ),
        );
      },
    );
  }
}
