import 'package:flutter/material.dart';
import 'package:iamhere/components/components.dart';

/// 필수·선택 구분을 세 화면에서 같은 모양으로 보여 준다.
class TermRequirementBadge extends StatelessWidget {
  final bool isRequired;

  const TermRequirementBadge({super.key, required this.isRequired});

  @override
  Widget build(BuildContext context) => ImHereBadge(
    label: isRequired ? '필수' : '선택',
    tone: isRequired ? ImHereBadgeTone.action : ImHereBadgeTone.neutral,
    size: ImHereBadgeSize.medium,
  );
}
