import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:imgbb_uploader/imgbb.dart';
import 'package:latlong2/latlong.dart';
import 'package:tiffn/global.dart';
import 'package:tiffn/login_page.dart';
import 'package:tiffn/menu_editor.dart';
import 'package:tiffn/mess_home.dart';

import 'mapPicker.dart';


// use imgbb uploader for fssai certificates

class MessRegistration extends StatefulWidget {

  // not final
  Map<String,dynamic> mess;
  MessRegistration( {super.key, this.mess = const {
    'menu': {}
  }});

  @override
  _MessRegistrationState createState() => _MessRegistrationState();
}

class _MessRegistrationState extends State<MessRegistration> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  bool _isPureVeg = false;
  File? _fssaiCertificateFile;
  String? _fssaiCertificateUrl;
  LatLng? _selectedLocation;
  Map? menu = {}; //widget.mess['menu'];

  TimeOfDay? _breakfastStart = TimeOfDay(hour: 7, minute: 0);
  TimeOfDay? _breakfastEnd = TimeOfDay(hour: 12, minute: 0);
  TimeOfDay? _lunchStart = TimeOfDay(hour: 12, minute: 01);
  TimeOfDay? _lunchEnd  = TimeOfDay(hour: 18, minute: 0);
  TimeOfDay? _dinnerStart  = TimeOfDay(hour: 18, minute: 01);
  TimeOfDay? _dinnerEnd = TimeOfDay(hour: 21, minute: 0);

  @override
  void initState() {
    super.initState();

    // take all values form widget.mess so that the form is already populated
    if (widget.mess['name'] != null && widget.mess['description'] != null && widget.mess['location'] != null) {
      _nameController.text = widget.mess['name'] ?? '';
      _descriptionController.text = widget.mess['description'] ?? '';
      _addressController.text = widget.mess['location']?['address'] ?? '';
      _isPureVeg = widget.mess['veg'] ?? false;
      _fssaiCertificateUrl = widget.mess['fssaiCertificateUrl'] ?? '';
      _selectedLocation = LatLng(widget.mess['location']['coordinates'][0], widget.mess['location']['coordinates'][1]);
      menu = widget.mess['menu'];

      _breakfastStart = TimeOfDay(hour: widget.mess['timings']['breakfast'][0]~/100, minute: widget.mess['timings']['breakfast'][0]%100);
      _breakfastEnd = TimeOfDay(hour: widget.mess['timings']['breakfast'][1]~/100, minute: widget.mess['timings']['breakfast'][1]%100);
      _lunchStart = TimeOfDay(hour: widget.mess['timings']['lunch'][0]~/100, minute: widget.mess['timings']['lunch'][0]%100);
      _lunchEnd = TimeOfDay(hour: widget.mess['timings']['lunch'][1]~/100, minute: widget.mess['timings']['lunch'][1]%100);
      _dinnerStart = TimeOfDay(hour: widget.mess['timings']['dinner'][0]~/100, minute: widget.mess['timings']['dinner'][0]%100);
      _dinnerEnd = TimeOfDay(hour: widget.mess['timings']['dinner'][1]~/100, minute: widget.mess['timings']['dinner'][1]%100);
    }
  }


  Future<void> _pickLocation() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => MapPickerPage()),
    );

    if (result != null) {
      setState(() {
        _selectedLocation = result;
      });
    }
  }

  Future<void> _pickFSSAICertificate() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 800,
    );

    if (pickedFile != null) {
      setState(() {
        _fssaiCertificateFile = File(pickedFile.path);
      });
    }
  }

  bool isUploading = false;

  Future<void> _uploadFSSAICertificate() async {

    setState(() {
      isUploading = true;
    });

    if (_fssaiCertificateFile == null) return;

    try {
      var value = await ImgbbUploader(imgBBkey).uploadImageFile(
        imageFile: _fssaiCertificateFile!,
        //name: 'certificate',
        //expiration: 600
      );

      if (value!.status!= 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: ${value.status}')),
        );
      } else {
        _fssaiCertificateUrl = value.data?.image?.url;
      }

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: $e')),
      );
    }
  }

  Future<void> _submitRegistration() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please pick a location on the map')),
      );
      return;
    }
    else if (menu!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please create a menu')),
      );
      return;
    }

    await _uploadFSSAICertificate();

    if (_fssaiCertificateUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please upload FSSAI certificate')),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User Signed Out')),
      );
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
            (route) => false,
      );
      return;
    }

    List<dynamic> existingSubscribers = widget.mess['subscribers'] ?? [];
    int totalRatings = widget.mess['totalRatings'] ?? 0;
    double avgRating = widget.mess['avgRating'] ?? 0.0;

    // could have changed individual fields but this seems more readable
    widget.mess = {
      'phoneNumber' : user.phoneNumber,
      'name': _nameController.text,
      'description': _descriptionController.text,
      'location': {
        'address': _addressController.text,
        'coordinates': [
          _selectedLocation!.latitude,
          _selectedLocation!.longitude
        ]
      },
      'veg': _isPureVeg,
      'timings': {
        'breakfast': [
          _breakfastStart!.hour * 100 + _breakfastStart!.minute,
          _breakfastEnd!.hour * 100 + _breakfastEnd!.minute
        ],
        'lunch': [
          _lunchStart!.hour * 100 + _lunchStart!.minute,
          _lunchEnd!.hour * 100 + _lunchEnd!.minute
        ],
        'dinner': [
          _dinnerStart!.hour * 100 + _dinnerStart!.minute,
          _dinnerEnd!.hour * 100 + _dinnerEnd!.minute
        ]
      },
      'fssaiCertificateUrl': _fssaiCertificateUrl,
      'verified': false,
      'menu' : menu,
      'subscribers' : existingSubscribers,
      'totalRatings' : totalRatings,
      'avgRating' : avgRating,
    };

    try {
      await FirebaseFirestore.instance.collection('mess').doc(user.uid).set(widget.mess);

     // Navigator.pop(context);
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => MessHome(widget.mess)),
          (route) => false
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Registration failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('tiffn', style: TextStyle(fontWeight: FontWeight.bold),), centerTitle: true,),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(16),
          children: [
            Text(' Mess Registration\n',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),

            ),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Mess Name'),
              validator: (value) =>
              value!.isEmpty ? 'Please enter mess name' : null,
            ),
            SizedBox(height: 10),
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(labelText: 'Description'),
              maxLines: 2,
              validator: (value) =>
              value!.isEmpty ? 'Please enter description' : null,
            ),
            SizedBox(height: 10),
            TextFormField(
              controller: _addressController,
              decoration: InputDecoration(labelText: 'Full Address'),
              validator: (value) =>
              value!.isEmpty ? 'Please enter address' : null,
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                (_selectedLocation != null) ? Row(
                  children: [
                    Icon((Icons.location_pin)),
                    Text('Location picked')
                  ],
                ) : SizedBox(),
                ElevatedButton(
                  onPressed: () {
                    _pickLocation();
                  },
                  child: Text('Pick on Map'),
                )
              ],
            ),
            SizedBox(height: 10,),
            CheckboxListTile(
              title: Text('Pure Veg', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),),
              value: _isPureVeg,
              onChanged: (bool? value) {
                setState(() {
                  _isPureVeg = value ?? false;
                });
              },
            ),
            Text('\n Adjust Meal Timings',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),

            ),
            // Timing pickers for breakfast, lunch, dinner
            TimePickerWidget('Breakfast',
                    (start) => _breakfastStart = start,
                    (end) => _breakfastEnd = end
            ),
            TimePickerWidget('Lunch',
                    (start) => _lunchStart = start,
                    (end) => _lunchEnd = end
            ),
            TimePickerWidget('Dinner',
                    (start) => _dinnerStart = start,
                    (end) => _dinnerEnd = end
            ),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: _pickFSSAICertificate,
              child: Text('Upload FSSAI Certificate'),
            ),
            if (_fssaiCertificateFile != null)
              Image.file(_fssaiCertificateFile!, height: 100),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                // Placeholder for menu editing
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => MenuEditor(menu!)),
                );
              },
              child: Text('Edit Menu'),
            ),
            SizedBox(height: 30),
            Center(child: Text(
              'Registering / changing mess details is subject to verification. The listing will be hidden during the verification period which may take upto 2 hours.',
              style: TextStyle(fontSize: 12, color: Colors.grey[600],),
              textAlign: TextAlign.center,
            ),),
            SizedBox(height: 20),
            ElevatedButton(

              onPressed: (isUploading)? (){} : _submitRegistration,
              style: ButtonStyle(
                // make color grey if uploading else same color
                  backgroundColor: WidgetStateProperty.resolveWith<Color?>(
                        (states) => isUploading ? Colors.grey[500] : Theme.of(context).colorScheme.primary,
                  ),
                  shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                      RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5.0),
                      )
                  )
              ),
              child: isUploading? Center(child: SizedBox(
                //padding: const EdgeInsets.all(2.0),
                height: 25,
                width: 25,
                child: CircularProgressIndicator(),
              ),) : Text('Register Mess'),
            ),
          ],
        ),
      ),
    );
  }
}


class TimePickerWidget extends StatefulWidget {

  final String meal;
  final Function(TimeOfDay) onStartSelected;
  final Function(TimeOfDay) onEndSelected;

  const TimePickerWidget(this.meal, this.onStartSelected, this.onEndSelected, {super.key});

  @override
  State<TimePickerWidget> createState() => _TimePickerWidgetState();
}

class _TimePickerWidgetState extends State<TimePickerWidget> {

  TimeOfDay? startTime;
  TimeOfDay? endTime;

  @override
  void initState() {
    // TODO: implement initState
    if (widget.meal == 'Breakfast') {
      startTime = TimeOfDay(hour: 7, minute: 0);
      endTime = TimeOfDay(hour: 12, minute: 0);
    }
    else if (widget.meal == 'Lunch') {
      startTime = TimeOfDay(hour: 12, minute: 01);
      endTime = TimeOfDay(hour: 18, minute: 0);
    }
    else {
      startTime = TimeOfDay(hour: 18, minute: 01);
      endTime = TimeOfDay(hour: 21, minute: 0);
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, right: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SizedBox(width: 80,child: Text(widget.meal),),
          TextButton(
            onPressed: () async {
              startTime = await showTimePicker(
                  context: context,
                  initialTime: startTime!
              );
              if (startTime != null) {
                setState(() {
                  widget.onStartSelected(startTime!);
                });
              }
            },
            child: Text(_formatTime(startTime)),
          ),
          Text('to'),
          TextButton(
            onPressed: () async {
              endTime = await showTimePicker(
                  context: context,
                  initialTime: endTime!
              );
              if (endTime != null) {
                setState(() {
                  widget.onEndSelected(endTime!);
                });
              }
            },
            child: Text(_formatTime(endTime)),
          ),
        ],
      ),
    );
  }
}


String _formatTime(TimeOfDay? time) {
  return time != null
      ? '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}'
      : 'Select Time';
}


