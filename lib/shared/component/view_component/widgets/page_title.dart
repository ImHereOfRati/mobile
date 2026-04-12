import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class PageTitle extends StatefulWidget {
  final String pageTitle;
  final String pageDescription;
  final String pageInfoCount;
  final Widget? additionalWidget;
  final Widget? secondAdditionalWidget;
  final int interval;
  final int expandedWidgetFlex;

  const PageTitle({
    super.key,
    required this.pageTitle,
    required this.pageDescription,
    required this.pageInfoCount,
    this.additionalWidget,
    this.secondAdditionalWidget,
    this.interval = 0,
    this.expandedWidgetFlex = 2,
  });

  @override
  State<PageTitle> createState() => _PageTitleState();
}

class _PageTitleState extends State<PageTitle> {
  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: widget.expandedWidgetFlex,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.pageTitle,
              style: TextStyle(
                fontFamily: 'GmarketSans',
                fontSize: 22.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1D1D1F),
                letterSpacing: -0.3,
                height: 1.14,
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              widget.pageDescription,
              style: TextStyle(
                fontFamily: 'BMHANNAAir',
                fontSize: 13.sp,
                color: const Color(0xFF6E6E73),
                letterSpacing: -0.2,
                height: 1.43,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              widget.pageInfoCount,
              style: TextStyle(
                fontFamily: 'BMHANNAAir',
                fontSize: 13.sp,
                color: const Color(0xFF0071E3),
                fontWeight: FontWeight.w600,
                letterSpacing: -0.2,
              ),
            ),
            if (widget.interval > 0) SizedBox(height: 10.h * widget.interval),
            if (widget.additionalWidget != null) widget.additionalWidget!,
            if (widget.secondAdditionalWidget != null)
              widget.secondAdditionalWidget!,
          ],
        ),
      ),
    );
  }
}
