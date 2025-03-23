
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:tiffn/global.dart';
import 'package:tiffn/mess_details.dart';
import 'package:carousel_slider/carousel_slider.dart';

class MessSearch extends StatefulWidget {
  const MessSearch({super.key});

  @override
  _MessSearchState createState() => _MessSearchState();
}

class _MessSearchState extends State<MessSearch> {

  String searchQuery = "";
  List<Map<String, dynamic>> nearby_mess = [];
  bool isLoaded = false;
  List<dynamic> adUrls = [];

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> loadMessDocuments() async {

      QuerySnapshot querySnapshot = await _firestore.collection('mess').get();

      List<Map<String, dynamic>> messList = [];
      for (var doc in querySnapshot.docs) {
        if (isNear(doc['location']['coordinates'][0], doc['location']['coordinates'][1])) {
          messList.add(doc.data() as Map<String, dynamic>);
          messList.last['id'] = doc.id;
        }
      }

      // Load imageUrls for Ad Space
      DocumentSnapshot adURLs = await _firestore.collection('adSpace').doc('ads').get();
      adUrls = adURLs.get('images');

      setState(() {
        nearby_mess = messList;
        isLoaded = true;
      });

  }


  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    loadMessDocuments();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: (isLoaded) ? (nearby_mess.isNotEmpty) ? Column(
          children: [
            // Search bar
            TextField(
              onChanged: (value) {
                setState(() {
                  searchQuery = value.toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: 'Search mess near you',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[200],
              ),
            ),
            SizedBox(height: 20),
            // Mess cards
            Expanded(
              child: ListView(
                children: [searchQuery.isEmpty? Container(
                  height: 180,
                  width: MediaQuery.of(context).size.width,
                  color: Colors.grey[300],
                  child: (adUrls.isEmpty) ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.emoji_food_beverage, color: Colors.white, size: 50,),
                        Text('Ad Space', style: TextStyle(color: Colors.white, fontSize: 12),)
                      ],
                    ),
                  ) : CarouselSlider(
                    options: CarouselOptions(
                        height: 180.0,
                      autoPlay: true,
                      autoPlayInterval: Duration(seconds: 5)
                    ),
                    items: adUrls.map((i) {
                      return Builder(
                        builder: (BuildContext context) {
                          return Container(
                              margin: EdgeInsets.symmetric(horizontal: 3.0),
                              child: Image.network(i, fit: BoxFit.cover,)
                          );
                        },
                      );
                    }).toList(),
                  ),
                ) : SizedBox(),
                  SizedBox(height: searchQuery.isEmpty? 20: 0),]

                    + nearby_mess
                    .where((mess) => mess["name"]!.toLowerCase().contains(searchQuery))
                    .where((mess) => mess['verified']! == true)
                    .map((mess) => MessCard(mess: mess))
                    .toList(),
              ),
            ),
          ],
        ) : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.no_food_rounded, size: 100, color: Colors.green[100],),
            Text('\nSorry,', style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 24,
              color: Colors.grey[800]
            ),),
            Text("We couldn't find any mess found near you.\nTry changing your address", style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600]
            ),
              textAlign: TextAlign.center,
            )
          ],
        ) :CircularProgressIndicator(),
      );
  }
}

class MessCard extends StatelessWidget {
  final Map<String, dynamic> mess;

  const MessCard({super.key, required this.mess});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MessDetailsPage(mess: mess),
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 10),
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 2,
          child: Container(
            margin: EdgeInsets.only(bottom: 5),
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mess['name'],
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 5),
                    Text(mess['location']['address'], style: TextStyle(fontSize: 16)),
                    //display rating based on mess['avgRating'] out of 5 stars

                    buildStarRating(mess['avgRating'].toDouble(), mess['totalRatings']),


                  ],
                ),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(Icons.crop_square_sharp, color: mess['veg']? Colors.green: Colors.red, size: 18,),
                    Icon(Icons.circle, color: mess['veg']? Colors.green: Colors.red, size: 7),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}