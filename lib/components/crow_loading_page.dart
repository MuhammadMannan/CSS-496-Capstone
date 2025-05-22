import 'package:flutter/material.dart';
import 'package:campus_connect/components/crow_orb.dart'; // adjust path if needed

class CrowLoadingPage extends StatefulWidget {
  final VoidCallback onComplete;
  final Duration duration;

  const CrowLoadingPage({
    required this.onComplete,
    this.duration = const Duration(seconds: 2),
    super.key,
  });

  @override
  State<CrowLoadingPage> createState() => _CrowLoadingPageState();
}

class _CrowLoadingPageState extends State<CrowLoadingPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _pulse = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    Future.delayed(widget.duration, widget.onComplete);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bg = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: bg,
      body: Center(
        child: ScaleTransition(
          scale: _pulse,
          child: const CrowOrb(
            crowAsset: 'crow_reg.svg',
            size: 120,
          ),
        ),
      ),
    );
  }
}
