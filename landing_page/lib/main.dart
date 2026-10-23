import 'package:flutter/material.dart';
import 'package:iamhere/components/components.dart';

import 'landing_page.dart';
import 'legal_document_page.dart';

void main() => runApp(const ImHereLandingApp());

class ImHereLandingApp extends StatelessWidget {
  const ImHereLandingApp({
    super.key,
    this.initialDocument,
    this.termFetcher,
    this.onLaunchPlayStore,
  });

  final LegalDocumentType? initialDocument;
  final LegalTermFetcher? termFetcher;
  final Future<void> Function()? onLaunchPlayStore;

  @override
  Widget build(BuildContext context) {
    final resolvedDocument =
        initialDocument ??
        LegalDocumentType.fromQuery(Uri.base.queryParameters['document']);

    return MaterialApp(
      title: 'ImHere | 자동 출발·도착 알림',
      debugShowCheckedModeBanner: false,
      theme: ImHereTheme.light,
      themeMode: ThemeMode.light,
      home: LandingPage(
        initialDocument: resolvedDocument,
        termFetcher: termFetcher,
        onLaunchPlayStore: onLaunchPlayStore,
      ),
    );
  }
}
