import 'package:flutter/material.dart';

class CrowLoadingPage extends StatefulWidget {
  final VoidCallback onComplete;

  const CrowLoadingPage({super.key, required this.onComplete});

  @override
  State<CrowLoadingPage> createState() => _CrowLoadingPageState();
}

class _CrowLoadingPageState extends State<CrowLoadingPage> {
  @override
  void initState() {
    super.initState();
    // Simulate loading time
    Future.delayed(const Duration(seconds: 2), () {
      widget.onComplete();
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
