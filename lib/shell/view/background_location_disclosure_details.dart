import 'package:flutter/material.dart';

class BackgroundLocationDisclosureDetails extends StatelessWidget {
  const BackgroundLocationDisclosureDetails({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DisclosureDetailRow(label: '필요 권한', value: '백그라운드 위치 권한 — 항상 허용'),
        SizedBox(height: 10),
        _DisclosureDetailRow(
          label: '수집 목적',
          value:
              '기기의 위치 정보로 설정한 장소의 도착·이탈을 감지하고, 앱이 닫혀 있거나 사용하지 않는 동안에도 위치 기반 자동 알림 제공',
        ),
        SizedBox(height: 10),
        _DisclosureDetailRow(label: '제공 대상', value: '사용자가 알림 대상으로 선택한 친구'),
        SizedBox(height: 10),
        _DisclosureDetailRow(
          label: '전송 시점',
          value: '설정한 장소의 도착·이탈을 감지해 친구에게 알림을 보낼 때만 전송',
        ),
        SizedBox(height: 18),
        _DisclosureSectionTitle('설정 방법'),
        SizedBox(height: 6),
        _DisclosureStep('동의 후 위치 권한에서 ‘앱 사용 중 허용’ 선택'),
        _DisclosureStep('장소 등록 전 권한 안내에서 앱 설정 열기'),
        _DisclosureStep('위치 권한에서 ‘항상 허용’ 선택'),
      ],
    );
  }
}

class _DisclosureSectionTitle extends StatelessWidget {
  final String text;

  const _DisclosureSectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: Theme.of(context).colorScheme.onSurface,
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _DisclosureStep extends StatelessWidget {
  final String text;

  const _DisclosureStep(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        '• $text',
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontSize: 14,
          height: 1.45,
        ),
      ),
    );
  }
}

class _DisclosureDetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DisclosureDetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Text.rich(
      TextSpan(
        style: TextStyle(
          color: scheme.onSurfaceVariant,
          fontSize: 14,
          height: 1.5,
        ),
        children: [
          TextSpan(
            text: '$label\n',
            style: TextStyle(
              color: scheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          TextSpan(text: value),
        ],
      ),
    );
  }
}
