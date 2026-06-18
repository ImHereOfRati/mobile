import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'component.dart';

class GeofenceListView extends ConsumerWidget {
  const GeofenceListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: const GeofenceHeader(),
        ),

        const GeofenceListBody(),
      ],
    );
  }
}
