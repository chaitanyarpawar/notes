import 'package:flutter/material.dart';
import 'package:unity_ads_plugin/unity_ads_plugin.dart';
import '../utils/constants.dart';

class UnityBannerAdWidget extends StatefulWidget {
  final String placementId;

  const UnityBannerAdWidget({
    super.key,
    this.placementId = AppConstants.unityBannerPlacementId, // Use production placement ID
  });

  @override
  State<UnityBannerAdWidget> createState() => _UnityBannerAdWidgetState();
}

class _UnityBannerAdWidgetState extends State<UnityBannerAdWidget> {
  bool _isLoaded = false;
  bool _hasError = false;
  String _errorMessage = '';
  bool _showPlaceholder = true;
  int _loadAttempts = 0;
  static const int _maxLoadAttempts = 3;

  @override
  void initState() {
    super.initState();
    debugPrint('🚀 Unity Banner Widget initialized');
    _checkUnityAdsStatus();
  }

  void _checkUnityAdsStatus() async {
    debugPrint('⏳ Starting comprehensive Unity Ads status check...');

    // First, try immediate check
    try {
      bool isInitialized = await UnityAds.isInitialized();
      if (isInitialized) {
        debugPrint('🎉 Unity Ads already initialized!');
        _loadBannerAd();
        return;
      }
    } catch (e) {
      debugPrint('⚠️ Error on immediate Unity Ads check: $e');
    }

    // Extended wait with comprehensive retry logic
    int attempts = 0;
    const maxAttempts = 60; // 30 seconds total (60 × 500ms)

    debugPrint('⏳ Waiting for Unity Ads initialization... (up to 30 seconds)');

    while (attempts < maxAttempts && mounted) {
      await Future.delayed(const Duration(milliseconds: 500));
      attempts++;

      try {
        bool isInitialized = await UnityAds.isInitialized();

        // Log progress every 5 seconds
        if (attempts % 10 == 0) {
          debugPrint(
              '🔍 Unity Ads status check at ${attempts * 0.5}s: $isInitialized');
        }

        if (isInitialized) {
          debugPrint(
              '✅ Unity Ads finally initialized after ${attempts * 0.5} seconds');
          _loadBannerAd();
          return;
        }
      } catch (error) {
        if (attempts % 20 == 0) {
          debugPrint(
              '⚠️ Error checking Unity Ads status (${attempts * 0.5}s): $error');
        }
      }
    }

    // Ultimate fallback - Unity Ads completely failed
    debugPrint('💀 Unity Ads completely failed to initialize after 30 seconds');
    if (mounted) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Unity Ads unavailable (failed after 30s)';
        _showPlaceholder = false;
      });
    }
  }

  void _loadBannerAd() {
    debugPrint('🚀 Loading Unity Banner Ad...');
    if (mounted) {
      setState(() {
        _showPlaceholder = false;
        _hasError = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint(
        '🏗️ Building Unity Banner Widget - loaded: $_isLoaded, error: $_hasError, placeholder: $_showPlaceholder');

    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(
            color: Colors.blue.withValues(alpha: 0.3),
            width: 1), // Debug border
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: _showPlaceholder
          ? _buildPlaceholder()
          : _hasError
              ? _buildErrorWidget()
              : UnityBannerAd(
                  placementId: widget.placementId,
                  onLoad: (placementId) {
                    debugPrint(
                        '✅ Unity Banner loaded successfully: $placementId');
                    if (mounted) {
                      setState(() {
                        _isLoaded = true;
                        _hasError = false;
                        _loadAttempts = 0; // Reset attempts on success
                      });
                    }
                  },
                  onClick: (placementId) =>
                      debugPrint('🖱️ Unity Banner clicked: $placementId'),
                  onShown: (placementId) =>
                      debugPrint('👁️ Unity Banner shown: $placementId'),
                  onFailed: (placementId, error, message) {
                    debugPrint(
                        '❌ Unity Banner failed (attempt ${_loadAttempts + 1}): $message');
                    _loadAttempts++;

                    if (_loadAttempts < _maxLoadAttempts) {
                      debugPrint(
                          '🔄 Retrying Unity Banner load in 2 seconds...');
                      Future.delayed(const Duration(seconds: 2), () {
                        if (mounted) {
                          setState(() {
                            // This will trigger a rebuild and retry
                          });
                        }
                      });
                    } else {
                      debugPrint(
                          '💀 Unity Banner failed after $_maxLoadAttempts attempts');
                      if (mounted) {
                        setState(() {
                          _hasError = true;
                          _errorMessage =
                              'Failed after $_loadAttempts attempts: $message';
                        });
                      }
                    }
                  },
                ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      height: 60,
      color: Colors.grey.withValues(alpha: 0.1),
      child: const Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 8),
            Text(
              'Loading Unity Banner Ad...',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      height: 60,
      color: Colors.orange.withValues(alpha: 0.1),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.warning, color: Colors.orange, size: 16),
            const SizedBox(width: 8),
            Text(
              'Ad Load Error: $_errorMessage',
              style: const TextStyle(
                color: Colors.orange,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
