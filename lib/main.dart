import 'package:flutter/material.dart';
import 'package:tmdb_api/tmdb_api.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';
import 'config.dart';

void main() {
  final tmdb = TMDB(ApiKeys(apiKey, readAccessToken));
  runApp(MyApp(tmdb: tmdb));
}

class MyApp extends StatelessWidget {
  final TMDB tmdb;

  const MyApp({required this.tmdb});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      darkTheme: ThemeData.dark(),
      home: HomePage(tmdb: tmdb),
    );
  }
}
class HomePage extends StatelessWidget {
  final TMDB tmdb;

  const HomePage({required this.tmdb, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SwipeMoviesPage(tmdb: tmdb),
    );
  }
}

class SwipeMoviesPage extends StatefulWidget {
  final TMDB tmdb;

  const SwipeMoviesPage({required this.tmdb, Key? key}) : super(key: key);

  @override
  _SwipeMoviesPageState createState() => _SwipeMoviesPageState();
}

class _SwipeMoviesPageState extends State<SwipeMoviesPage> {
  List<dynamic> movies = []; // Stores the list of movies
  List<dynamic> tvShows = []; // Stores the list of TV shows
  List<dynamic> combinedList = [];
  List<dynamic> likedMovies = []; // Stores swiped 'liked' movies
  int currentPage = 1; // Keeps track of the current page for pagination
  bool isLoading = false; // Prevents multiple simultaneous API calls

  @override
  void initState() {
    super.initState();
    _fetchMoviesAndTvShows(); // Load the first page of both movies and TV shows
  }
  
  void _updateCombinedList() {
    combinedList.clear();

    int maxLength = movies.length > tvShows.length ? movies.length : tvShows.length;
    
    for (int i = 0; i < maxLength; i++) {
      if (i < movies.length) {
        combinedList.add(movies[i]); // Add movie
      }
      if (i < tvShows.length) {
        combinedList.add(tvShows[i]); // Add TV show
      }
    }
  }

  Future<void> _fetchMoviesAndTvShows() async {
    if (isLoading) return; // Prevent duplicate requests

    setState(() {
      isLoading = true;
    });

    try {
      // Fetch popular movies
      final movieResponse = await widget.tmdb.v3.discover.getMovies(
        page: currentPage,
        sortBy: SortMoviesBy.popularityDesc, // Sort by popularity (customizable)
      );
      final newMovies = movieResponse['results'] ?? [];

      // Fetch popular TV shows
      final tvResponse = await widget.tmdb.v3.discover.getTvShows(
        page: currentPage,
        sortBy: SortTvShowsBy.popularityDesc, // Sort by popularity (customizable)
      );
      final newTvShows = tvResponse['results'] ?? [];

      setState(() {
        // Add only unique movies and TV shows
        movies.addAll(newMovies.where((movie) => !movies.contains(movie)));
        tvShows.addAll(newTvShows.where((tvShow) => !tvShows.contains(tvShow)));
        _updateCombinedList();
        currentPage++; // Increment the page for pagination
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load movies and TV shows: $e')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }


FutureOr<bool> _handleSwipe(int oldIndex, int? currentIndex, CardSwiperDirection direction) {
    // Make sure currentIndex is not null
    final index = currentIndex ?? oldIndex;

    // Get the item from the combined list
    final item = combinedList[index -1];

    // Determine if the item is a movie or TV show
    if (movies.contains(item)) {
      // It's a movie
      if (direction == CardSwiperDirection.right) {
        // Like the movie
        setState(() {
          likedMovies.add(item); // Add the liked movie to the likedMovies list
        });
      }
    } else if (tvShows.contains(item)) {
      // It's a TV show
      if (direction == CardSwiperDirection.right) {
        // Like the TV show
        setState(() {
          likedMovies.add(item); // Add the liked TV show to the likedMovies list
        });
      }
    }
    // If it's the last item, load more content (movies and TV shows)
    if (index == combinedList.length - 1) {
      _fetchMoviesAndTvShows();
    }

    // Return true to allow the swipe action to continue
    return true;
  }
  // Scaffold widget with an AppBar and CardSwiper
  @override
  Widget build(BuildContext context) {
    return Scaffold(
    appBar: AppBar(
      title: Text('Swipe Movies & TV Shows'),
      actions: [
        IconButton(
          icon: Icon(Icons.favorite),
          onPressed: () {
            // Navigate to liked movies
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => LikedMoviesPage(likedMovies: likedMovies),
              ),
            );
          },
        ),
      ],
    ),
    body: (combinedList.isEmpty)
        ? Center(child: CircularProgressIndicator())
        : CardSwiper(
        cardsCount: combinedList.length,
        cardBuilder: (context, index, percentThresholdX, percentThresholdY) {
          final item = combinedList[index];
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              color: Colors.black,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                item['poster_path'] != null
                    ? Image.network(
                        'https://image.tmdb.org/t/p/w500${item['poster_path']}',
                        fit: BoxFit.cover,
                        height: 400,
                      )
                    : SizedBox.shrink(),
                SizedBox(height: 20),
                Text(
                  item['title'] ?? item['name'] ?? 'No Title',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 10),
                Text(
                  'Rating: ${item['vote_average'] ?? 'N/A'}',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                SizedBox(height: 10),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: SingleChildScrollView(
                      child: Text(
                        item['overview'] ?? 'No Description',
                        style: TextStyle(fontSize: 16, color: Colors.white70),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 10),
              ],
            ),
          );
        },
        onSwipe: _handleSwipe,
        onEnd: _fetchMoviesAndTvShows,
      ),
  );
  }
}

class LikedMoviesPage extends StatelessWidget {
  final List<dynamic> likedMovies;

  LikedMoviesPage({required this.likedMovies});

  // Helper function to open IMDb URL
  Future<void> _launchURL(Uri imdbUrl) async {
    if (await canLaunchUrl(imdbUrl)) {
      await launchUrl(imdbUrl);
    } else {
      throw 'Could not launch $imdbUrl';
    }
  }
  // Scaffold widget with an AppBar and ListView
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Liked Movies/TV Shows'),
      ),
      body: ListView.builder(
        itemCount: likedMovies.length,
        itemBuilder: (context, index) {
          final item = likedMovies[index];

          final tmdbUrl = Uri.parse('https://www.themoviedb.org/movie/${item['id']}');

          return ListTile(
            onTap: () => _launchURL(tmdbUrl), // Make the item clickable
            leading: item['poster_path'] != null
                ? Image.network(
                    'https://image.tmdb.org/t/p/w500${item['poster_path']}',
                    width: 50,
                    height: 75,
                    fit: BoxFit.cover,
                  )
                : SizedBox.shrink(),
            title: Text(item['title'] ?? item['name'] ?? 'No Title'),
            subtitle: Text('Rating: ${item['vote_average'] ?? 'N/A'}'),
          );
        },
      ),
    );
  }
}
