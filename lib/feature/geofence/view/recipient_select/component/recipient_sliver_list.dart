import 'package:flutter/material.dart';
import 'package:iamhere/feature/geofence/model/recipient.dart';
import 'recipient_tile.dart';

class RecipientSliverList extends StatelessWidget {
  final List<Recipient> recipients;
  final Set<String> selectedKeys;
  final Function(String) onToggle;

  const RecipientSliverList({
    super.key,
    required this.recipients,
    required this.selectedKeys,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildBuilderDelegate((context, i) {
        final r = recipients[i];
        return RecipientTile(
          key: ValueKey(r.selectionKey),
          recipient: r,
          isSelected: selectedKeys.contains(r.selectionKey),
          onTap: () => onToggle(r.selectionKey),
        );
      }, childCount: recipients.length),
    );
  }
}
