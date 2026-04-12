import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iamhere/shared/util/phone_number_formatter.dart'; // ✅ ScreenUtil import

class ContactTile extends StatelessWidget {
  final String contactName;
  final String phoneNumber;
  final VoidCallback? onDelete;

  const ContactTile({
    super.key,
    required this.contactName,
    required this.phoneNumber,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _contactBoxDecoration(context),
      width: 1.sw,
      height: 80.h,
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      margin: EdgeInsets.symmetric(vertical: 8.h),

      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildPhoneNumberOwner(context),
                SizedBox(height: 4.h),
                _buildPhoneNumber(),
              ],
            ),
          ),
          _buildDeleteButton(),
        ],
      ),
    );
  }

  BoxDecoration _contactBoxDecoration(BuildContext context) {
    return BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.all(Radius.circular(20.r)),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withValues(alpha: 0.1),
          spreadRadius: 1.r,
          blurRadius: 5.r,
          offset: Offset(0, 3.h),
        ),
      ],
    );
  }

  Text _buildPhoneNumberOwner(BuildContext context) {
    return Text(
      contactName,
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
        fontWeight: FontWeight.bold,
        fontSize: 20.sp,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }

  Row _buildPhoneNumber() {
    return Row(
      children: [
        Icon(Icons.call, size: 16.sp, color: Colors.grey),
        SizedBox(width: 4.w),
        Text(
          convertToPhoneNumber(phoneNumber),
          style: TextStyle(color: Colors.grey, fontSize: 15.sp),
        ),
      ],
    );
  }

  IconButton _buildDeleteButton() {
    return IconButton(
      icon: Icon(Icons.delete_forever_outlined, color: Colors.red, size: 24.w),
      onPressed: onDelete,
    );
  }
}
