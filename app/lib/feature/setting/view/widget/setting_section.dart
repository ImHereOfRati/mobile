import 'package:flutter/material.dart';
import 'package:iamhere/components/components.dart';

/// 제목 하나와 그 아래 행들. 의미가 바뀌는 지점마다 구분선을 둔다.
class SettingSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  /// 마지막 섹션에서는 구분선을 끈다.
  final bool divider;

  const SettingSection({
    super.key,
    required this.title,
    required this.children,
    this.divider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ImHereListHeader(title: title),
        ...children,
        if (divider) const ImHereBorder(),
      ],
    );
  }
}
