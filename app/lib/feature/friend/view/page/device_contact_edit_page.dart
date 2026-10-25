import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iamhere/components/components.dart';
import 'package:iamhere/core/view/async_state_view.dart';
import 'package:iamhere/feature/friend/model/repository/contact_entity.dart';
import 'package:iamhere/feature/friend/model/service/device_contact_service.dart';
import 'package:iamhere/feature/friend/model/service/friend_service.dart';
import 'package:iamhere/feature/friend/viewmodel/device_contact_provider.dart';
import 'package:iamhere/feature/friend/viewmodel/friend_list_view_model.dart';

const _nameMaxLength = 30;

class DeviceContactEditPage extends ConsumerWidget {
  final FriendService friendService;
  final DeviceContactService contactService;
  final int contactId;

  const DeviceContactEditPage({
    super.key,
    required this.friendService,
    required this.contactService,
    required this.contactId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = deviceContactProvider(contactService, contactId);
    return Scaffold(
      backgroundColor: ImHereColors.of(context).background,
      body: AsyncStateView<ContactEntity?>(
        value: ref.watch(provider),
        errorTitle: '연락처를 불러오지 못했어요',
        onRetry: () => ref.invalidate(provider),
        builder: (contact) => contact == null
            ? const ImHereStatePanel(
                glyph: ImHereGlyph.person,
                title: '연락처를 찾을 수 없어요',
                size: ImHereStateSize.large,
              )
            : _EditForm(
                contact: contact,
                friendService: friendService,
                contactService: contactService,
              ),
      ),
    );
  }
}

class _EditForm extends ConsumerStatefulWidget {
  final ContactEntity contact;
  final FriendService friendService;
  final DeviceContactService contactService;

  const _EditForm({
    required this.contact,
    required this.friendService,
    required this.contactService,
  });

  @override
  ConsumerState<_EditForm> createState() => _EditFormState();
}

class _EditFormState extends ConsumerState<_EditForm> {
  late final TextEditingController _name = TextEditingController(
    text: widget.contact.name,
  );
  late final TextEditingController _phone = TextEditingController(
    text: widget.contact.number,
  );
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    final message = await ref
        .read(
          friendListViewModelProvider(
            widget.friendService,
            widget.contactService,
          ).notifier,
        )
        .renameContact(widget.contact, _name.text);
    if (!mounted) return;
    if (message == null) {
      _leave();
      return;
    }
    setState(() {
      _saving = false;
      _error = message;
    });
  }

  void _leave() => context.canPop() ? context.pop() : context.go('/friend');

  @override
  Widget build(BuildContext context) {
    final metrics = ImHereMetrics.of(context);
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        metrics.resolve(ImHereSpace.gutter),
        metrics.resolve(ImHereSpace.navToTitle),
        metrics.resolve(ImHereSpace.gutter),
        metrics.resolve(ImHereSpace.xl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ImHereTextField(
            label: '닉네임',
            controller: _name,
            maxLength: _nameMaxLength,
            errorText: _error,
            enabled: !_saving,
          ),
          SizedBox(height: metrics.resolve(ImHereSpace.md)),
          ImHereTextField(label: '전화번호', controller: _phone, enabled: false),
          SizedBox(height: metrics.resolve(ImHereSpace.lg)),
          Row(
            children: [
              Expanded(
                child: ImHereButton(
                  label: '취소',
                  tone: ImHereButtonTone.weak,
                  expand: true,
                  onPressed: _saving ? null : _leave,
                ),
              ),
              SizedBox(width: metrics.resolve(ImHereSpace.xs)),
              Expanded(
                child: ImHereButton(
                  label: '저장',
                  expand: true,
                  loading: _saving,
                  onPressed: _saving ? null : _save,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
