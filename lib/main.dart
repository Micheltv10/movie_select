import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:tmdb_api/tmdb_api.dart';
import 'screens/swipe_screen.dart';
import 'utils/ad_state.dart';
import 'config.dart';

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