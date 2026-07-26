import 'package:flutter/material.dart';
import 'package:iamhere/shell/view/shell_status_view.dart';

class ShellSplashView extends StatelessWidget {
  const ShellSplashView({super.key});

  @override
  Widget build(BuildContext context) {
    return const ShellStatusView(
      icon: Icons.location_on_outlined,
      title: 'ImHere',
      message: '잠시만 기다려 주세요.',
      loading: true,
    );
  }
}
