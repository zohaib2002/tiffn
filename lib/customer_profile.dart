import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:tiffn/chatbot.dart';
import 'package:tiffn/customer_registration.dart';
import 'package:tiffn/login_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'global.dart';

class CustomerProfile extends StatefulWidget {

  final Map<String, dynamic> userData;

  const CustomerProfile({required this.userData, super.key});

  @override
  State<CustomerProfile> createState() => _CustomerProfileState();
}

class _CustomerProfileState extends State<CustomerProfile> {

  bool isloaded = false;
  List<String> messNames = [];

  bool isOrdersLoaded = false;
  List<dynamic> existingOrders = [];


  Future<void> loadUserDetials() async {
    try {

      // load all mess names from subscriptions
      for (int i=0; i<widget.userData['subscriptions'].length; i++) {
        DocumentSnapshot messDoc = await FirebaseFirestore.instance.collection('mess').doc(widget.userData['subscriptions'][i]['messID']).get();
        messNames.add(messDoc.get('name'));
      }

      setState(() {
        isloaded = true;
      });
    }
    catch (e) {
      print('Error loading user details: $e');
    }
  }

  Future<void> loadActiveOrders() async {
    // get all active orders
    existingOrders = await fetchExistingActiveOrders();
    setState(() {
      isOrdersLoaded = true;
    });
  }


  List<Widget> generateSubscriptionTiles() {
    List<Widget> tiles = [];

    for (int i = 0; i < widget.userData['subscriptions'].length; i++) {
      DateTime dateTime = (widget.userData['subscriptions'][i]['startDate']).toDate();
      DateTime endTime = dateTime.add(Duration(days: 30));

      tiles.add(Container(
        margin: EdgeInsets.all(8),
        decoration: BoxDecoration(
            color: Colors.green[50],
            borderRadius: BorderRadius.circular(10)
        ),
        child: ListTile(
          title: Text(messNames[i],
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),),
          subtitle: Text('   Start Date: ${DateFormat('dd-MM-yyyy').format((dateTime))}\n'
              '   End Date: ${DateFormat('dd-MM-yyyy').format((endTime))}'),
        ),
      ));
    }

    return tiles;
  }

    List<Widget> generateOrderTiles(Function updateOrdersList)  {
      List<Widget> tiles = [];

      if (existingOrders.length == 0) {
        return [
          SizedBox(height: 10,),
          Center(child: Text("No Active Orders"))
        ];
      }

      if (! isOrdersLoaded ) {
        return [Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
        ],
      )];
      }

      for (int i=0; i<existingOrders.length; i++) {

        String itemString = '';
        for (String item in existingOrders[i]['items']) {
          itemString += '   $item\n';
        }

        tiles.add(Container(
          margin: EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(10)
          ),
          child: ListTile(
            title: Text(existingOrders[i]['messName'], style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(' Status: ${['Order Placed', 'Order Confirmed', 'Preparing Order', 'Out for Delivery', 'Awaiting Review'][existingOrders[i]['status']]}\n', style: TextStyle(
                  fontWeight: FontWeight.bold
                ),),
                Text(itemString),

                (existingOrders[i]['status'] == 4) ? ElevatedButton(onPressed: () {
                  /// rating modal bottom sheet view

                  showModalBottomSheet(
                    context: context,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
                    ),
                    builder: (BuildContext context) {
                      int selectedStars = 0; // Stores the selected rating

                      return StatefulBuilder(
                        builder: (context, setState) {
                          return Container(
                            padding: EdgeInsets.all(16),
                            height: 200,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text("Rate Order", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                SizedBox(height: 15),

                                // Star Rating System
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: List.generate(5, (index) {
                                    return GestureDetector(
                                      onTap: () {
                                        setState(() => selectedStars = index + 1);
                                      },
                                      child: Icon(
                                        index < selectedStars ? Icons.star : Icons.star_border,
                                        color: Colors.amber,
                                        size: 40,
                                      ),
                                    );
                                  }),
                                ),

                                SizedBox(height: 20),
                                ElevatedButton(
                                  onPressed: () async {

                                    // get mess document
                                    String userID = FirebaseAuth.instance.currentUser!.uid;
                                    DocumentReference messRef = FirebaseFirestore.instance.collection('mess').doc(existingOrders[i]['messID']);
                                    DocumentSnapshot messSnap = await messRef.get();
                                    Map<String, dynamic> messData = messSnap.data() as Map<String, dynamic>;
                                    int currentTotalRatings = messData['totalRatings'];
                                    double currentAvgRating = messData['avgRating'].toDouble();

                                    await messRef.update({
                                      'avgRating': (currentAvgRating * currentTotalRatings + selectedStars) / (currentTotalRatings + 1),
                                      'totalRatings': currentTotalRatings + 1,
                                    });


                                    FirebaseFirestore.instance.collection('activeUserOrders').doc(userID).update({
                                      'activeOrders': FieldValue.arrayRemove([existingOrders[i]]),
                                    });

                                    updateOrdersList(() {
                                      existingOrders.removeAt(i);

                                    });
                                     // Use the rating as needed
                                    Navigator.pop(context);
                                  },
                                  child: Text("Submit"),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  );


                }, child: Text("Rate Order")) : SizedBox()
              ],
            ),
          ),
        ));
      }

    //format the time user['subscriptions'][i]['startDate'] in dd-mm-yyyy format

      return tiles;
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    loadUserDetials(); // MessNames
    loadActiveOrders();
  }


  @override
  Widget build(BuildContext context) {
    return  Padding(
      padding: const EdgeInsets.all(16.0),
      child: (isloaded) ? SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start  ,
          children: [
            Text(widget.userData['fullName'], style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),),
            Text(widget.userData['phoneNumber'], style: TextStyle(fontSize: 16, color: Colors.grey),),
            SizedBox(height: 20,),
        
            Text('Current Address', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),),
            SizedBox(height: 10,),
            Text('Only the messes that are near your address are shown', style: TextStyle(
              fontSize: 13,
              color: Colors.grey
            ),),
            SizedBox(height: 10,),
            //drop down menu for addresses
            DropdownButton<int>(
              itemHeight: 80,
              value: selectedAddressIndex ,// change with default loaded from sharedprefs
              hint: Text('Select an address'),
              isExpanded: true,
              items: (widget.userData['addresses'] as List<dynamic>)
                  .map<DropdownMenuItem<int>>((address) {
                return DropdownMenuItem<int>(
                  value: widget.userData['addresses'].indexOf(address),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(address['name'].toString(), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),),
                      Text(address['text'], style: TextStyle(fontWeight: FontWeight.normal),),
                      SizedBox(height: 10,)
                    ],
                  ),
                );
              }).toList(),
              onChanged: (int? newValue) {
                setState(() {
                  selectedAddressIndex = newValue!;
                  selectedAddress = widget.userData['addresses'][newValue];
        
                  // save this index in shared preferences
                  SharedPreferences.getInstance().then((prefs) {
                    prefs.setInt('selectedAddressIndex', selectedAddressIndex);
                  });
                });
              },
            ),
            SizedBox(height: 20,),
        
        
            Text('Subscriptions', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),),

            Text("To manage Subscriptions, contact support", style: TextStyle(
                fontSize: 13,
                color: Colors.grey
            ),)
        
             ]
        
              + generateSubscriptionTiles() +
        
              [
                SizedBox(height: 20,),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Active Orders', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),),
                    IconButton(onPressed: () {
                      setState(() {
                        isOrdersLoaded = false;
                      });
                      loadActiveOrders();
                    }, icon: Icon(Icons.refresh))
                  ],
                ), ] +

               generateOrderTiles((Function updateFunction) {setState(() {
                 updateFunction();
               });})

              + [
        
        
            SizedBox(height: 20,),
                TextButton(
                  onPressed: ()  {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => CustomerRegistration(userData: widget.userData,)),
                    );
                  },
                  child: const Text('Change / Add Adresses', style: TextStyle(fontSize: 16),),
                ),
        
                TextButton(
                  onPressed: ()  {
                    showModalBottomSheet(
                      context: context,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
                      ),
                      builder: (BuildContext context) {
                        return ContactUs();////
                      },
                    );
                  },
                  child: const Text('Contact Support', style: TextStyle(fontSize: 16),),
                ),
        
            TextButton(
              onPressed: () async {
                try {
                  await FirebaseAuth.instance.signOut();

                  // clear the addressIndex from shared preferences
                  SharedPreferences prefs = await SharedPreferences.getInstance();
                  prefs.remove('selectedAddressIndex');
                  selectedAddress = {};
        
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
              child: const Text('Logout', style: TextStyle(fontSize: 16),),
            ),
          ],
        ),
      ) : CircularProgressIndicator(),
    );
  }
}
class ContactUs extends StatefulWidget {
  const ContactUs({super.key});

  @override
  State<ContactUs> createState() => _ContactUsState();
}

class _ContactUsState extends State<ContactUs> {

  bool isLoaded = false;
  Map<String, dynamic> contactDetails = {};

  Future<void> loadContact() async {
    // get firestore document reference for collection contact
    DocumentSnapshot contactSnap = await FirebaseFirestore.instance.collection('contact').doc('contactDetails').get();
    contactDetails = contactSnap.data() as Map<String, dynamic>;

    setState(() {
      isLoaded = true;
    });

  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    loadContact();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      height: 180, // Adjust as needed
      width: MediaQuery.of(context).size.width,
      child: (isLoaded) ? Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          Text("Preferred mode of contact", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green[900])),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(onPressed: () {
                //open dailer with number
                launchUrl(Uri.parse("tel:${contactDetails['phone']}"));
              }, icon: Column(
                children: [
                  Icon(Icons.perm_phone_msg_outlined, size: 50, color: Colors.grey[500],),
                  Text("Phone Call", style: TextStyle(color: Colors.grey[500], fontSize: 12),)
                ],
              )),
              IconButton(onPressed: () {
                // launch url to mail
                launchUrl(Uri.parse("mailto:${contactDetails['email']}"));
              }, icon: Column(
                children: [
                  Icon(Icons.mail_outline_rounded, size: 50, color: Colors.grey[500],),
                  Text("Email", style: TextStyle(color: Colors.grey[500], fontSize: 12),)
                ],
              )),
              IconButton(onPressed: () {
                //open chatbot page using navigator.push
                Navigator.push(context, MaterialPageRoute(builder: (context) => Chatbot()));

              }, icon: Column(
                children: [
                  Icon(Icons.chat_bubble_outline, size: 50, color: Colors.grey[500],),
                  Text("Live Chat", style: TextStyle(color: Colors.grey[500], fontSize: 12),)
                ],
              )),
            ],
          )
        ],
      ) : Center(child: CircularProgressIndicator()),
    );
  }
}
