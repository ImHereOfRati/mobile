import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class GeofenceTile extends StatelessWidget {
  final bool isToggleOn;
  final ValueChanged<bool> onToggleChanged;
  final String homeName;
  final String address;
  final int memberCount;
  final VoidCallback? onLongPress;

  const GeofenceTile({
    super.key,
    required this.isToggleOn,
    required this.onToggleChanged,
    required this.homeName,
    required this.address,
    required this.memberCount,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    Color tileBackgroundColor = _getBackgroundColor(context);

    return GestureDetector(
      onLongPress: onLongPress,
      child: Container(
        decoration: _getGeofenceTileDecoration(tileBackgroundColor),
        width: MediaQuery.of(context).size.width,
        height: 100.h,
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        margin: EdgeInsets.symmetric(vertical: 8.h), // 마진 추가하여 두 타일 분리

        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // 1. 정보 영역 (Expanded: Flex 4)
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildTileTitle(context),
                  SizedBox(height: 5.h),
                  // 주소와 인원 정보 행
                  _buildAdressAndPersonCount(),
                ],
              ),
            ),

            // 2. 토글 스위치 영역 (Expanded: Flex 1)
            Expanded(flex: 1, child: _buildOnOffToggle()),
          ],
        ),
      ),
    );
  }

  Align _buildOnOffToggle() {
    return Align(
      alignment: Alignment.centerRight,
      child: Transform.scale(
        // 스위치 크기 조절
        scale: 0.8, // 스위치 전체 크기 줄이기 (이미지 크기에 맞춤)
        child: Switch(
          value: isToggleOn,
          onChanged: onToggleChanged,
          // 활성화 시 트랙 색상 (이미지 밝은 청록색)
          activeColor: Colors.white, // thumb가 흰색이니 activeColor는 thumb color
          activeTrackColor: const Color(0xFF66C8C8), // 활성화 시 트랙 색상 (이미지 청록색)
          // 비활성화 시 트랙 색상 (이미지 회색)
          inactiveThumbColor: Colors.white, // 비활성화 시 thumb 색상 (흰색)
          inactiveTrackColor: Colors.grey.withValues(
            alpha: 0.4,
          ), // 비활성화 시 트랙 색상 (연한 회색)
        ),
      ),
    );
  }

  Row _buildAdressAndPersonCount() {
    return Row(
      children: [
        Icon(Icons.location_on, size: 16.w, color: Colors.grey),
        SizedBox(width: 1.w),
        Text(
          address,
          style: TextStyle(color: Colors.grey, fontSize: 15.sp),
        ),

        SizedBox(width: 20.w),

        Icon(Icons.people, size: 16.w, color: Colors.grey),
        SizedBox(width: 5.w),
        Text(
          '$memberCount명',
          style: TextStyle(color: Colors.grey, fontSize: 15.sp),
        ),
      ],
    );
  }

  Text _buildTileTitle(BuildContext context) {
    return Text(
      homeName,
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
        fontWeight: FontWeight.bold,
        fontSize: 25.sp,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }

  BoxDecoration _getGeofenceTileDecoration(Color tileBackgroundColor) {
    return BoxDecoration(
      color: tileBackgroundColor,
      borderRadius: BorderRadius.all(Radius.circular(25.w)),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withValues(alpha: 0.1),
          spreadRadius: 1,
          blurRadius: 5,
          offset: const Offset(0, 3), // changes position of shadow
        ),
      ],
    );
  }

  Color _getBackgroundColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isToggleOn) {
      return isDark ? const Color(0xFF1A2E2E) : const Color(0xFFE8F6F6);
    }
    return Theme.of(context).colorScheme.surface;
  }
}
