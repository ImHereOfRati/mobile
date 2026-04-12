import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iamhere/contact/view/component/contact_tile.dart';
import 'package:iamhere/contact/view_model/contact.dart';
import 'package:iamhere/contact/view_model/contact_view_model.dart';
import 'package:iamhere/contact/view_model/contact_view_model_provider.dart';
import 'package:iamhere/shared/component/view_component/widgets/page_title.dart';

class ContactView extends ConsumerStatefulWidget {
  const ContactView({super.key});

  @override
  ConsumerState<ContactView> createState() => _ContactViewState();
}

class _ContactViewState extends ConsumerState<ContactView> {
  @override
  Widget build(BuildContext context) {
    final contactsAsyncValue = ref.watch(contactViewModelProvider);
    final ContactViewModel vm = ref.read(contactViewModelProvider.notifier);
    final vmInterface = ref.read(contactViewModelInterfaceProvider);

    final List<Contact> contacts = contactsAsyncValue.value ?? [];

    final pageTitle = "내 친구 목록";
    final pageDescription = "메시지를 받을 친구들";
    final pageInfoCount = "${contacts.length}명 등록됨";

    return Column(
      children: [
        PageTitle(
          key: ValueKey(pageTitle),
          pageTitle: pageTitle,
          pageDescription: pageDescription,
          pageInfoCount: pageInfoCount,
          additionalWidget: _buildContactImportButton(context, vmInterface),
          interval: 2,
        ),

        Expanded(flex: 5, child: buildContactTiles(contactsAsyncValue, vm)),
      ],
    );
  }

  Widget buildContactTiles(
    AsyncValue<List<Contact>> contactsAsyncValue,
    ContactViewModel vm,
  ) {
    return contactsAsyncValue.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(
        child: Padding(
          padding: EdgeInsets.all(20.w),
          child: Text(
            '연락처 로드 실패: ${err.toString().contains("Exception:") ? err.toString().split("Exception: ")[1] : err.toString()}',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.red, fontSize: 16.sp),
          ),
        ),
      ),

      data: (contacts) {
        if (contacts.isEmpty) {
          return Center(
            child: Text(
              "등록된 친구가 없습니다.\n위 버튼을 눌러 연락처를 불러오세요.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16.sp, color: Colors.grey),
            ),
          );
        }
        return ListView.builder(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          itemCount: contacts.length,
          itemBuilder: (context, index) {
            final contact = contacts[index];
            final contactId = contact.id;

            return ContactTile(
              key: ValueKey(contact.number),
              contactName: contact.name,
              phoneNumber: contact.number,
              onDelete: () {
                _confirmDelete(context, vm, contactId!, contact.name);
              },
            );
          },
        );
      },
    );
  }

  // 폰에서 친구 연락처 불러오기 버튼
  Widget _buildContactImportButton(BuildContext context, vmInterface) {
    onPressed() async {
      final result = await vmInterface.selectContact();

      if (result != null) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${result.name}님 연락처가 등록되었습니다!')),
        );
      } else {
        if (!context.mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('연락처 불러오기가 취소되었거나 실패했습니다.')));
      }
    }

    return Container(
      height: 60.h,
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        borderRadius: BorderRadius.all(Radius.circular(50.r)),
      ),
      child: Center(
        child: TextButton(
          onPressed: onPressed,
          child: Text(
            "폰에서 친구 연락처 불러오기",
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: Theme.of(context).colorScheme.surface,
              fontWeight: FontWeight.bold,
              fontSize: 18.sp,
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    ContactViewModel vm,
    int id,
    String name,
  ) {
    vm
        .deleteContact(id)
        .then((_) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('$name 님이 삭제되었습니다.')));
        })
        .catchError((e) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('삭제 실패: ${e.toString()}')));
        });
  }
}
