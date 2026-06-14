import 'package:flutter/material.dart';
import 'package:iamhere/common/component/feedback/imhere_loading_indicator.dart';

class LoadingBody extends StatelessWidget {
  const LoadingBody({super.key});

  @override
  Widget build(BuildContext context) => const SliverFillRemaining(
        child: Center(child: ImHereLoadingIndicator()),
      );
}
