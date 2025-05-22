// Import Flutter core UI library.
import 'package:flutter/material.dart';
// Import Supabase Flutter package for backend services (auth, database, etc.).
import 'package:supabase_flutter/supabase_flutter.dart';
// Import the custom page for unified authentication (handles login/signup for both roles).
import 'pages/unified_auth_page.dart';
// Import ShadCN UI package for consistent design system and components.
import 'package:shadcn_ui/shadcn_ui.dart';
import 'components/main_logo.dart';
import 'components/crow_loading_page.dart';

void main() async {
  // Ensure widget binding is initialized before calling asynchronous code.
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the Supabase client with the given project URL and anon key.
  await Supabase.initialize(
    url: 'https://hltshychtrcyzseoipcc.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhsdHNoeWNodHJjeXpzZW9pcGNjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDQyNTI4ODcsImV4cCI6MjA1OTgyODg4N30.IRMrVWUEDO5X6jDcq9JXjGBWboLhs788Js_hF8LP-aA',
  );
  runApp(const AppLauncher());
}

class AppLauncher extends StatefulWidget {
  const AppLauncher({super.key});

  @override
  State<AppLauncher> createState() => _AppLauncherState();
}

class _AppLauncherState extends State<AppLauncher> {
  bool _loadingDone = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: _loadingDone
      ? const MyApp(showDebugBanner: false)
      : CrowLoadingPage(
        onComplete: () {
          setState(() {
            _loadingDone = true;
          });
        },
      ),
    );
  }
}

// MyApp is the root of the widget tree and configures the theme, routing, and homepage.
class MyApp extends StatelessWidget {
  final bool showDebugBanner;

  const MyApp({super.key, required this.showDebugBanner});

  @override
  Widget build(BuildContext context) {
    return ShadApp.material(
      // Apply dark theme configuration using ShadSlateColorScheme.
      darkTheme: ShadThemeData(
        brightness: Brightness.dark,
        colorScheme: const ShadSlateColorScheme.dark(),
      ),
      title: 'UWB Flock', // Title shown in system UI or task switchers.
      debugShowCheckedModeBanner: showDebugBanner, // Hide/show debug banner.
      // Set the initial landing page of the app.
      home: const OnboardingPage(),

      // Define named routes for navigation.
      routes: {
        '/auth': (context) => const UnifiedAuthPage(), // Authentication page.
      },
    );
  }
}

// Stateless widget that defines the onboarding or landing screen.
class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Set background color using the current Shad theme.
      backgroundColor: ShadTheme.of(context).colorScheme.background,
      body: Column(
        mainAxisAlignment:
            MainAxisAlignment.center, // Center content vertically.
        children: [
          Center(
            child: Column(
              children: [
                // App title icon/svg displayed prominently.
                const MainLogo(width: 280),
                const SizedBox(height: 16), // Add spacing.
                // App subtitle or mission statement.
                Text(
                  'Connect. Discover. Thrive.\nYour gateway to student life at UWB.',
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // Call-to-action button that navigates to the authentication screen.
                ShadButton(
                  size: ShadButtonSize.lg,
                  onPressed: () => Navigator.pushNamed(context, '/auth'),
                  child: const Text('Get Started'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
