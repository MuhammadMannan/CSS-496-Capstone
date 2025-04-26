import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'pages/unified_auth_page.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://hltshychtrcyzseoipcc.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhsdHNoeWNodHJjeXpzZW9pcGNjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDQyNTI4ODcsImV4cCI6MjA1OTgyODg4N30.IRMrVWUEDO5X6jDcq9JXjGBWboLhs788Js_hF8LP-aA',
  );
  runApp(MyApp(showDebugBanner: false));
}

class MyApp extends StatelessWidget {
  final bool showDebugBanner;

  const MyApp({super.key, required this.showDebugBanner});

  @override
  Widget build(BuildContext context) {
    return ShadApp.material(
      darkTheme: ShadThemeData(
        brightness: Brightness.dark,
        colorScheme: const ShadSlateColorScheme.dark(),
      ),
      title: 'UWB Flock',
      debugShowCheckedModeBanner: showDebugBanner,
      home: const OnboardingPage(),
      routes: {'/auth': (context) => const UnifiedAuthPage()},
    );
  }
}

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ShadTheme.of(context).colorScheme.background,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Center(
            child: Column(
              children: [
                const Text(
                  'UWB Flock',
                  style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Text(
                  'Connect. Discover. Thrive.\nYour gateway to student life at UWB.',
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
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
