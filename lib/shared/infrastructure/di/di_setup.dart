import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

import 'di_setup.config.dart';

final getIt = GetIt.instance;

@InjectableInit(
  initializerName: 'init', // 초기화 함수 이름 (기본값 init)
  preferRelativeImports: true, // 생성된 코드에서 상대 경로 사용
  asExtension: true, // getIt.init() 처럼 확장 함수 형태로 생성
)
Future<void> configureDependencies({required String baseUrl}) async {
  getIt.registerSingleton<String>(baseUrl, instanceName: "baseUrl");
  await getIt.init();
}