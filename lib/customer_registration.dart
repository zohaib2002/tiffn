import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:latlong2/latlong.dart';
import 'package:tiffn/customer_home.dart';
import 'package:tiffn/global.dart';

import 'mapPicker.dart';

class AddressDetails extends StatefulWidget {
  final List<dynamic> _addresses;
  final Function updateAddresses;

  const AddressDetails(this._addresses, this.updateAddresses,{super.key});

  @override
  State<AddressDetails> createState() => _AddressDetailsState();
}

class _AddressDetailsState extends State<AddressDetails> {
  final TextEditingController addressController = TextEditingController();
  final TextEditingController addressNameController = TextEditingController();
  LatLng? selectedLocation;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(child: Text('Address Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),)),
        SizedBox(height: 30,),
        Text('  Address Name'),
        TextField(
          controller: addressNameController,
          decoration: InputDecoration(
            hintText: 'Home / Work',
            border: OutlineInputBorder(),
          ),
        ),
        SizedBox(height: 10,),
        Text('  Full Street Address'),
        TextField(
          controller: addressController,
          decoration: InputDecoration(
            hintText: 'Flat/Home/Apartment, Street, Area',
            border: OutlineInputBorder(),
          ),
        ),
        SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            (selectedLocation != null)? Row(
              children: [
                Icon(Icons.location_pin),
                Text('Location picked  '),
              ],
            ) : SizedBox(),
            ElevatedButton(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MapPickerPage(),
                  ),
                );

                if (result != null) {
                  setState(() {
                    selectedLocation = result;
                  });
                }
              },
              child: Text('Pick on Map'),
            ),
          ],
        ),
        SizedBox(height: 10),
        ElevatedButton(
          onPressed: () {
            if (addressController.text.isNotEmpty && selectedLocation != null && addressNameController.text.isNotEmpty) {
              widget._addresses.add({
                'name': addressNameController.text,
                'text': addressController.text,
                'latitude': selectedLocation!.latitude,
                'longitude': selectedLocation!.longitude,
              });
              widget.updateAddresses();
              Navigator.pop(context);
            }
          },
          child: Text('Save Address'),
        ),
      ],
    );
  }
}


class CustomerRegistration extends StatefulWidget {
  final Map<String, dynamic> userData;

  const CustomerRegistration({super.key, this.userData = const {}});

  @override
  _CustomerRegistrationState createState() => _CustomerRegistrationState();
}

class _CustomerRegistrationState extends State<CustomerRegistration> {
  final TextEditingController _nameController = TextEditingController();
  final List<dynamic> _addresses = [];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  void updateAddresses() {
    setState(() {
      // blank set state to update address list
    });
  }

  void loadDataToFields() {
    _nameController.text = widget.userData['fullName'] ?? '';
    _addresses.addAll(widget.userData['addresses'] ?? []);
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    loadDataToFields();
  }

  void _showAddAddressBottomSheet() {

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 30,
          top: 20,
          left: 20,
          right: 20,
        ),
        child: AddressDetails(_addresses, updateAddresses)
      ),
    );
  }

  Future<void> _saveUserDetails() async {
    if (_nameController.text.isEmpty || _addresses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill all details')),
      );
      return;
    }

    try {
      User? user = _auth.currentUser;

      if (user != null) {
        // can modify original widget.userData according to changes / data in the fields
        widget.userData['fullName'] = _nameController.text;
        widget.userData['phoneNumber'] = user.phoneNumber;
        widget.userData['addresses'] = _addresses;
        widget.userData['subscriptions'] = widget.userData['subscriptions'] ?? [];
        widget.userData['recentOrders'] = widget.userData['recentOrders'] ?? [];
        widget.userData['createdAt'] = FieldValue.serverTimestamp();

        /*
        Map<String, dynamic> userData = {
          'fullName': _nameController.text,
          'phoneNumber': user.phoneNumber,
          'addresses': _addresses,
          'subscriptions': widget.userData['subscriptions'] ?? [],
          'recentOrders' : widget.userData['recentOrders'] ?? [],
          'createdAt': FieldValue.serverTimestamp(),
        };
        */

        await _firestore.collection('customers').doc(user.uid).set(widget.userData, SetOptions(merge: true));

        // set selected Address
        selectedAddress = _addresses[0];
        selectedAddressIndex = 0;


        // Navigate to next screen or home
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => CustomerHomePage(userData: widget.userData,)),
            (route) => false
        );


        //No need to do mastersetstate, since we are virtually restarting the app...
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving details: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('tiffn', style: TextStyle(fontWeight: FontWeight.bold),), centerTitle: true,),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Customer Registration\n',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
            ),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Full Name',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 30),
            Text('Your Addresses', style: TextStyle(fontSize: 16,)),
            Divider(),
            Expanded(
              child: ListView.builder(
                itemCount: _addresses.length + 1,
                itemBuilder: (context, index) {
                  if (index == _addresses.length) {
                    return ElevatedButton(
                      onPressed: _showAddAddressBottomSheet,
                      child: Text('Add Address'),
                    );
                  }
                  return ListTile(
                    title: Text(_addresses[index]['name']),
                    subtitle: Text(
                      _addresses[index]['text'],
                    ),
                    trailing: IconButton(
                      icon: Icon(Icons.delete),
                      onPressed: () {
                        setState(() {
                          _addresses.removeAt(index);
                        });
                      },
                    ),
                  );
                },
              ),
            ),
            Row(
              children: [
                Expanded(child: SizedBox()),
                ElevatedButton(
                  onPressed: _saveUserDetails,
                  child: Text('Save Details'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

