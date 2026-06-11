import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('수신자 선택')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('수신자 선택')),
        body: const RecipientSelectErrorPage(),
      ),
      data: (all) {
        if (all.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: const Text('수신자 선택')),
            body: RecipientSelectEmptyPage(
              vmInterface: ref.read(contactViewModelInterfaceProvider),
            ),
          );
        }
        final server = all.whereType<ServerRecipient>().toList();
        final local = all.whereType<LocalRecipient>().toList();
        final isConfirmEnabled = state.selectedCount > 0;

        return Scaffold(
          appBar: AppBar(
            title: const Text('수신자 선택'),
          ),
          body: Stack(
            children: [
              Column(
                children: [
                  SelectedChipRow(
                    selectedKeys: state.selectedKeys,
                    all: all,
                    onToggle: notifier.toggleSelection,
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
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: EdgeInsets.all(16.w),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: isConfirmEnabled
                          ? () => confirmRecipientSelection(
                                context,
                                ref,
                                all,
                                widget.initialSelectedKeys,
                              )
                          : null,
                      child: Text(
                        '완료${isConfirmEnabled ? ' (${state.selectedCount})' : ''}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
