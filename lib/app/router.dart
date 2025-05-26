import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_scanner/views/history_screen.dart';
import 'package:qr_scanner/views/qr_code_generator.dart';
import 'package:qr_scanner/views/scanner_screen.dart';
import 'package:qr_scanner/views/home_screen.dart';
import 'package:qr_scanner/widgets/navbar.dart';


final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final goRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/scanner-screen',
  routes: [
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) {
        return NavBar(child: child);
      },
      routes: [
         GoRoute(
          path: '/',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: '/home-screen',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: '/history-screen',
          builder: (context, state) => const HistoryScreen(),
        ),
        GoRoute(
          path: '/generator-screen',
          builder: (context, state) => const QRCodeGenerator(),
        ),
        GoRoute(
          path: '/qr-generator/:qrData',
          builder: (context, state) {
            final qrData = state.pathParameters['qrData'] ?? '';
            return QRCodeGenerator(initialData: Uri.decodeComponent(qrData));
          },
        ),
        GoRoute(path: '/scanner-screen',
          builder: (context, state) => ScannerScreen(),)
      ],
    ),
    
    ]);
