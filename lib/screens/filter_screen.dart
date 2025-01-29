import 'package:flutter/material.dart';
import 'dart:async';
import 'package:tmdb_api/tmdb_api.dart';

List<Map<String, String>> genres = [];
List<Map<String, String>> watchProviders = [];

// In FilterScreen (lib/screens/filter_screen.dart)
class FilterScreen extends StatefulWidget {
  final Function(Map<String, dynamic>) onApplyFilters;
  final bool initialIncludeAdult;
  final String? initialGenre;
  final String? initialWatchProvider;
  final TMDB tmdb;

  const FilterScreen({
    required this.onApplyFilters,
    required this.initialIncludeAdult,
    required this.initialGenre,
    required this.initialWatchProvider,
    required this.tmdb,
    Key? key,
  }) : super(key: key);

  @override
  _FilterScreenState createState() => _FilterScreenState();
}

class _FilterScreenState extends State<FilterScreen> {
  late bool includeAdult;
  late String? selectedGenre;
  late String? selectedWatchProvider;

  @override
  void initState() {
    super.initState();
    includeAdult = widget.initialIncludeAdult;
    selectedGenre = widget.initialGenre;
    selectedWatchProvider = widget.initialWatchProvider;
  }

  void _resetFilters() {
    setState(() {
      includeAdult = false;
      selectedGenre = null;
      selectedWatchProvider = null;
      loadGenres();
      loadWatchProviders();
    });
  }

  Future<void> loadGenres() async {
    if (genres.isEmpty) {
      final genresData = await widget.tmdb.v3.genres.getMovieList();
      for (var genre in genresData['genres']) {
        genres.add({'id': genre['id'].toString(), 'name': genre['name']});
      }
      //update State
      setState(() {
        genres = genres;
      });
      print("Genres: $genres");
    }
  }

  Future<void> loadWatchProviders() async {
    final watchProvidersData =
        await widget.tmdb.v3.watchProviders.getMovieProviders();
    for (var provider in watchProvidersData['results']) {
      watchProviders.add({
        'id': provider['provider_id'].toString(),
        'name': provider['provider_name'],
      });
    }
    //update State
    setState(() {
      watchProviders = watchProviders;
    });
    print("Watch Providers: $watchProviders");
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
          DropdownButton<String>(
            hint: Text('Select Watch Provider'),
            value: null,
            onChanged: (value) {},
            items: watchProviders.map((provider) {
              return DropdownMenuItem(
                value: provider['id'],
                child: Text(provider['name']!),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
