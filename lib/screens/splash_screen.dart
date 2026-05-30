import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1600), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 500),
            pageBuilder: (_, a, __) =>
                FadeTransition(opacity: a, child: const LoginScreen()),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.brandGradient),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(.2),
                        blurRadius: 30,
                        offset: const Offset(0, 12)),
                  ],
                ),
                child: const Icon(Icons.settings_suggest_rounded,
                    size: 64, color: AppTheme.primary),
              )
                  .animate()
                  .scale(duration: 600.ms, curve: Curves.easeOutBack)
                  .then()
                  .shimmer(duration: 900.ms),
              const SizedBox(height: 24),
              Text('PitStock',
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(color: Colors.white, fontWeight: FontWeight.w700))
                  .animate()
                  .fadeIn(delay: 300.ms)
                  .slideY(begin: .3, end: 0),
              const SizedBox(height: 6),
              Text('AI Spare Parts Inventory',
                      style: TextStyle(color: Colors.white.withOpacity(.85)))
                  .animate()
                  .fadeIn(delay: 500.ms),
            ],
          ),
        ),
      ),
    );
  }
}
