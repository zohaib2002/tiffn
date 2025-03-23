import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ntp/ntp.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:tiffn/global.dart';

class CheckoutScreen extends StatefulWidget {

  final Map<dynamic, dynamic> mess;
  final Map<String, dynamic> user;
  final Cart cart;
  const CheckoutScreen({super.key, required this.mess, required this.user, required this.cart});


  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {

  Future<void> handlePaymentSuccess() async {
    try {
      // Get current user
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        String userId = user.uid; // Get user ID

        // get existing subscriptions
        widget.user['subscriptions'] ??= [];
        List existingSubscriptions = widget.user['subscriptions'];

        if (existingSubscriptions.length == 3) {
          // show snackbar
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('You have reached the limit of 3 subscriptions')),
          );
          return;
        }


        Map<String,dynamic> newSubscription = {
          'messID': widget.mess['id'],
          'meals' : widget.cart.toList(),
          'startDate' : await NTP.now(),
        };

        existingSubscriptions.add(newSubscription); //implicitly updates widget.user too (copy by reference)

        await FirebaseFirestore.instance.collection('customers').doc(userId).update({
          'subscriptions': existingSubscriptions,
        });

        masterSetState!(userData: widget.user);

        // add userID to messes document too.
        DocumentSnapshot messDoc = await FirebaseFirestore.instance.collection('mess').doc(widget.mess['id']).get();
        List existingSubscribers = messDoc.get('subscribers') ?? [];

        existingSubscribers.add(userId);

        await FirebaseFirestore.instance.collection('mess').doc(widget.mess['id']).update({
          'subscribers': existingSubscribers,
        });

        // clear cart
        widget.cart.empty();

        //pop unitl home
        Navigator.popUntil(context, (route) => route.isFirst);

        //show snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Subscribed Successfully')),
        );


        print('User document updated successfully');
      } else {
        print('No user logged in');
      }
    } catch (e) {
      print('Error updating user document: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Checkout'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(30.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(widget.mess['name'], style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold
              ),),
              Text(widget.mess['location']['address'], style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold
              ),),
              SizedBox(height: 20,),
              Divider(),
              SizedBox(height: 10,),
          
              Text(widget.cart.toText()),
              Divider(),
              SizedBox(height: 10,),
              Padding(
                padding: const EdgeInsets.only(left: 50, right: 50),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                  Row(
                    children: [
                      Expanded(child: Text('Total:', style: TextStyle(fontWeight: FontWeight.bold))),
                      Text('₹${widget.cart.total()}'),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(child: Text('GST:', style: TextStyle(fontWeight: FontWeight.bold))),
                      Text('₹${(widget.cart.total() * 0.18).toStringAsFixed(2)}'),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(child: Text('Platform Fee:', style: TextStyle(fontWeight: FontWeight.bold))),
                      Text('₹${(widget.cart.total() * 0.05).toStringAsFixed(2)}'),
                    ],
                  ),
                    SizedBox(height: 10,),
                    Row(
                      children: [
                        Expanded(child: Text('Grand Total:', style: TextStyle(fontWeight: FontWeight.bold))),
                        Text('₹${(widget.cart.total() + (widget.cart.total() * 0.18) + (widget.cart.total() * 0.05)).toStringAsFixed(2)}'),
                      ],
                    ),
                ],),
              ),

          
              SizedBox(height: 10,),
              Divider(),
              SizedBox(height: 20,),
          
              ElevatedButton(onPressed: ()async{
                // add subscriiption details to user including mess id to check if user is in delivery cycle
                int total = (widget.cart.total() + (widget.cart.total() * 0.18) + (widget.cart.total() * 0.05)).floor();

                Razorpay razorpay = Razorpay();
                var options = {
                  'key': razorpay_keyId,
                  'amount': total*100,
                  'name': widget.mess['name'],
                  'description': widget.mess['description'],
                  'retry': {'enabled': true, 'max_count': 1},
                  'send_sms_hash': true,
                  'prefill': {'contact': widget.mess['phoneNumber'], 'email': 'contact@tiffn.app'},
                  'external': {
                    'wallets': ['paytm']
                  }
                };
                razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, (PaymentFailureResponse response) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Payment Failed')),
                  );
                });
                razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, (PaymentSuccessResponse response) {
                  handlePaymentSuccess();
                });
                razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, (ExternalWalletResponse response) {

                });
                razorpay.open(options);


              }, child: Text('Pay and Subscribe')),
              Text('\n\nTODO: Razorpay, check if user in delivery circle, change address from profile',textAlign: TextAlign.center,),
            ],
          ),
        ),
      ),
    );
  }
}
