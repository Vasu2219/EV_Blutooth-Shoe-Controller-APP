import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:go_router/go_router.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/homescreen.dart';
import 'screens/controlscreen.dart';
import 'screens/services_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Default to portrait for login/signup
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final router = GoRouter(
      initialLocation: '/login',
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) {
            // Ensure portrait orientation for login
            SystemChrome.setPreferredOrientations([
              DeviceOrientation.portraitUp,
              DeviceOrientation.portraitDown,
            ]);
            return const LoginScreen();
          },
        ),
        GoRoute(
          path: '/signup',
          builder: (context, state) {
            // Ensure portrait orientation for signup
            SystemChrome.setPreferredOrientations([
              DeviceOrientation.portraitUp,
              DeviceOrientation.portraitDown,
            ]);
            return const SignupScreen();
          },
        ),
        GoRoute(
          path: '/services',
          builder: (context, state) {
            // Keep portrait orientation for services
            SystemChrome.setPreferredOrientations([
              DeviceOrientation.portraitUp,
              DeviceOrientation.portraitDown,
            ]);
            return const ServicesScreen();
          },
        ),
        GoRoute(
          path: '/home',
          builder: (context, state) {
            // Allow all orientations for home screen
            SystemChrome.setPreferredOrientations([
              DeviceOrientation.landscapeLeft,
              DeviceOrientation.landscapeRight,
            ]);
            return const HomeScreen();
          },
        ),
        GoRoute(
          path: '/controller',
          name: 'controller',
          builder: (context, state) => ControlScreen(
            device: state.extra as BluetoothDevice,
          ),
        ),
      ],
    );

    return MaterialApp.router(
      title: 'RC Controller',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.black,
      ),
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}