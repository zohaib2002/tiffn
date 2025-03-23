import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class MessOrdersPage extends StatefulWidget {

  final Map<String, dynamic> mess;
  const MessOrdersPage({required this.mess, super.key});

  @override
  State<MessOrdersPage> createState() => _MessOrdersPageState();
}

class _MessOrdersPageState extends State<MessOrdersPage> {

  bool isOrdersLoaded = false;
  List<dynamic> activeOrders = [];
  List<String> correspondingUserIDs = [];
  String messID = "";

  Future<void> getActiveOrders() async {
    // get userid from firebase auth
    messID = FirebaseAuth.instance.currentUser!.uid;

    // get a list of all subscribers
    for (String userID in widget.mess['subscribers']) {
      // fetch user order list
      DocumentSnapshot userOrderDoc = await FirebaseFirestore.instance.collection('activeUserOrders').doc(userID).get();
      if (userOrderDoc.exists) {
        Map<String, dynamic> userOrders = userOrderDoc.data() as Map<String, dynamic>;
        List<dynamic> activeOrdersList = userOrders['activeOrders'];

        if (activeOrdersList.isNotEmpty) {
          for (dynamic order in activeOrdersList) {
            if (order['messID'] == messID && order['status'] <=3) {
              activeOrders.add(order);
              correspondingUserIDs.add(userID);
            }
          }
        }
      }
    }

    setState(() {
      isOrdersLoaded = true;
    });

  }

  List<Widget> generateOrderTiles()  {
    List<Widget> tiles = [];
    List<String> statusStrings = ['Order Placed', 'Order Confirmed', 'Preparing Order', 'Out for Delivery', 'Waiting for Review'];


    for (int i=0; i<activeOrders.length; i++) {

      String itemString = '';
      for (String item in activeOrders[i]['items']) {
        itemString += '   $item\n';
      }

      tiles.add(Container(
        margin: EdgeInsets.all(8),
        decoration: BoxDecoration(
            color: Colors.green[50],
            borderRadius: BorderRadius.circular(10)
        ),
        child: ListTile(
          title: Text(activeOrders[i]['messName'], style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(' Status: ${statusStrings[activeOrders[i]['status']]}\n', style: TextStyle(
                  fontWeight: FontWeight.bold
              ),),
              Text(itemString),
              SizedBox(height: 10,),
              ElevatedButton(onPressed: () async {

                bool confirm = await showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text("Upgrade Status"),
                      content: Text("Upgrade status to: ${statusStrings[activeOrders[i]['status'] + 1]}?"),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop(false); // User cancels
                          },
                          child: Text("Cancel"),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop(true); // User confirms
                          },
                          child: Text("Confirm"),
                        ),
                      ],
                    );
                  },
                );

                if (confirm == true) {

                  DocumentReference orderDocRef = FirebaseFirestore.instance.collection('activeUserOrders').doc(correspondingUserIDs[i]);

                  Map<String, dynamic> userOrdersData = (await orderDocRef.get()).data() as Map<String, dynamic>;

                  // deep match
                  int index = userOrdersData['activeOrders'].indexWhere((order) =>
                  order['meal'] == activeOrders[i]['meal'] &&
                      order['messID'] == activeOrders[i]['messID'] &&
                      order['day'] == activeOrders[i]['day'] &&
                      order['items'].toString() == activeOrders[i]['items'].toString() && // Ensure list comparison works
                      order['status'] == activeOrders[i]['status'] &&
                      order['messName'] == activeOrders[i]['messName']
                  );

                  //print(index);
                  //print(userOrdersData['activeOrders'][index]);

                  userOrdersData['activeOrders'][index]['status'] ++ ;

                  orderDocRef.update({
                    'activeOrders' : userOrdersData['activeOrders']
                  });

                  if (activeOrders[i]['status'] < 3) {
                    setState(() {
                      activeOrders[i]['status'] ++;
                    });
                  }

                  else {
                    // no longer can incerement
                    setState(() {
                      activeOrders.removeAt(i);
                    });
                  }

                }

              }, child: Text("Upgrade Status")),
              SizedBox(height: 10,),
            ],
          ),
        ),
      ));
    }
    return tiles;
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getActiveOrders();
  }


  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child:  (isOrdersLoaded) ? (activeOrders.isNotEmpty) ? Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text("  Acitve Orders", style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),)
          ] + generateOrderTiles(),
        ),
      ) : Column(
        children: [
          Icon(Icons.receipt_long_outlined, size: 50, color: Colors.grey[500],),
          Text("\nYou have no active orders")
        ],
      ) :CircularProgressIndicator(),
    );
  }
}
