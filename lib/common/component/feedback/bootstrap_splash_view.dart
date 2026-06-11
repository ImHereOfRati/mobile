import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BootstrapSplashView extends StatefulWidget {
  const BootstrapSplashView({super.key});

  @override
  State<BootstrapSplashView> createState() => _BootstrapSplashViewState();
}

class _BootstrapSplashViewState extends State<BootstrapSplashView>
    with SingleTickerProviderStateMixin {
  static const _appleBlue = Color(0xFF0A84FF);
  static const _wordmarkGradient = LinearGradient(
    colors: [Color(0xFFD7EBFF), Color(0xFFFFFFFF), Color(0xFFB7DAFF)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<double> _scale;
  Timer? _startDelayTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _opacity = Tween(
      begin: 0.76,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _scale = Tween(
      begin: 0.985,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _startDelayTimer = Timer(const Duration(milliseconds: 180), () {
      if (!mounted) return;
      _controller.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _startDelayTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseStyle =
        Theme.of(context).textTheme.headlineLarge ??
        const TextStyle(fontFamily: 'GmarketSans', fontWeight: FontWeight.w700);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: _appleBlue,
        body: SafeArea(
          child: Center(
            child: FadeTransition(
              opacity: _opacity,
              child: ScaleTransition(
                scale: _scale,
                child: ShaderMask(
                  shaderCallback: (bounds) => _wordmarkGradient.createShader(
                    Rect.fromLTWH(0, 0, bounds.width, bounds.height),
                  ),
                  child: Text(
                    'ImHere',
                    textAlign: TextAlign.center,
                    style: baseStyle.copyWith(
                      color: Colors.white,
                      fontSize: 64,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -2.6,
                      height: 1,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
