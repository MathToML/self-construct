import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../screens/home_screen.dart';
import '../screens/components_screen.dart';
import '../screens/component_detail/component_detail_screen.dart';

/// GoRouter configuration for the application
class GoRouterConfig {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      // Home route
      GoRoute(
        path: '/',
        name: 'home',
        pageBuilder: (context, state) => NoTransitionPage(
          child: const HomeScreen(),
        ),
      ),

      // Components route
      GoRoute(
        path: '/components',
        name: 'components',
        pageBuilder: (context, state) => NoTransitionPage(
          child: const ComponentsScreen(),
        ),
      ),

      // Component detail route with parameter
      GoRoute(
        path: '/component/:componentName',
        name: 'component-detail',
        pageBuilder: (context, state) {
          final componentName = state.pathParameters['componentName']!;
          return NoTransitionPage(
            child: _buildComponentDetailPage(componentName),
          );
        },
      ),
    ],
    errorBuilder: (context, state) {
      // Error page - redirect to home for unknown routes
      return const HomeScreen();
    },
  );

  /// Builds component detail page with proper data loading
  static Widget _buildComponentDetailPage(String componentName) {
    return ShadSonner(
      child: ComponentDetailScreen(
        componentName: componentName,
      ),
    );
  }
}

/// Route constants for type-safe navigation
class AppRoutes {
  static const String home = '/';
  static const String components = '/components';
  static const String componentDetail = '/component';

  /// Generate component route path
  static String componentRoute(String componentName) =>
      '$componentDetail/$componentName';

  /// Extract component name from route path
  static String? extractComponentName(String routePath) {
    if (!routePath.startsWith('$componentDetail/')) return null;
    final name = routePath.substring('$componentDetail/'.length);
    return name.isNotEmpty ? name : null;
  }

  /// Validate if route is valid
  static bool isValidRoute(String routePath) {
    return routePath == home ||
        routePath == components ||
        extractComponentName(routePath) != null;
  }
}
