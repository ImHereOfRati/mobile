import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iamhere/feature/friend/view_model/contact_view_model_provider.dart';
import 'package:iamhere/feature/geofence/model/recipient.dart';
import 'package:iamhere/feature/geofence/view_model/recipient/all_recipients_provider.dart';
import 'package:iamhere/feature/geofence/view_model/recipient/recipient_select_view_model.dart';

import 'component.dart';

class RecipientSelectView extends ConsumerStatefulWidget {
  final List<String>? initialSelectedKeys;
  const RecipientSelectView({super.key, this.initialSelectedKeys});

  @override
  ConsumerState<RecipientSelectView> createState() =>
      _RecipientSelectViewState();
}

class _RecipientSelectViewState extends ConsumerState<RecipientSelectView> {
  @override
  Widget build(BuildContext context) {
    final allAsync = ref.watch(allRecipientsProvider);
    final state = ref.watch(
      recipientSelectViewModelProvider(widget.initialSelectedKeys),
    );
    final notifier = ref.read(
      recipientSelectViewModelProvider(widget.initialSelectedKeys).notifier,
    );

    return allAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: RecipientSelectErrorPage(error: e)),
      data: (all) {
        if (all.isEmpty) {
          return Scaffold(
            body: RecipientSelectEmptyPage(
              vmInterface: ref.read(contactViewModelInterfaceProvider),
            ),
          );
        }
        final server = all.whereType<ServerRecipient>().toList();
        final local = all.whereType<LocalRecipient>().toList();

        return Scaffold(
          body: Column(
            children: [
              RecipientSelectHeader(
                selectedCount: state.selectedCount,
                onConfirm: () => confirmRecipientSelection(
                  context,
                  ref,
                  all,
                  widget.initialSelectedKeys,
                ),
              ),
              RecipientSelectAllRow(
                isAllSelected: state.selectedCount == all.length,
                selectedCount: state.selectedCount,
                totalCount: all.length,
                onToggle: (_) => notifier.selectAll(all),
              ),
              Expanded(
                child: CustomScrollView(
                  slivers: [
                    if (server.isNotEmpty) ...[
                      const SliverToBoxAdapter(
                        child: RecipientSectionHeader('ImHere 친구'),
                      ),
                      RecipientSliverList(
                        recipients: server,
                        selectedKeys: state.selectedKeys,
                        onToggle: notifier.toggleSelection,
                      ),
                    ],
                    if (local.isNotEmpty) ...[
                      const SliverToBoxAdapter(
                        child: RecipientSectionHeader('내 기기 연락처'),
                      ),
                      RecipientSliverList(
                        recipients: local,
                        selectedKeys: state.selectedKeys,
                        onToggle: notifier.toggleSelection,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
