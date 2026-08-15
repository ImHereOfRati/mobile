import 'package:flutter_test/flutter_test.dart';
import 'package:iamhere/shell/web_url_resolver.dart';

void main() {
  final fallback = Uri.parse('https://fallback.example/app');

  test('uses a valid HTTPS Remote Config URL', () async {
    final resolver = WebUrlResolver(
      loadRemoteUrl: () async => ' https://release.example ',
      fallbackUrl: fallback,
    );

    expect(await resolver.resolve(), Uri.parse('https://release.example/app'));
  });

  test('falls back when the remote URL is invalid', () async {
    final resolver = WebUrlResolver(
      loadRemoteUrl: () async => 'http://release.example/app',
      fallbackUrl: fallback,
    );

    expect(await resolver.resolve(), fallback);
  });

  test('falls back when Remote Config throws', () async {
    final resolver = WebUrlResolver(
      loadRemoteUrl: () async => throw StateError('offline'),
      fallbackUrl: fallback,
    );

    expect(await resolver.resolve(), fallback);
  });
}
