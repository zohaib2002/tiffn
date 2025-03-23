import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:tiffn/checkout.dart';
import 'package:tiffn/global.dart';
import 'package:tiffn/login_page.dart';
import 'package:tiffn/mess_registration.dart';

class MessDetailsPage extends StatefulWidget {
  final Map<String, dynamic> mess;
  final bool editable; //accessed through MessHome

  const MessDetailsPage({super.key, required this.mess, this.editable = false});

  @override
  _MessDetailsPageState createState() => _MessDetailsPageState();
}

class _MessDetailsPageState extends State<MessDetailsPage> {

  Cart cart = Cart();
  bool isLoaded = false;
  bool alreadySubbed = false;

  Map<String, dynamic>? user;

  // Define the correct order of days
  final List<String> orderedDays = [
    'Sun',
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat'
  ];

  void checkSubscribed() async {
    String userId = FirebaseAuth.instance.currentUser!.uid;

    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('customers').doc(userId).get();
      List existingSubscriptions = userDoc.get('subscriptions') ?? [];

      // whether the user is already subscribed or not we can store the user data
      user = userDoc.data() as Map<String, dynamic>;

      if (existingSubscriptions.isNotEmpty) {
        for (int i=0; i<existingSubscriptions.length; i++) {
          if (existingSubscriptions[i]['messID'] == widget.mess['id']) {
            setState(() {
              alreadySubbed = true;
              isLoaded = true;
            });
            //break;
            return;
          }
        }
      }

      setState(() {
        isLoaded = true;
      });
    }
    catch (e) {
      print('Error getting user document: $e');
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    // if user opens mess details check if user is already subscribed to this mess
    if (!widget.editable) {
      // user has opened mess details
      // get userid from firebase auth
      checkSubscribed();
    }
    else {
      isLoaded = true;
    }
  }

  @override
  Widget build(BuildContext context) {

    return WillPopScope(
      onWillPop: ()async{

        // Show the dialog before allowing the back action
        bool shouldExit = await _showDiscardDialog(context);
        if (shouldExit) cart.empty();
        return shouldExit; // Return true to allow pop, false to prevent it
      },
      child: Scaffold(
        appBar: (! widget.editable) ? AppBar(
          title: Text('Mess Menu'),
          centerTitle: true,
          actions: [
            IconButton(onPressed: () {
              Navigator.push(context,
                MaterialPageRoute(builder: (context) => CertificateView(Url: widget.mess['fssaiCertificateUrl'])),
              );
            }, icon: Icon(Icons.assignment_outlined))
          ]
        ) : null,
        body: (isLoaded) ? Padding(
          padding: const EdgeInsets.all(16.0),
          child: Stack(
            alignment: AlignmentDirectional.bottomCenter,
            children: [

              ListView(
                //crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.mess['name'],
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  Text(widget.mess['location']['address'], style: TextStyle(fontSize: 16, color: Colors.grey)),
                  SizedBox(height: 10),

                  buildStarRating(widget.mess['avgRating'].toDouble(), widget.mess['totalRatings']),
                  SizedBox(height: 10),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SizedBox(
                        width: 250,
                        child: Text(widget.mess['description'], style: TextStyle(fontSize: 16)),
                      ),
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(Icons.crop_square_sharp, color: widget.mess['veg']? Colors.green: Colors.red, size: 36,),
                          Icon(Icons.circle, color: widget.mess['veg']? Colors.green: Colors.red, size: 14),
                        ],
                      ),
                    ],
                  ),

                  (alreadySubbed)? Text("\nYou have already subscribed to this mess. Please contact support to modify / cancel subscriptions", textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.orange
                  ),
                  )
                  : SizedBox(),

                  SizedBox(height: 30),
                  Text('Prices are on a per month basis', style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey
                  ),),
                  Column(
                    children: orderedDays.map<Widget>((day) {
                      if (widget.mess['menu'].containsKey(day)) {
                        final meals = widget.mess['menu'][day];
                        return ExpansionTile(
                          title: Text(dayMap[day]!.toUpperCase(),
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 20)),
                          children: meals.keys.map<Widget>((meal) {
                            final items = meals[meal]['items'];
                            final price = meals[meal]['price'].toDouble();
                            CartItem cartItem = CartItem(
                                day: day, meal: meal, price: price);
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(top: 10),
                                  child: (!widget.editable) ? CheckboxListTile(
                                    title: Row(
                                      mainAxisAlignment: MainAxisAlignment
                                          .spaceBetween,
                                      children: [
                                        Text('$meal', style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold),),
                                        Text('₹$price',
                                          style: TextStyle(fontSize: 18),)
                                      ],
                                    ),
                                    value: cart.contains(cartItem),
                                    enabled : !alreadySubbed,
                                    onChanged: (isChecked) {
                                      setState(() {
                                        if (isChecked == true) {
                                          cart.add(
                                              cartItem); // make a class for cart items.....
                                        } else {
                                          cart.remove(cartItem);
                                        }
                                      });
                                    },
                                  ) : Row(
                                    mainAxisAlignment: MainAxisAlignment
                                        .spaceBetween,
                                    children: [
                                      Text('$meal', style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold),),
                                      Text('₹$price',
                                        style: TextStyle(fontSize: 18),)
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(left: 30.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment
                                        .start,
                                    children: items.map<Widget>((item) {
                                      return Text('$item',
                                        style: TextStyle(fontSize: 16),);
                                    }).toList(),
                                  ),
                                ),
                              ],
                            );
                          }).toList() + [SizedBox(height: 16,)],
                        );
                      }
                      else {
                        return  SizedBox.shrink();
                      }
                    }

                    ).toList(),///////////
                  ),
                  SizedBox(height: 20,),
                  (widget.editable) ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextButton(
                        child: Text('Edit Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),),
                        onPressed: () {
                          Navigator.push(context,
                            MaterialPageRoute(builder: (context) => MessRegistration(mess: widget.mess)),
                          );
                        },
                      ),
                      TextButton(
                        onPressed: () async {
                          try {
                            await FirebaseAuth.instance.signOut();

                            // Navigate to login page
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(builder: (context) => LoginPage()),
                                  (route) => false,
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error signing out: $e')),
                            );
                          }
                        },
                        child: const Text('Logout', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      )
                    ],
                  ) : SizedBox(),
                 SizedBox(height: 50,),
                ],
              ),
              (cart.items.isNotEmpty && !widget.editable)? InkWell(
                onTap: () {
                  //Navigator.pop(context); pop this window only if payment is complete...
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      // will only show if !editable (opened by customer)
                      builder: (context) => CheckoutScreen(mess: widget.mess, user: user!, cart: cart),
                    ),
                  );
                },
                child: Container(
                  width: MediaQuery.of(context).size.width, // 100% width
                  height: 50, // Set the height as required
                  decoration: BoxDecoration(
                    color: Colors.green, // Set the color of the container
                    borderRadius: BorderRadius.circular(10), // Set rounded corners
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text('     Total', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),),
                      Expanded(child: Row()),
                      Text('₹${cart.total()} per Month ', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),),
                      Icon(Icons.arrow_forward_ios_rounded, color: Colors.white,),
                      SizedBox(width: 10,)
                    ],
                  ),
                ),
              ): SizedBox(),
            ],
          ),
        ): Center(child: CircularProgressIndicator(),),
      ),
    );
  }
}

Future<bool> _showDiscardDialog(BuildContext context) async {
  // Show the dialog and return the result or false if null is returned
  bool? result = await showDialog<bool>(
    context: context,
    barrierDismissible: false, // Prevent dismissing by tapping outside
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Are you sure?'),
        content: Text('All your selections will be discarded.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(false); // Don't pop, stay on the screen
            },
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(true); // Allow back action, exit screen
            },
            child: Text('Discard'),
          ),
        ],
      );
    },
  );

  // Return the result or false if the result is null
  return result ?? false;
}

class CertificateView extends StatelessWidget {

  final Url;
  const CertificateView({required this.Url, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("FSSAI Certificate"),
      ),
      body: Center(child: Container(
        color: Colors.grey[200],
        child: Stack(
          alignment: AlignmentDirectional.center,
          children: [
            CircularProgressIndicator(),
            Image.network(Url)
          ],
        ),
      )),
    );
  }
}

