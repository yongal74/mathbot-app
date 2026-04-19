import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme.dart';
import 'screens/home_screen.dart';
import 'screens/problem_list_screen.dart';
import 'screens/concept_list_screen.dart';
import 'screens/camera_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/analysis_screen.dart';
import 'services/analytics_service.dart';
import 'services/auth_service.dart';
import 'services/game_service.dart';
import 'services/notification_service.dart';
import 'services/purchase_service.dart';
import 'services/tts_service.dart';
import 'services/wrong_note_service.dart';

final ValueNotifier<ThemeMode> themeModeNotifier =
    ValueNotifier(ThemeMode.light);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  // Firebase 초기화
  try {
    await Firebase.initializeApp();
    if (!kIsWeb) {
      FlutterError.onError =
          FirebaseCrashlytics.instance.recordFlutterFatalError;
      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };
    }
  } catch (e) {
    debugPrint('[Firebase] init failed: $e');
  }

  // 서비스 병렬 초기화
  await Future.wait([
    AnalyticsService().init().catchError((_) {}),
    GameService().load().catchError((_) {}),
    WrongNoteService().load().catchError((_) {}),
    TtsService().init().catchError((_) {}),
    NotificationService().load().catchError((_) {}),
    PurchaseService().init().catchError((_) {}),
    AuthService().load().catchError((_) {}),
  ]);

  final prefs = await SharedPreferences.getInstance();
  final onboardingDone = prefs.getBool('onboarding_done') ?? false;
  final savedTheme = prefs.getString('theme_mode') ?? 'light';
  themeModeNotifier.value =
      savedTheme == 'dark' ? ThemeMode.dark : ThemeMode.light;

  runApp(NunMathApp(onboardingDone: onboardingDone));
}

class NunMathApp extends StatelessWidget {
  final bool onboardingDone;
  const NunMathApp({super.key, required this.onboardingDone});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<PurchaseService>.value(
            value: PurchaseService()),
        ChangeNotifierProvider<AuthService>.value(value: AuthService()),
        ChangeNotifierProvider<GameService>.value(value: GameService()),
        ChangeNotifierProvider<WrongNoteService>.value(
            value: WrongNoteService()),
      ],
      child: ValueListenableBuilder<ThemeMode>(
        valueListenable: themeModeNotifier,
        builder: (context, mode, _) => MaterialApp(
          title: '눈수학',
          debugShowCheckedModeBanner: false,
          themeMode: mode,
          theme: buildAppTheme(),
          darkTheme: buildDarkTheme(),
          home: onboardingDone
              ? const MainTabScreen()
              : const OnboardingScreen(),
        ),
      ),
    );
  }
}

class MainTabScreen extends StatefulWidget {
  const MainTabScreen({super.key});

  @override
  State<MainTabScreen> createState() => _MainTabScreenState();
}

class _MainTabScreenState extends State<MainTabScreen> {
  int _currentIndex = 0;

  final _screens = const [
    HomeScreen(),
    ConceptListScreen(),
    ProblemListScreen(),
    CameraScreen(),
    AnalysisScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.pageBackground,
          border:
              Border(top: BorderSide(color: Color(0xFFDDDDDD), width: 0.5)),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (i) => setState(() => _currentIndex = i),
          backgroundColor: AppColors.pageBackground,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: '홈',
            ),
            NavigationDestination(
              icon: Icon(Icons.lightbulb_outline_rounded),
              selectedIcon: Icon(Icons.lightbulb_rounded),
              label: '개념',
            ),
            NavigationDestination(
              icon: Icon(Icons.menu_book_outlined),
              selectedIcon: Icon(Icons.menu_book_rounded),
              label: '문제',
            ),
            NavigationDestination(
              icon: Icon(Icons.camera_alt_outlined),
              selectedIcon: Icon(Icons.camera_alt_rounded),
              label: '사진',
            ),
            NavigationDestination(
              icon: Icon(Icons.bar_chart_outlined),
              selectedIcon: Icon(Icons.bar_chart_rounded),
              label: '분석',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded),
              label: '나',
            ),
          ],
        ),
      ),
    );
  }
}
