import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;

Map selectedAddress = {};
int selectedAddressIndex = 0;
// this has to be loaded during sign in from firestore and shared prefs

class CartItem {
  String day;
  String meal;
  double price;

  CartItem({required this.day, required this.meal, required this.price});
}

class Cart {

  List<CartItem> items = [];


  List<dynamic> toList() {
    List<dynamic> mealList = [];
    for (CartItem item in items) {
      // nested lists are not allowed in firestore
      mealList.add({
        'day': item.day,
        'meal': item.meal,
      });
    }
    return mealList;
  }

  String toText() {
// Initialize an empty map to store items grouped by day and time

    String text = '';
    for (CartItem item in items) {
      text += '${item.day} - ${item.meal} : ₹${item.price}\n';
    }
    // Combine all the day summaries into one long string
    return text;
  }

  void empty() {
    items = [];
  }

  void add(CartItem item) {
    items.add(item);
  }

  void remove(CartItem item) {
    bool found = false;
    int index = 0;
    for (int i=0; i<items.length; i++) {
      if (items[i].day == item.day && items[i].meal == item.meal && items[i].price == item.price) {
        found = true;
        index = i;
        break;
      }
    }

    if (found) {
      items.removeAt(index);
    }
  }

  bool contains(CartItem item) {
    for (CartItem i in items) {
      if (i.day == item.day && i.meal == item.meal && i.price == item.price) {
        return true;
      }
    }
    return false;
  }

  double total() {
    double sum = 0;
    for (CartItem item in items) {
      sum += item.price;
    }
    return sum;
  }

}

Map<String, String> dayMap = {
  'Mon': 'Monday',
  'Tue': 'Tuesday',
  'Wed': 'Wednesday',
  'Thu': 'Thursday',
  'Fri': 'Friday',
  'Sat': 'Saturday',
  'Sun': 'Sunday',
};

// wierd work around (but it works)
Function? masterSetState;

class LocationUtils {
  static double calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    // Radius of the Earth in kilometers
    const double earthRadius = 6371.0;

    // Convert latitude and longitude from degrees to radians
    double lat1Rad = _degreesToRadians(lat1);
    double lon1Rad = _degreesToRadians(lon1);
    double lat2Rad = _degreesToRadians(lat2);
    double lon2Rad = _degreesToRadians(lon2);

    // Differences in coordinates
    double dLat = lat2Rad - lat1Rad;
    double dLon = lon2Rad - lon1Rad;

    // Haversine formula
    double a = math.pow(math.sin(dLat / 2), 2) +
        math.cos(lat1Rad) *
            math.cos(lat2Rad) *
            math.pow(math.sin(dLon / 2), 2);
    double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    // Calculate the distance
    double distance = earthRadius * c;

    return distance; // Distance in kilometers
  }

  // Helper function to convert degrees to radians
  static double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180.0);
  }
}

int thresholdRadius = 50; // distance in KM (set it to 10)

bool isNear(double lat1, double lon1) {
  print(LocationUtils.calculateDistance(lat1, lon1, selectedAddress['latitude'], selectedAddress['longitude']));
  if (LocationUtils.calculateDistance(lat1, lon1, selectedAddress['latitude'], selectedAddress['longitude']) < thresholdRadius) {
    return true;
  }
  return false;
}

Future<List<dynamic>> fetchExistingActiveOrders() async {
  FirebaseAuth auth = FirebaseAuth.instance;
  User? user = auth.currentUser;
  String userId = user!.uid;

  List<dynamic> existingOrders = [];

  DocumentSnapshot orderSnap = await FirebaseFirestore.instance.collection('activeUserOrders').doc(userId).get();
  if (orderSnap.exists) {
    Map<String, dynamic> orderData = orderSnap.data() as Map<String, dynamic>;
    if (orderData.isNotEmpty) {
      existingOrders = orderData['activeOrders'] as List<dynamic>? ?? [];
    }
  }

  return existingOrders;
}

Widget buildStarRating(double avgRating, int totalRatings) {
  int fullStars = avgRating.floor(); // Number of full stars
  bool hasHalfStar = (avgRating - fullStars) >= 0.5; // Check if half star is needed
  int emptyStars = 5 - fullStars - (hasHalfStar ? 1 : 0); // Remaining empty stars

  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      // Full stars
      for (int i = 0; i < fullStars; i++)
        Icon(Icons.star, color: Colors.amber, size: 24),

      // Half star if applicable
      if (hasHalfStar) Icon(Icons.star_half, color: Colors.amber, size: 24),

      // Empty stars
      for (int i = 0; i < emptyStars; i++)
        Icon(Icons.star_border, color: Colors.amber, size: 24),

      // Rating count in brackets
      SizedBox(width: 5),
      Text("${avgRating.toStringAsFixed(1)}  ($totalRatings)", style: TextStyle(fontSize: 14, color: Colors.grey[600])),
    ],
  );
}

// ImgBB used for image hosting
String imgBBkey = "";
String razorpay_keyId = "";
String razorpay_keySecret = "";