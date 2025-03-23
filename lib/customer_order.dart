import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:tiffn/global.dart';
import 'package:ntp/ntp.dart';



class CustomerOrderPage extends StatefulWidget {

  final Map<String, dynamic> userData;

  const CustomerOrderPage({required this.userData, super.key});

  @override
  State<CustomerOrderPage> createState() => _CustomerOrderPageState();
}

class _CustomerOrderPageState extends State<CustomerOrderPage> {

  bool isLoaded = false;
  List<Map<String, dynamic>> meals = [];
  int weekday = 1;



  Future<void> loadMeals() async {

    try {
      DateTime currentNTPTime = await NTP.now();

      meals =[];
      weekday = currentNTPTime.weekday;

      List<dynamic> existingOrders = await fetchExistingActiveOrders();

      //get current day in 3 letters (eg Sun, Mon, Tue, etc) (Sunday should be saved as Sun)
      String currentDay = dayMap.keys.toList()[weekday - 1];

      // get all subscriptions
      for (int i=0; i<widget.userData['subscriptions'].length; i++) {

        // get the mess detials
        DocumentSnapshot messDoc = await FirebaseFirestore.instance.collection('mess').doc(widget.userData['subscriptions'][i]['messID']).get();
        Map <String, dynamic> subbedMess = messDoc.data() as Map<String, dynamic>;

        if (isNear(subbedMess['location']['coordinates'][0], subbedMess['location']['coordinates'][1])) {
          // get all meals for each subscription
          for (int j = 0; j < widget.userData['subscriptions'][i]['meals'].length; j++) {
            // check if current day is in the meals
            if (widget.userData['subscriptions'][i]['meals'][j]['day'] == currentDay) {
              //see what meal is active for that day in that mess
              // get the current time in 4 digit format(eg 1:31pm is 1331)
              int currentTime = currentNTPTime.hour * 100 + currentNTPTime.minute;
              // check if the current time is between the start and end time of the meal

              Map<String, dynamic> meal = {
                'messName': subbedMess['name'],
                'address': subbedMess['location']['address'],
                'messID': widget.userData['subscriptions'][i]['messID'],
                'day': currentDay,
                'startTime': subbedMess['timings'][widget
                    .userData['subscriptions'][i]['meals'][j]['meal']
                    .toLowerCase()][0],
                'endTime': subbedMess['timings'][widget
                    .userData['subscriptions'][i]['meals'][j]['meal']
                    .toLowerCase()][1],
                'hasActiveOrder': false
              };

              //check if subscribed to a certain meal

              List<String> mealTypes = ['Breakfast', 'Lunch', 'Dinner'];

              for (String mealType in mealTypes) {
                if (widget.userData['subscriptions'][i]['meals'][j]['meal'] ==  mealType) {
                  // check if mess is in the meal time
                  if (currentTime >= subbedMess['timings'][mealType.toLowerCase()][0] &&
                      currentTime < subbedMess['timings'][mealType.toLowerCase()][1]) {
                    meal['meal'] = mealType;
                    meal['items'] =
                    subbedMess['menu'][currentDay][mealType]['items'];

                    //check if order is active:

                    List<dynamic> recentOrders = widget.userData['recentOrders'] ?? [];


                    for (int k = 0; k < existingOrders.length; k++) {
                      if (existingOrders[k]['messID'] == widget.userData['subscriptions'][i]['messID'] &&
                          existingOrders[k]['status'] <= 3
                          && existingOrders[k]['day'] == currentDay
                          && existingOrders[k]['meal'] == mealType) {
                        meal['hasActiveOrder'] = true;
                        break;
                      }
                    }

                    // ? /////////////////////////////////////////////////////////
                    // The meal is already an existing order, so we continue (skip further checks)
                    if (meal['hasActiveOrder']) {
                      meals.add(meal);
                      continue;
                    }


                    // further checks required to avoid user from ordering same meal again and again...
                    // the meal may not be an existing order but a recent order. so it should also be disabled


                    for (Map<String, dynamic> order in recentOrders) {
                      // check if order day and meal same as meal day and meal
                      if (order['day'] == meal['day'] &&
                          order['meal'] == meal['meal'] &&
                          order['messID'] == meal['messID']) {
                        // then find the time elaspsed since order
                        DateTime orderTime = order['createdAt'].toDate();
                        Duration timeElapsed = currentNTPTime.difference(orderTime);

                        // find duration between order time hour and minute and meal endTime hour and minute
                        int mealHour = meal['endTime'] ~/ 100;
                        int mealMinute = meal['endTime'] % 100;

                        // create meal end time object by appending meal hour and meal minute to current time day
                        DateTime mealEndTime = DateTime(
                            orderTime.year, orderTime.month, orderTime.day,
                            mealHour, mealMinute);

                        Duration duration = mealEndTime.difference(orderTime);

                        // if time elapsed is less than duration, then order is active
                        if (timeElapsed.inMinutes < duration.inMinutes) {
                          meal['hasActiveOrder'] = true;
                          break;
                        }
                      }
                    }


                    meals.add(meal);
                  }
                }
              }
            }
          }
        }

      }
    }

    catch(e) {
      print("Error in loadMeals: $e");
    }
    finally {
      if (mounted) {
        setState(() {
          isLoaded = true;
        });
      }
    }

  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    loadMeals();
  }


  @override
  Widget build(BuildContext context) {

    List<Widget> mealDetailsWidgets = [];

    for (int i=0; i<meals.length; i++) {
      mealDetailsWidgets.add(MealDetails(meal: meals[i], userData: widget.userData, reloadOrders: () {
        setState(() {
          isLoaded = false;
        });
        loadMeals();
      }
      ));
    }

    return  SingleChildScrollView(
      child: (isLoaded) ? (meals.isNotEmpty) ? Column(
        // view all meal detials
        children: <Widget> [Text(dayMap.values.toList()[weekday - 1] + ' - Meals', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),)] + mealDetailsWidgets,

      ) : Column(
        children: [
          Icon(
            (widget.userData['subscriptions'].length == 0) ?
            Icons.fastfood_outlined : Icons.access_time,
            size: 50, color: Colors.grey[500],),
          Text(
            (widget.userData['subscriptions'].length == 0) ? "\nYou have not subscribed to any mess.\n" :
            '\nNo mess you have subscribed to is\nactive at this moment.\n',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14),),
        ],
      )

          : Column(
            children: [
              CircularProgressIndicator(),
              Text("\nFinding available meals")
            ],
          ),
    ) ;
  }
}


class MealDetails extends StatefulWidget {

  final Map<String, dynamic> meal;
  final Map<String, dynamic> userData;
  final Function reloadOrders;

  const MealDetails({required this.meal, required this.userData, required this.reloadOrders, super.key});

  @override
  State<MealDetails> createState() => _MealDetailsState();
}

class _MealDetailsState extends State<MealDetails> {

  List<bool> checked = [];
  List<int> selectedIndexes = []; // Stores checked item indexes

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (checked.isEmpty) {  // Ensure it initializes only once
      checked = List.filled(widget.meal['items'].length, false);
    }
  }

  @override
  Widget build(BuildContext context) {

    List<Widget> itemList = [];
    for (int i = 0; i < widget.meal['items'].length; i++) {
      itemList.add(
        CheckboxListTile(
          dense: true,
          enabled: !widget.meal['hasActiveOrder'],
          title: Text(widget.meal['items'][i], style: TextStyle(fontSize: 16),),
          value: checked[i],
          onChanged: (bool? value) {
            setState(() {
              if (value == true) {
                if (selectedIndexes.length >= 2) {
                  // Uncheck the oldest selected checkbox
                  checked[selectedIndexes[0]] = false;
                  selectedIndexes.removeAt(0);

                  //display SnackBar
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('You can only order 2 items from a mess')),
                  );

                }
                // Check new box and store index
                checked[i] = true;
                selectedIndexes.add(i);
              } else {
                // Uncheck box and remove index
                checked[i] = false;
                selectedIndexes.remove(i);
              }
            });
          },
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(16),
      margin: EdgeInsets.all(16),
      width: MediaQuery.of(context).size.width - 32,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all()
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.meal['messName'], style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),),
          Text(widget.meal['address']),
          SizedBox(height: 10,),
          Text(widget.meal['meal'], style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),),
          // display all items in the meal
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: itemList,
          ),

          SizedBox(height: 10,),

          ( selectedIndexes.isNotEmpty) ? Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () async {
                  //show alert dialogue box
                  bool? result = await showDialog<bool>(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text("Place Order"),
                        content: Text("Confirm place order?"),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop(true);
                            },
                            child: Text("Yes"),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop(false);
                            },
                            child: Text("No"),
                          ),
                        ],
                      );

                    },
                  );

                  if (result == true) {
                    //place order everywhere. do a master set state...
                    // get the list of selected items
                    List<String> selectedItems = [];
                    for (int i=0; i<selectedIndexes.length; i++) {
                      selectedItems.add(widget.meal['items'][selectedIndexes[i]]);
                    }

                    Map<String, dynamic> order = {
                      'messID': widget.meal['messID'],
                      'messName' : widget.meal['messName'],
                      'day': widget.meal['day'],
                      'meal': widget.meal['meal'],
                      'items': selectedItems,
                      'status' : 0,
                      'createdAt': await NTP.now(),
                    };

                    // add this to the activeUserOrders collection in firebase with doc id as userID
                    String userId = FirebaseAuth.instance.currentUser!.uid;

                    List<dynamic> existingOrders = await fetchExistingActiveOrders();

                    existingOrders.add(order);

                    await FirebaseFirestore.instance.collection('activeUserOrders').doc(userId).set({
                      'activeOrders': existingOrders,
                    }, SetOptions(merge: true));

                    // preventing user from ordering same meal again
                    // add messID and next meal start time to recentOrders field
                    DocumentReference userRef = FirebaseFirestore.instance.collection('customers').doc(userId);

                    widget.userData['recentOrders'] ??= [];
                    List<dynamic> recentOrders = widget.userData['recentOrders'];

                    if (recentOrders.length >= 3) {
                      recentOrders.removeAt(0);
                    }

                    recentOrders.add(order); // implicitly updates widget.userData

                    await userRef.update({
                      'recentOrders': recentOrders,
                    });


                    masterSetState!(userData: widget.userData);
                    // reload Order Screen
                    // alternatively can put loadMeals() in dependecieschange()...
                    widget.reloadOrders();


                  }
                },
                child: Text('Place Order'),
              ),
            ],
          ) : SizedBox(),

          (widget.meal['hasActiveOrder']) ? Text("You already ordered this meal today") : SizedBox()
        ]
      ),
    );
  }
}
