import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'imhere_loading_indicator.dart';

class BootstrapSplashView extends StatefulWidget {
  const BootstrapSplashView({super.key});

  @override
  State<BootstrapSplashView> createState() => _BootstrapSplashViewState();
}

class _BootstrapSplashViewState extends State<BootstrapSplashView> {

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: const Center(child: ImHereLoadingIndicator(height: 72)),
        ),
      ),
    );
  }
}
