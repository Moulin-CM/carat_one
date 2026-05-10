import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart'
    show debugPrint, kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'views/auth/auth_wrapper.dart';
import 'views/splash/splash_view.dart';
import 'services/notification_service.dart';
import 'services/ads_service.dart';
import 'services/subscription_service.dart';
import 'viewmodels/subscription_viewmodel.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase must be ready before anything else (auth, db, etc.) — keep
  // this awaited.
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize Subscriptions
  final subService = SubscriptionService();
  await subService.initialize();

  // Set preferred orientations only on mobile platforms (not web). This
  // runs before runApp so the first frame is laid out correctly.
  if (!kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS)) {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  // Kick the UI off immediately. Anything below runs in parallel with the
  // splash animation so the user never sees a stalled main thread.
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SubscriptionViewModel()),
      ],
      child: const InvoiceApp(),
    ),
  );

  // Notification setup hits platform channels (timezone, exact-alarm
  // permission, channel creation) — fire-and-forget so it doesn't block
  // the first frame.
  // ignore: unawaited_futures
  Future(() async {
    try {
      await NotificationService.initialize();
    } catch (e) {
      // Notification initialization failed, but app can still run.
      debugPrint('Failed to initialize notifications: $e');
    }
  });

  // Initialize AdMob in the background — never block app startup on ads.
  // The service is a no-op on web/desktop so this is safe everywhere.
  // ignore: unawaited_futures
  AdsService.instance.initialize();
}

class InvoiceApp extends StatelessWidget {
  const InvoiceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CaratOne',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF4F8AF4)),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF5F7FB),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          titleSpacing: 0,
          iconTheme: IconThemeData(color: Colors.black87),
          titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.black87),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF5F7FB),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
        ),
        cardTheme: CardTheme(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      home: const SplashView(),
      routes: {
        '/home': (context) => const AuthWrapper(),
      },
    );
  }
}
