import 'package:flutter/material.dart';

const List<Map<String, String>> genres = [
  {'id': '28', 'name': 'Action'},
  {'id': '12', 'name': 'Adventure'},
  // Add more genres as needed
];
// In FilterScreen (lib/screens/filter_screen.dart)
class FilterScreen extends StatefulWidget {
  final Function(Map<String, dynamic>) onApplyFilters;
  final bool initialIncludeAdult;
  final String? initialGenre;

  const FilterScreen({
    required this.onApplyFilters,
    required this.initialIncludeAdult,
    required this.initialGenre,
    Key? key,
  }) : super(key: key);

  @override
  _FilterScreenState createState() => _FilterScreenState();
}

class _FilterScreenState extends State<FilterScreen> {
  late bool includeAdult;
  late String? selectedGenre;

  @override
  void initState() {
    super.initState();
    includeAdult = widget.initialIncludeAdult;
    selectedGenre = widget.initialGenre;
  }

  void _resetFilters() {
    setState(() {
      includeAdult = false;
      selectedGenre = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Filters'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _resetFilters,
          ),
          IconButton(
            icon: Icon(Icons.check),
            onPressed: () {
              widget.onApplyFilters({
                'includeAdult': includeAdult,
                'withGenres': selectedGenre,
              });
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          SwitchListTile(
            title: Text('Include Adult'),
            value: includeAdult,
            onChanged: (value) {
              setState(() => includeAdult = value);
            },
          ),
          DropdownButton<String>(
            hint: Text('Select Genre'),
            value: selectedGenre,
            onChanged: (value) {
              setState(() => selectedGenre = value);
            },
            items: genres.map((genre) {
              return DropdownMenuItem(
                value: genre['id'],
                child: Text(genre['name']!),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}