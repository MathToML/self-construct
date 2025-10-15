import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/responsive_nav.dart';
import '../widgets/header_component.dart';
import 'package:shadcn_playground/widgets/shared/mobile_nav_drawer.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const MobileNavDrawer(),
      body: Column(
        children: [
          // Custom responsive navigation
          const ResponsiveNav(),
          // Main content
          Expanded(
            child: HeaderComponent(
              badgeText: 'New Calendar Component',
              badgeIcon: 'arrow_forward',
              title: 'Building Blocks for the Web',
              description:
                  'Clean, modern building blocks. Copy and paste into your apps.',
              subtitle: 'Flutter. Open Source. Free forever.',
              actions: [
                HeaderAction(
                  text: 'Browse Blocks',
                  onPressed: () => context.go('/components'),
                  variant: HeaderActionVariant.primary,
                ),
                HeaderAction(
                  text: 'Add a block',
                  onPressed: () {
                    // Add a block functionality
                  },
                  variant: HeaderActionVariant.secondary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
