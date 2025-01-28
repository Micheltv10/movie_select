import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/ad_state.dart';

class LikedMoviesPage extends StatefulWidget {
  final List<dynamic> likedMovies;
  final AdState adState;

  LikedMoviesPage({required this.likedMovies, required this.adState});

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
    widget.adState.initialization.then((status) {
      _loadBannerAd();
    });
  }

  void _loadBannerAd() {
    _bannerAd = widget.adState.createBannerAd(
      AdState.testAdaptiveBannerAdUnitId,
      (ad) {
        setState(() {
          _isBannerAdReady = true;
        });
      },
      (ad, error) {
        setState(() {
          _isBannerAdReady = false;
        });
      },
    );
    _bannerAd!.load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
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
                final tmdbUrl = 'https://www.themoviedb.org/movie/${item['id']}';
                return ListTile(
                  onTap: () => _launchURL(Uri.parse(tmdbUrl)),
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