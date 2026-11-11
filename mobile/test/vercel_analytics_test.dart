import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/services/vercel_analytics_service.dart';

void main() {
  group('VercelAnalyticsService', () {
    late VercelAnalyticsService analytics;

    setUp(() {
      analytics = VercelAnalyticsService.instance;
      analytics.reset('/');
    });

    test('initializes with root path /', () {
      expect(analytics.currentPath, '/');
    });

    test('trackPageView updates currentPath and normalizes leading slash', () {
      analytics.trackPageView('semester/5');
      expect(analytics.currentPath, '/semester/5');

      analytics.trackPageView('/downloads');
      expect(analytics.currentPath, '/downloads');
    });

    test('trackPageView deduplicates identical sequential calls', () {
      analytics.trackPageView('/semester/5');
      expect(analytics.currentPath, '/semester/5');

      // Subsequent identical call
      analytics.trackPageView('/semester/5');
      expect(analytics.currentPath, '/semester/5');
    });

    test('trackPageView ignores empty path', () {
      analytics.trackPageView('/semester/5');
      analytics.trackPageView('');
      expect(analytics.currentPath, '/semester/5');
    });
  });

  group('VercelAnalyticsObserver', () {
    late VercelAnalyticsService analytics;
    late VercelAnalyticsObserver observer;

    setUp(() {
      analytics = VercelAnalyticsService.instance;
      analytics.reset('/');
      observer = VercelAnalyticsObserver(analytics: analytics);
    });

    testWidgets('didPush tracks named routes and ignores un-named routes', (tester) async {
      final routeA = MaterialPageRoute(
        settings: const RouteSettings(name: '/semester/5'),
        builder: (_) => const SizedBox(),
      );

      observer.didPush(routeA, null);
      expect(analytics.currentPath, '/semester/5');

      // Unnamed route
      final routeUnnamed = MaterialPageRoute(
        builder: (_) => const SizedBox(),
      );

      observer.didPush(routeUnnamed, routeA);
      expect(analytics.currentPath, '/semester/5'); // Unchanged
    });

    testWidgets('didPop updates to previous route path', (tester) async {
      final routeHome = MaterialPageRoute(
        settings: const RouteSettings(name: '/'),
        builder: (_) => const SizedBox(),
      );
      final routeSem = MaterialPageRoute(
        settings: const RouteSettings(name: '/semester/5'),
        builder: (_) => const SizedBox(),
      );

      observer.didPush(routeHome, null);
      observer.didPush(routeSem, routeHome);
      expect(analytics.currentPath, '/semester/5');

      observer.didPop(routeSem, routeHome);
      expect(analytics.currentPath, '/');
    });

    testWidgets('didReplace updates to new route path', (tester) async {
      final routeA = MaterialPageRoute(
        settings: const RouteSettings(name: '/admin/login'),
        builder: (_) => const SizedBox(),
      );
      final routeB = MaterialPageRoute(
        settings: const RouteSettings(name: '/admin/dashboard'),
        builder: (_) => const SizedBox(),
      );

      observer.didPush(routeA, null);
      expect(analytics.currentPath, '/admin/login');

      observer.didReplace(newRoute: routeB, oldRoute: routeA);
      expect(analytics.currentPath, '/admin/dashboard');
    });
  });
}

