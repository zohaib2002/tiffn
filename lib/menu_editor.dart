import 'package:flutter/material.dart';

class MenuEditor extends StatefulWidget {

  final Map menu;

  const MenuEditor(this.menu, {super.key});

  @override
  State<MenuEditor> createState() => _MenuEditorState();
}

class _MenuEditorState extends State<MenuEditor> {
  final List<String> days = [
    'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'
  ];
  final List<String> mealTypes = ['Breakfast', 'Lunch', 'Dinner'];


  // Controllers
  final _mealPriceController = TextEditingController();
  final _menuItemController = TextEditingController();

  String selectedDay = 'Sunday';
  String selectedMeal = 'Breakfast';

  void addMealType() {
    if (_mealPriceController.text.isEmpty) return;

    setState(() {
      widget.menu.putIfAbsent(selectedDay.substring(0, 3), () => {});
      widget.menu[selectedDay.substring(0, 3)]![selectedMeal] = {'price' : double.parse(_mealPriceController.text), 'items' : []};
      _mealPriceController.clear();
    });
  }

  void addMenuItem() {
    if (_menuItemController.text.isEmpty) return;

    setState(() {
      widget.menu[selectedDay.substring(0, 3)]![selectedMeal]!['items'].add(_menuItemController.text);
      _menuItemController.clear();
    });
  }

  void removeMealType(String day, String meal) {
    setState(() {
      String daySubString = day.substring(0,3);
      widget.menu[daySubString]!.remove(meal);
      if (widget.menu[daySubString]!.isEmpty) {
        widget.menu.remove(daySubString);
      }
    });
  }

  void removeMenuItem(String day, String meal, int index) {
    setState(() {
      widget.menu[day.substring(0,3)]![meal]!['items'].removeAt(index);
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Menu Editor'),
        actions: [
          IconButton(onPressed: () {
            Navigator.pop(context);
          }, icon: Icon(Icons.save))
        ]
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [

              //Menu Display
              for (var day in days)
                if (widget.menu.containsKey(day.substring(0,3)))
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$day:',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      for (var entry in widget.menu[day.substring(0,3)]!.entries)
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            '${entry.key}',
                                            style: Theme.of(context).textTheme.titleMedium,
                                          ),
                                          Text(
                                            '₹${entry.value['price']}',
                                            style: Theme.of(context).textTheme.titleMedium,
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                                      onPressed: () => removeMealType(day, entry.key),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                (entry.value['items'].length == 0) ? Center(child: Text('No items added in this meal')) : SizedBox(),
                                for (int i = 0; i < entry.value['items'].length; i++)
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text('     ${entry.value['items'][i]}'),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                                        onPressed: () => removeMenuItem(day, entry.key, i),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),



              // Meal Type Input
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: selectedDay,
                              decoration: const InputDecoration(
                                labelText: 'Day',
                                border: OutlineInputBorder(),
                              ),
                              items: days.map((day) =>
                                  DropdownMenuItem(
                                    value: day,
                                    child: Text(day),
                                  )
                              ).toList(),
                              onChanged: (value) => setState(() {
                                selectedDay = value!;
                              }),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: selectedMeal,
                              decoration: const InputDecoration(
                                labelText: 'Meal',
                                border: OutlineInputBorder(),
                              ),
                              items: mealTypes.map((meal) =>
                                  DropdownMenuItem(
                                    value: meal,
                                    child: Text(meal),
                                  )
                              ).toList(),
                              onChanged: (value) => setState(() {
                                selectedMeal = value!;
                              }),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _mealPriceController,
                        decoration: const InputDecoration(
                          labelText: 'Meal Price (₹)',
                          border: OutlineInputBorder(),
                          prefixText: '₹ ',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: addMealType,
                        child: const Text('Add Meal Type'),
                      ),
                    ],
                  ),
                ),
              ),

              // Menu Item Input
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _menuItemController,
                          decoration: const InputDecoration(
                            labelText: 'Menu Item',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: widget.menu[selectedDay.substring(0, 3)]?[selectedMeal] != null
                            ? addMenuItem
                            : null,
                        child: const Text('Add Item'),
                      ),
                    ],
                  ),
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }
}
