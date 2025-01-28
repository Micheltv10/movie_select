import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdState {
  Future<InitializationStatus> initialization;

  AdState(this.initialization);

  // Test Ad Unit IDs
  static const String testAppOpenAdUnitId = 'ca-app-pub-3940256099942544/9257395921';
  static const String testAdaptiveBannerAdUnitId = 'ca-app-pub-3940256099942544/9214589741';
  static const String testFixedSizeBannerAdUnitId = 'ca-app-pub-3940256099942544/6300978111';
  static const String testInterstitialAdUnitId = 'ca-app-pub-3940256099942544/1033173712';
  static const String testRewardedAdUnitId = 'ca-app-pub-3940256099942544/5224354917';
  static const String testRewardedInterstitialAdUnitId = 'ca-app-pub-3940256099942544/5354046379';
  static const String testNativeAdUnitId = 'ca-app-pub-3940256099942544/2247696110';
  static const String testNativeVideoAdUnitId = 'ca-app-pub-3940256099942544/1044960115';

  // Real Ad Unit IDs
  static const String likedMoviesBannerAdUnitId = 'ca-app-pub-2675511241339445/6292006838';
  static const String afterSwipeInterstitialAdUnitId = 'ca-app-pub-2675511241339445/8178430428';

  BannerAd createBannerAd(String adUnitId, Function(BannerAd) onAdLoaded, Function(BannerAd, LoadAdError) onAdFailedToLoad) {
    return BannerAd(
      adUnitId: adUnitId,
      size: AdSize.banner,
      request: AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          print('Banner ad loaded.');
          onAdLoaded(ad as BannerAd);
        },
        onAdFailedToLoad: (ad, error) {
          print('Failed to load banner ad: $error');
          onAdFailedToLoad(ad as BannerAd, error);
          ad.dispose();
        },
      ),
    );
  }

  void loadInterstitialAd(String adUnitId, Function(InterstitialAd) onAdLoaded) {
    InterstitialAd.load(
      adUnitId: adUnitId,
      request: AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          print('Interstitial ad loaded.');
          onAdLoaded(ad);
        },
        onAdFailedToLoad: (LoadAdError error) {
          print('Failed to load interstitial ad: $error');
        },
      ),
    );
  }

  void loadRewardedAd(String adUnitId, Function(RewardedAd) onAdLoaded) {
    RewardedAd.load(
      adUnitId: adUnitId,
      request: AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          print('Rewarded ad loaded.');
          onAdLoaded(ad);
        },
        onAdFailedToLoad: (LoadAdError error) {
          print('Failed to load rewarded ad: $error');
        },
      ),
    );
  }
}
