import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// 약관 동의 화면 (임시 placeholder)
/// TERMS-003, TERMS-004에서 실제 UI 구현 예정
class TermsConsentView extends StatelessWidget {
  const TermsConsentView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('약관 동의'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                '약관에 동의하세요',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                '서비스를 이용하기 위해 약관에 동의해야 합니다.\n'
                '(실제 약관 UI는 향후 구현)',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  // 메인 화면으로 이동
                  context.go('/geofence');
                },
                child: const Text('동의'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
