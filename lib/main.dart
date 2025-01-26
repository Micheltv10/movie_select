import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'package:tmdb_api/tmdb_api.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';
import 'config.dart';
import 'ad_state.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final initFuture = MobileAds.instance.initialize();
  final adState = AdState(initFuture);
  final tmdb = TMDB(ApiKeys(apiKey, readAccessToken));
  runApp(Provider.value(
    value: adState,
    builder: (context, child) => MyApp(tmdb: tmdb),
  ));
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
  List<dynamic> movies = [];
  List<dynamic> tvShows = [];
  List<dynamic> combinedList = [];
  List<dynamic> likedMovies = [];
  int currentPage = 1;
  bool isLoading = false;
  final CardSwiperController swiperController = CardSwiperController();

  InterstitialAd? _interstitialAd;
  int swipeCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchMoviesAndTvShows();
    _loadInterstitialAd();
  }


// Load interstitial ad
void _loadInterstitialAd() {
  InterstitialAd.load(
    adUnitId: "ca-app-pub-2675511241339445/8178430428", 
    request: AdRequest(),
    adLoadCallback: InterstitialAdLoadCallback(
      onAdLoaded: (InterstitialAd ad) {
        setState(() {
          _interstitialAd = ad; 
        });
      },
      onAdFailedToLoad: (LoadAdError error) {
        print("Interstitial ad failed to load: $error");
      },
    ),
  );
}

// Show interstitial ad after 10 swipes
void _showInterstitialAd() {
  if (_interstitialAd != null) {
    _interstitialAd!.show();
    _loadInterstitialAd(); 
  }
}

  FutureOr<bool> _handleSwipe(int oldIndex, int? currentIndex, CardSwiperDirection direction) {
    setState(() {
      swipeCount++; 
    });

    if (combinedList.isEmpty) {
      return false; 
    }

    final index = currentIndex ?? oldIndex;
    final validIndex = (index - 1) >= 0 ? index - 1 : 0;
    final item = combinedList[validIndex];

    if (movies.contains(item) || tvShows.contains(item)) {

      if (direction == CardSwiperDirection.right) {
        setState(() {
          likedMovies.add(item);
        });
      }
    }

    if (index == combinedList.length - 1) {
      _fetchMoviesAndTvShows();
    }

    if (swipeCount % 15 == 0) {
      _showInterstitialAd(); 
    }

    return true;
  }

  Future<void> _fetchMoviesAndTvShows() async {
    if (isLoading) return;

    setState(() {
      isLoading = true;
    });

    try {
      final movieResponse = await widget.tmdb.v3.discover.getMovies(page: currentPage, sortBy: SortMoviesBy.popularityDesc);
      final newMovies = movieResponse['results'] ?? [];

      final tvResponse = await widget.tmdb.v3.discover.getTvShows(page: currentPage, sortBy: SortTvShowsBy.popularityDesc);
      final newTvShows = tvResponse['results'] ?? [];

      setState(() {
        movies.addAll(newMovies);
        tvShows.addAll(newTvShows);
        _updateCombinedList();
        currentPage++;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load movies and TV shows: $e')));
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Update the combined list with movies and TV shows
  void _updateCombinedList() {
    combinedList.clear();
    int maxLength = movies.length > tvShows.length ? movies.length : tvShows.length;
    for (int i = 0; i < maxLength; i++) {
      if (i < movies.length) combinedList.add(movies[i]);
      if (i < tvShows.length) combinedList.add(tvShows[i]);
    }
  }

  @override
  void dispose() {
    _interstitialAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: Text('Spectare - Swipe Movies & TV Shows'),
        actions: [
          IconButton(
            icon: Icon(Icons.favorite),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => LikedMoviesPage(likedMovies: likedMovies)),
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
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: screenWidth / 2 - 40,
                      child: ElevatedButton(
                        onPressed: () => swiperController.swipe(CardSwiperDirection.left),
                        child: Icon(Icons.close),
                      ),
                    ),
                    SizedBox(width: 16),
                    SizedBox(
                      width: screenWidth / 2 - 40,
                      child: ElevatedButton(
                        onPressed: () => swiperController.swipe(CardSwiperDirection.right),
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


class LikedMoviesPage extends StatefulWidget {
  final List<dynamic> likedMovies;

  LikedMoviesPage({required this.likedMovies});

  @override
  State<LikedMoviesPage> createState() => _LikedMoviesPageState();
}

class _LikedMoviesPageState extends State<LikedMoviesPage> {
  BannerAd? _bannerAd;
  bool _isBannerAdReady = false;

  // Helper function to open IMDb URL
  Future<void> _launchURL(Uri imdbUrl) async {
    if (await canLaunchUrl(imdbUrl)) {
      await launchUrl(imdbUrl);
    } else {
      throw 'Could not launch $imdbUrl';
    }
  }

  @override
  void initState() {
    super.initState();
    // Initialize the Mobile Ads SDK
    MobileAds.instance.initialize();
    _loadBannerAd();
  }

  void _loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-2675511241339445/6292006838', 
      size: AdSize.banner,
      request: AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          setState(() {
            _isBannerAdReady = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          print('Failed to load banner ad: $error');
          setState(() {
            _isBannerAdReady = false;
          });
        },
      ),
    );

    _bannerAd!.load();
  }

  @override
  void dispose() {
    super.dispose();
    _bannerAd?.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Liked Movies/TV Shows'),
      ),
      body: Column(
        children: <Widget>[
          if (_isBannerAdReady)
            Container(
              height: 50,
              child: AdWidget(ad: _bannerAd!),
            ),
          Expanded(
            child: ListView.builder(
              itemCount: widget.likedMovies.length,
              itemBuilder: (context, index) {
                final item = widget.likedMovies[index];

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
          ),
        ],
      ),
    );
  }
}
