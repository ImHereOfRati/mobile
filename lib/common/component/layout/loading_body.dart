import 'package:flutter/material.dart';

class LoadingBody extends StatelessWidget {
  const LoadingBody({super.key});

  @override
  Widget build(BuildContext context) => const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator()),
      );
}
