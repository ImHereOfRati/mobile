import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iamhere/contact/view_model/contact.dart';

class RecipientTile extends StatelessWidget {
  final Contact contact;
  final bool isSelected;
  final VoidCallback onTap;

  const RecipientTile({
    super.key,
    required this.contact,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: _recipientDecoration(context),
        child: Row(
          children: [
            Checkbox(value: isSelected, onChanged: (_) => onTap()),
            SizedBox(width: 12.w),
            _buildCircleAvatar(colorScheme),
            SizedBox(width: 16.w),
            buildNameAndNumber(colorScheme),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: colorScheme.primary,
                size: 24.sp,
              ),
          ],
        ),
      ),
    );
  }

  CircleAvatar _buildCircleAvatar(ColorScheme colorScheme) {
    return CircleAvatar(
      radius: 24.r,
      backgroundColor: isSelected
          ? colorScheme.primary.withValues(alpha: 0.25)
          : colorScheme.onSurface.withValues(alpha: 0.15),
      child: Text(
        contact.name.isNotEmpty ? contact.name[0] : '?',
        style: TextStyle(
          fontSize: 18.sp,
          fontWeight: FontWeight.bold,
          color: isSelected
              ? colorScheme.primary
              : colorScheme.onSurface.withValues(alpha: 0.7),
        ),
      ),
    );
  }

  Expanded buildNameAndNumber(ColorScheme colorScheme) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            contact.name,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: isSelected ? colorScheme.primary : colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            contact.number,
            style: TextStyle(
              fontSize: 14.sp,
              color: colorScheme.onSurface.withValues(alpha: 0.55),
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _recipientDecoration(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return BoxDecoration(
      color: isSelected ? colorScheme.primary.withValues(alpha: 0.08) : null,
      border: Border(
        bottom: BorderSide(
          color: Theme.of(context).dividerTheme.color ?? colorScheme.onSurface.withValues(alpha: 0.12),
          width: 1,
        ),
      ),
    );
  }
}
