import 'package:flutter/material.dart';
import 'package:tiffn/customer_order.dart';
import 'package:tiffn/customer_profile.dart';
import 'package:tiffn/global.dart';
import 'package:tiffn/mess_search.dart';


class CustomerHomePage extends StatefulWidget {

  Map<String, dynamic> userData;
  CustomerHomePage({required this.userData, super.key});

  @override
  _CustomerHomePageState createState() => _CustomerHomePageState();
}

class _CustomerHomePageState extends State<CustomerHomePage> {
  int _currentIndex = 1; //CustomerOrderScreen is defualt.
  List<Widget> _pages = [];


  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    // not keeping user as global as even mess owner can use the app...
    masterSetState = ({required Map<String, dynamic> userData}) {setState(() {
      widget.userData = userData;
    });};
  }

  // Update the index on tab tap
  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    _pages = [
      Center(child: MessSearch()),
      Center(child: CustomerOrderPage(userData: widget.userData),),
      Center(child: CustomerProfile(userData: widget.userData)),
    ];


    return Scaffold(
      appBar: AppBar(
        title: Text('tiffn', style: TextStyle(fontWeight: FontWeight.bold,),),
        centerTitle: true,
        leading: SizedBox(),
      ),
      body: _pages[_currentIndex], // Display the selected page
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex, // Highlight the selected tab
        onTap: _onTabTapped, // Handle tab tap
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.dining_outlined),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.sticky_note_2_outlined),
            label: 'Order',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'You',
          ),
        ],
        selectedItemColor: Colors.green, // Selected tab color
        unselectedItemColor: Colors.grey, // Unselected tab color
        showUnselectedLabels: true, // Display labels for all tabs
      ),
    );
  }
}
