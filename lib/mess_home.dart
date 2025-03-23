import 'package:flutter/material.dart';
import 'package:tiffn/mess_details.dart';
import 'package:tiffn/mess_orders.dart';


class MessHome extends StatefulWidget {

  final Map<String, dynamic> mess;
  const MessHome(this.mess, {super.key});

  @override
  State<MessHome> createState() => _MessHomeState();
}

class _MessHomeState extends State<MessHome> {

  int _currentIndex = 0;

  // List of pages for each tab
  List<Widget>? _pages;

  @override
  void initState() {
    // TODO: implement initState
    /*
    _pages = [
      Center(child: MessOrdersPage()),
      Center(child: MessDetailsPage(mess: widget.mess, editable: true,)),
    ];
    */

    super.initState();

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
      Center(child: MessOrdersPage(mess: widget.mess)),
      Center(child: MessDetailsPage(mess: widget.mess, editable: true,)),
    ];


    return Scaffold(
      appBar: AppBar(
        title: Text('tiffn', style: TextStyle(fontWeight: FontWeight.bold),),
        centerTitle: true,
        leading: SizedBox(),
      ),

      body: _pages![_currentIndex], // Display the selected page
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex, // Highlight the selected tab
        onTap: _onTabTapped, // Handle tab tap
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt_outlined),
            label: 'Orders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant),
            label: 'Mess',
          ),
        ],
        selectedItemColor: Colors.green, // Selected tab color
        unselectedItemColor: Colors.grey, // Unselected tab color
        showUnselectedLabels: true, // Display labels for all tabs
      ),
    );
  }
}
