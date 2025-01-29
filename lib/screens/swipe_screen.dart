import 'dart:async';

import 'package:flutter/material.dart';
import 'package:movie_select/screens/liked_screen.dart';
import 'package:tmdb_api/tmdb_api.dart';
import 'filter_screen.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:movie_select/utils/ad_state.dart';
import 'package:provider/provider.dart';

class SwipeMoviesPage extends StatefulWidget {
  final TMDB tmdb;

  const SwipeMoviesPage({required this.tmdb, Key? key}) : super(key: key);

  @override
  _SwipeMoviesPageState createState() => _SwipeMoviesPageState();
}

class _SwipeMoviesPageState extends State<SwipeMoviesPage> {
  List<dynamic> movies = [];
  List<dynamic> tvShows = [];
  List<dynamic> combinedList = [];
  List<dynamic> likedMovies = [];
  int currentPage = 1;
  bool isLoading = false;
  final CardSwiperController swiperController = CardSwiperController();

  InterstitialAd? _interstitialAd;
  int swipeCount = 0;

  bool includeAdult = false;
  String? selectedGenre;
  String? selectedWatchProvider;

  @override
  void initState() {
    super.initState();
    _fetchMoviesAndTvShows();
    _loadInterstitialAd();
  }

  void _applyFilters(Map<String, dynamic> filters) {
    setState(() {
      includeAdult = filters['includeAdult'];
      selectedGenre = filters['withGenres'];
      movies.clear();
      tvShows.clear();
      combinedList.clear();
      currentPage = 1;
    });
    _fetchMoviesAndTvShows(includeAdult: includeAdult, genre: selectedGenre);
  }

  void _openFilterScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FilterScreen(
          onApplyFilters: _applyFilters,
          initialIncludeAdult: includeAdult,
          initialGenre: selectedGenre,
          initialWatchProvider: selectedWatchProvider,
          tmdb: widget.tmdb,
        ),
      ),
    );
  }

  Future<void> _fetchMoviesAndTvShows(
      {bool includeAdult = false, String? genre}) async {
    if (isLoading) return;

    setState(() {
      isLoading = true;
    });

    try {
      print("Fetching page: $currentPage");
      print("Watch provider: $selectedWatchProvider");
      final movieResponse = await widget.tmdb.v3.discover.getMovies(
        page: currentPage,
        sortBy: SortMoviesBy.popularityDesc,
        includeAdult: includeAdult,
        withGenres: genre,
        withWatchProviders: selectedWatchProvider,
      );
      final newMovies = movieResponse['results'] ?? [];
      print("Fetched ${newMovies.length} movies");

      final tvResponse = await widget.tmdb.v3.discover.getTvShows(
        page: currentPage,
        sortBy: SortTvShowsBy.popularityDesc,
        withGenres: genre,
      );
      final newTvShows = tvResponse['results'] ?? [];
      print("Fetched ${newTvShows.length} TV shows");

      setState(() {
        movies.addAll(newMovies);
        tvShows.addAll(newTvShows);
        _updateCombinedList(newMovies, newTvShows);
        currentPage++;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load movies and TV shows: $e')));
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _updateCombinedList(List<dynamic> newMovies, List<dynamic> newTvShows) {
    final newCombinedList = [];
    newCombinedList.addAll(newMovies);
    newCombinedList.addAll(newTvShows);
    setState(() {
      combinedList = newCombinedList;
    });
    print("Combined list updated with ${combinedList.length} items");
  }

  void _loadInterstitialAd() {
    final adState = Provider.of<AdState>(context, listen: false);
    adState.loadInterstitialAd(AdState.afterSwipeInterstitialAdUnitId, (ad) {
      setState(() {
        _interstitialAd = ad;
      });
    });
  }

  void _showInterstitialAd() {
    if (_interstitialAd != null) {
      _interstitialAd!.show();
      _loadInterstitialAd();
    }
  }

  FutureOr<bool> _handleSwipe(
      int oldIndex, int? currentIndex, CardSwiperDirection direction) {
    setState(() {
      swipeCount++;
    });
    print(
        "Swiped $direction on item at index $oldIndex, swipe count: $swipeCount");

    if (combinedList.isEmpty) {
      return false;
    }

    final item = combinedList[oldIndex];
    if (direction == CardSwiperDirection.right) {
      if (!likedMovies.any((likedItem) => likedItem['id'] == item['id'])) {
        setState(() {
          likedMovies.add(item);
        });
        print("Liked movie: ${item['title']}");
      }
    }

    if (swipeCount % 50 == 0) {
      _showInterstitialAd();
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final adState = Provider.of<AdState>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: Text('Spectare - Swipe to like'),
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list),
            onPressed: _openFilterScreen,
          ),
          IconButton(
            icon: Icon(Icons.favorite),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => LikedMoviesPage(
                    likedMovies: likedMovies,
                    adState: adState,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: combinedList.isEmpty
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: CardSwiper(
                    controller: swiperController,
                    cardsCount: combinedList.length,
                    cardBuilder:
                        (context, index, percentThresholdX, percentThresholdY) {
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
                              style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 10),
                            Text(
                              'Rating: ${item['vote_average'] ?? 'N/A'}',
                              style:
                                  TextStyle(fontSize: 16, color: Colors.grey),
                            ),
                            SizedBox(height: 10),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0),
                                child: SingleChildScrollView(
                                  child: Text(
                                    item['overview'] ?? 'No Description',
                                    style: TextStyle(
                                        fontSize: 16, color: Colors.white70),
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
                    onEnd: () => _fetchMoviesAndTvShows(
                        includeAdult: includeAdult, genre: selectedGenre),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: screenWidth / 2 - 40,
                      child: ElevatedButton(
                        onPressed: () =>
                            swiperController.swipe(CardSwiperDirection.left),
                        child: Icon(Icons.close),
                      ),
                    ),
                    SizedBox(width: 16),
                    SizedBox(
                      width: screenWidth / 2 - 40,
                      child: ElevatedButton(
                        onPressed: () =>
                            swiperController.swipe(CardSwiperDirection.right),
                        child: Icon(Icons.favorite),
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}
