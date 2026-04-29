import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Android Auto Backup 은 우리 SQLite 파일까지 같이 백업해 두었다가
/// "삭제 후 재설치" 시 stale DB(예전 user_version) 를 그대로 복원시킨다.
/// 그러면 새 스키마에 대한 onUpgrade 가 다시 안 돌아 같은 "no such table"
/// 오류가 재현되므로, 매니페스트에서 명시적으로 비활성화한다.
///
/// 이 테스트는 누군가 모르고 그 플래그를 다시 풀어 두는 회귀를 잡기 위한
/// 단순 lock-in 검증이다.
void main() {
  test('main AndroidManifest 의 application 에 allowBackup="false" 가 설정돼 있다', () {
    final manifest = File('android/app/src/main/AndroidManifest.xml');
    expect(
      manifest.existsSync(),
      isTrue,
      reason: 'AndroidManifest.xml 이 예상 경로에 없습니다: ${manifest.path}',
    );

    final content = manifest.readAsStringSync();

    expect(
      content,
      contains('android:allowBackup="false"'),
      reason: 'Auto Backup 으로 stale DB 가 복원되는 것을 막기 위해 '
          'allowBackup="false" 가 반드시 설정돼 있어야 한다.',
    );
  });
}
