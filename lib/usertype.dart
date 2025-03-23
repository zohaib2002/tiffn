import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:tiffn/customer_registration.dart';
import 'package:tiffn/mess_registration.dart';

class UserType extends StatefulWidget {
  const UserType({super.key});

  @override
  State<UserType> createState() => _UserTypeState();
}

class _UserTypeState extends State<UserType> {
  String _selectedRole = "Customer"; // Default selected role
  final FirebaseAuth _auth = FirebaseAuth.instance;


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('tiffn', style: TextStyle(fontWeight: FontWeight.bold),),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              "I am a,",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Radio<String>(
                      value: "Customer",
                      groupValue: _selectedRole,
                      onChanged: (value) {
                        setState(() {
                          _selectedRole = value!;
                        });
                      },
                    ),
                    Text("Customer"),
                  ],
                ),
                SizedBox(width: 30,),
                Row(
                  children: [
                    Radio<String>(
                      value: "Mess Owner",
                      groupValue: _selectedRole,
                      onChanged: (value) {
                        setState(() {
                          _selectedRole = value!;
                        });
                      },
                    ),
                    Text("Mess Owner"),
                  ],
                ),
              ],
            ),
            SizedBox(height: 30),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  // Handle continue button press
                  if (_selectedRole == 'Customer') {
                    Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (context) => CustomerRegistration()),
                  );
                  } else {
                    Navigator.pushReplacement(context,
                      MaterialPageRoute(builder: (context) => MessRegistration()),
                    );
                  }

                },
                child: Text("Continue"),
              ),
            ),
            SizedBox(height: 100),
            Text("Signed in using ${_auth.currentUser!.phoneNumber}"),
            InkWell(
              child: Text(
                '\nUse another number',
                style: TextStyle(color: Colors.green,),
              ),
              onTap: () {
                _auth.signOut();
              },
            )
          ],
        ),
      ),
    );
  }
}
