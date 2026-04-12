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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: 15.h),
          Text(
            widget.pageTitle,
            style: Theme.of(context).textTheme.headlineMedium,
            textWidthBasis: TextWidthBasis.parent,
          ),
          Text(
            widget.pageDescription,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          SizedBox(height: 5.h),
          Text(
            widget.pageInfoCount,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).primaryColor,
              fontWeight: FontWeight.bold,
              fontSize: 18.sp,
            ),
            textWidthBasis: TextWidthBasis.parent,
          ),
          SizedBox(height: 10.h * widget.interval),
          ?widget.additionalWidget,
          ?widget.secondAdditionalWidget,
        ],
      ),
    );
  }
}
