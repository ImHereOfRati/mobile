import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iamhere/feature/friend/view_model/contact_view_model_provider.dart';
import 'package:iamhere/feature/geofence/model/recipient.dart';
import 'package:iamhere/feature/geofence/view_model/recipient/all_recipients_provider.dart';
import 'package:iamhere/feature/geofence/view_model/recipient/recipient_select_state.dart';
import 'package:iamhere/feature/geofence/view_model/recipient/recipient_select_view_model.dart';

import 'component/recipient_select_status_pages.dart';
import 'component/recipient_select_widgets.dart';
import 'component/recipient_sliver_list.dart';

class RecipientSelectView extends ConsumerStatefulWidget {
  final List<String>? initialSelectedKeys;
  const RecipientSelectView({super.key, this.initialSelectedKeys});

  @override
  ConsumerState<RecipientSelectView> createState() =>
      _RecipientSelectViewState();
}

class _RecipientSelectViewState extends ConsumerState<RecipientSelectView> {
  void _confirmSelection(List<Recipient> all) {
    final res = ref
        .read(
          recipientSelectViewModelProvider(widget.initialSelectedKeys).notifier,
        )
        .confirmSelection(all);
    if (res != null) {
      Navigator.of(context).pop(res);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('최소 1명 이상 선택해주세요')));
    }
  }

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
      data: (all) => _buildDataBody(context, all, state, notifier),
    );
  }

  Widget _buildDataBody(
    BuildContext context,
    List<Recipient> all,
    RecipientSelectState state,
    RecipientSelectViewModel notifier,
  ) {
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
            onConfirm: () => _confirmSelection(all),
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
  }
}
