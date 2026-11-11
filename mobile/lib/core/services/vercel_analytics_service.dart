import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Service responsible for managing Vercel Web Analytics page-view tracking
/// in the Flutter Web single-page application.
class VercelAnalyticsService {
  static final VercelAnalyticsService instance = VercelAnalyticsService._internal();

  factory VercelAnalyticsService() => instance;

  VercelAnalyticsService._internal();

  String _currentPath = '/';

  /// Currently tracked route path.
  String get currentPath => _currentPath;

  /// Tracks a page view for [rawPath].
  ///
  /// Deduplicates sequential page view calls so redundant events are not sent.
  /// On Flutter Web, synchronizes browser history and URL state using
  /// [SystemNavigator.routeInformationUpdated], which triggers Vercel Analytics'
  /// client-side route change detection.
  void trackPageView(String rawPath, {bool replace = false}) {
    if (rawPath.isEmpty) return;

    final path = rawPath.startsWith('/') ? rawPath : '/$rawPath';

    // Strict deduplication: Do not re-trigger if already on the requested path
    if (_currentPath == path) return;

    _currentPath = path;

    if (kIsWeb) {
      try {
        SystemNavigator.routeInformationUpdated(
          uri: Uri.parse(path),
          replace: replace,
        );
      } catch (e) {
        debugPrint('VercelAnalytics route update error: $e');
      }
    }
  }

  /// Resets the tracked path (useful for testing).
  @visibleForTesting
  void reset([String initialPath = '/']) {
    _currentPath = initialPath;
  }
}

/// Navigator observer that intercepts route transitions and dispatches
/// page-view events to [VercelAnalyticsService].
class VercelAnalyticsObserver extends NavigatorObserver {
  final VercelAnalyticsService analytics;

  VercelAnalyticsObserver({VercelAnalyticsService? analytics})
      : analytics = analytics ?? VercelAnalyticsService.instance;

  String? _getRoutePath(Route<dynamic>? route) {
    if (route == null || route is PopupRoute) return null;
    final name = route.settings.name;
    if (name != null && name.isNotEmpty) {
      return name;
    }
    return null;
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    final path = _getRoutePath(route);
    if (path != null) {
      analytics.trackPageView(path);
    }
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    final path = _getRoutePath(newRoute);
    if (path != null) {
      analytics.trackPageView(path, replace: true);
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    final path = _getRoutePath(previousRoute);
    if (path != null) {
      analytics.trackPageView(path);
    }
  }
}

