import 'package:flutter/material.dart';
import 'pages/student_login_page.dart';
import 'pages/student_signup_page.dart';
import 'pages/club_login_page.dart';
import 'pages/club_signup_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: HomePage(),
      debugShowCheckedModeBanner: showDebugBanner,
      routes: {
        '/student-login': (context) => StudentLoginPage(),
        '/student-signup': (context) => StudentSignUpPage(),
        '/club-login': (context) => ClubLoginPage(),
        '/club-signup': (context) => ClubSignUpPage(),
      },
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home Page')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/student-login');
              },
              child: const Text('Student Login'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/student-signup');
              },
              child: const Text('Student Sign Up'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/club-login');
              },
              child: const Text('Club Login'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/club-signup');
              },
              child: const Text('Club Sign Up'),
            ),
          ],
        ),
      ),
    );
  }
}
