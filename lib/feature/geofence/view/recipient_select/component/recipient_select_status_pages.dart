import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iamhere/feature/friend/view_model/contact_view_model_interface.dart';
import 'package:iamhere/shared/component/style/app_text_styles.dart';
import 'recipient_select_constants.dart';

class RecipientSelectErrorPage extends StatelessWidget {
  final Object? error;
  const RecipientSelectErrorPage({super.key, this.error});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48.sp, color: cs.error),
            SizedBox(height: 16.h),
            Text(loadContactFailed, style: AppTextStyles.gSansBold(18, cs.onSurface)),
            SizedBox(height: 8.h),
            Text(error?.toString() ?? '', textAlign: TextAlign.center, style: AppTextStyles.hannaAirRegular(14, cs.onSurface.withValues(alpha: 0.55))),
          ],
        ),
      ),
    );
  }
}

class RecipientSelectEmptyPage extends StatelessWidget {
  final ContactViewModelInterface vmInterface;
  const RecipientSelectEmptyPage({super.key, required this.vmInterface});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.contacts_outlined, size: 64.sp, color: cs.onSurface.withValues(alpha: 0.3)),
          SizedBox(height: 16.h),
          Text(emptyList, style: AppTextStyles.gSansBold(18, cs.onSurface.withValues(alpha: 0.7))),
          SizedBox(height: 8.h),
          Text(addFriendPrompt, textAlign: TextAlign.center, style: AppTextStyles.hannaAirRegular(14, cs.onSurface.withValues(alpha: 0.55))),
          SizedBox(height: 24.h),
          ElevatedButton.icon(
            onPressed: () async {
              final result = await vmInterface.selectContact();
              if (result != null && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${result.name}$contactAddedSuffix')));
              }
            },
            icon: const Icon(Icons.person_add),
            label: Text(addContactButton),
            style: ElevatedButton.styleFrom(
              backgroundColor: cs.primary,
              foregroundColor: cs.onPrimary,
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
            ),
          ),
        ],
      ),
    );
  }
}
