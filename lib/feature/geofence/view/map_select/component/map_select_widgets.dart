import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iamhere/feature/geofence/model/location_search_result.dart';
import 'package:iamhere/shared/component/style/app_text_styles.dart';

class MapSelectResult {
  final NLatLng location;
  final String address;
  MapSelectResult({required this.location, required this.address});
}

class MapSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isSearching;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onClear;

  const MapSearchBar({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.isSearching,
    required this.onChanged,
    required this.onSubmitted,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [BoxShadow(color: cs.shadow.withValues(alpha: 0.15), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        style: AppTextStyles.hannaAirRegular(14, cs.onSurface),
        decoration: InputDecoration(
          hintText: '주소 또는 장소명을 검색하세요',
          hintStyle: AppTextStyles.hannaAirRegular(14, cs.onSurface.withValues(alpha: 0.4)),
          prefixIcon: Icon(Icons.search, size: 22.r, color: cs.onSurface.withValues(alpha: 0.5)),
          suffixIcon: isSearching
              ? Padding(padding: EdgeInsets.all(12.r), child: SizedBox(width: 18.r, height: 18.r, child: CircularProgressIndicator(strokeWidth: 2, color: cs.primary)))
              : controller.text.isNotEmpty
                  ? IconButton(icon: Icon(Icons.close, size: 20.r, color: cs.onSurface.withValues(alpha: 0.5)), onPressed: onClear)
                  : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        ),
      ),
    );
  }
}

class MapSearchResults extends StatelessWidget {
  final List<LocationSearchResult> results;
  final ValueChanged<LocationSearchResult> onTap;

  const MapSearchResults({super.key, required this.results, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      constraints: BoxConstraints(maxHeight: 280.h),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [BoxShadow(color: cs.shadow.withValues(alpha: 0.12), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12.r),
        child: ListView.separated(
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          itemCount: results.length,
          separatorBuilder:
              (_, __) => Divider(height: 1, color: cs.onSurface.withValues(alpha: 0.08)),
          itemBuilder: (context, i) => _buildResultItem(context, results[i], cs),
        ),
      ),
    );
  }

  Widget _buildResultItem(
    BuildContext context,
    LocationSearchResult res,
    ColorScheme cs,
  ) {
    final isPlace = res.type == LocationSearchType.place;
    return InkWell(
      onTap: () => onTap(res),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Row(
          children: [
            Icon(
              isPlace ? Icons.place_outlined : Icons.location_on_outlined,
              size: 20.r,
              color: isPlace ? cs.tertiary : cs.primary,
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    res.title,
                    style: AppTextStyles.hannaAirBold(13, cs.onSurface),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (res.address.isNotEmpty)
                    Text(
                      res.address,
                      style: AppTextStyles.hannaAirRegular(
                        12,
                        cs.onSurface.withValues(alpha: 0.55),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MapConfirmButton extends StatelessWidget {
  final VoidCallback onTap;
  const MapConfirmButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: cs.primary,
        padding: EdgeInsets.symmetric(vertical: 16.h),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
        elevation: 4,
      ),
      child: Text('이 위치로 선택', style: AppTextStyles.hannaAirBold(16, cs.onPrimary)),
    );
  }
}
