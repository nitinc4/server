import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/state/app_state.dart';
import 'features/auth/login_screen.dart';
import 'features/delivery/delivery_dashboard.dart';
import 'features/sales/sales_dashboard.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(),
      child: const ZudoDeliveryApp(),
    ),
  );
}

class ZudoDeliveryApp extends StatelessWidget {
  const ZudoDeliveryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, child) {
        return MaterialApp(
          title: 'Zudo Delivery',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          home: const MainNavigator(),
        );
      },
    );
  }
}

class MainNavigator extends StatelessWidget {
  const MainNavigator({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, child) {
        if (!state.isLoggedIn) {
          return const LoginScreen();
        }
        if (state.currentUser?.role == 'sales') {
          return const SalesDashboard();
        }
        return const DeliveryDashboard();
      },
    );
  }
}
