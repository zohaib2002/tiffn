// First, add these imports at the top
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:ntp/ntp.dart';
import 'package:tiffn/customer_home.dart';
import 'package:tiffn/mess_home.dart';
import 'package:tiffn/usertype.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tiffn/global.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController phoneController = TextEditingController();
  final List<TextEditingController> otpControllers = List.generate(
    6,
        (index) => TextEditingController(),
  );
  bool showOtpInput = false;
  String? _verificationId;
  bool isLoading = true;

  Future<void> loadAPIs() async {
    DocumentSnapshot apiSnap = await _firestore.collection('externalAPIs').doc('APIKeys').get();
    if (apiSnap.exists) {
      Map<String, dynamic> apiData = apiSnap.data() as Map<String, dynamic>;
      imgBBkey = apiData['imgbb'];
      razorpay_keyId = apiData['razorpay']['keyID'];
      razorpay_keySecret = apiData['razorpay']['keySecret'];
    }
  }

  @override
  void initState() {
    super.initState();
    checkAuthState();
  }

  Future<void> checkAuthState() async {
    await loadAPIs();
    User? user = _auth.currentUser;
    if (user != null) {
      // User is already logged in
      await checkUserType(user.uid);
    }
    else {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> checkUserType(String uid) async {
    try {
      DocumentSnapshot custDoc = await _firestore.collection('customers').doc(uid).get();
      DocumentSnapshot messDoc = await _firestore.collection('mess').doc(uid).get();

      if (!custDoc.exists && !messDoc.exists ) {
        // Completely new registration
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => UserType()),
        );
      } else if (custDoc.exists) {

        // load addressIndex from shared preferences
        SharedPreferences prefs = await SharedPreferences.getInstance();
        selectedAddressIndex = prefs.getInt('selectedAddressIndex') ?? 0;
        selectedAddress = custDoc.get('addresses')[selectedAddressIndex];

        Map<String, dynamic> custData = custDoc.data() as Map<String, dynamic>;

        // update subscriptions
        // get current date from NTP
        DateTime today = (await NTP.now());

        List<dynamic> existingSubscriptions = custDoc.get('subscriptions') ?? [];
        for (int i=0; i<existingSubscriptions.length; i++) {

          // get subscription start date as datetime
          DateTime subscriptionStartDate = ((existingSubscriptions[i]['startDate']).toDate());

          // get subscription end date as datetime
          DateTime subscriptionEndDate = subscriptionStartDate.add(Duration(days: 30));

          // see if enddate has surpassed today
          if (subscriptionEndDate.isBefore(today)) {
            // remove subscription from subscriptions

            String messID = existingSubscriptions[i]['messID'];

            existingSubscriptions.removeAt(i);

            //update ar firebase
            await _firestore.collection('customers').doc(uid).update({
              'subscriptions': existingSubscriptions,
            });

            //update mess subscribers too
            await _firestore.collection('mess').doc(messID).update({
              'subscribers': FieldValue.arrayRemove([uid]),
            });

            //update the custData (updates automatically) (reference)
            //custData['subscriptions'] = existingSubscriptions;
          }

        }


        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => CustomerHomePage(userData: custData)), // aslo pass user data
        );
      } else if (messDoc.exists) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MessHome(messDoc.data() as Map<String, dynamic>)), // aslo pass user data
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error checking user status: $e')),
      );
    }
  }

  Future<void> verifyPhone() async {
    setState(() {
      isLoading = true;
    });

    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: '+91${phoneController.text}', // Assuming Indian phone numbers
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _auth.signInWithCredential(credential);
          User? user = _auth.currentUser;
          if (user != null) {
            await checkUserType(user.uid);
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          setState(() {
            isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Verification Failed: ${e.message}')),
          );
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() {
            _verificationId = verificationId;
            showOtpInput = true;
            isLoading = false;
          });
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          setState(() {
            _verificationId = verificationId;
            isLoading = false;
          });
        },
        timeout: const Duration(seconds: 60),
      );
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> verifyOTP() async {
    setState(() {
      isLoading = true;
    });

    try {
      String otp = otpControllers.map((controller) => controller.text).join();

      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otp,
      );

      UserCredential userCredential = await _auth.signInWithCredential(credential);
      User? user = userCredential.user;

      if (user != null) {
        // Save login state
        // this is probably not required
        //SharedPreferences prefs = await SharedPreferences.getInstance();
        //await prefs.setBool('isLoggedIn', true);
        //await prefs.setString('userId', user.uid);

        // Check user type and navigate
        await checkUserType(user.uid);
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to verify OTP: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('tiffn', style: TextStyle(fontWeight: FontWeight.bold),),
      ),
      body: Stack(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Phone Number Input Page
              Visibility(
                visible: !showOtpInput,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Login / Register',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 32),
                      TextFormField(
                        controller: phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.phone),
                          prefixText: '+91 ', // Assuming Indian phone numbers
                          hintText: 'Phone Number',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Theme.of(context).primaryColor,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : verifyPhone,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Continue',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // OTP Input Page
              Visibility(
                visible: showOtpInput,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Enter verification code',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Code sent to +91 ${phoneController.text}',
                        style: TextStyle(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(
                          6,
                              (index) => SizedBox(
                            width: 40,
                            child: TextFormField(
                              controller: otpControllers[index],
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              maxLength: 1,
                              decoration: InputDecoration(
                                counterText: '',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: Theme.of(context).primaryColor,
                                    width: 2,
                                  ),
                                ),
                              ),
                              onChanged: (value) {
                                if (value.isNotEmpty && index < 5) {
                                  FocusScope.of(context).nextFocus();
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : verifyOTP,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Verify & Continue',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: isLoading
                            ? null
                            : () {
                          setState(() {
                            showOtpInput = false;
                          });
                        },
                        child: const Text('Change Phone Number'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}