import 'package:flutter/material.dart';
import 'package:iamhere/components/components.dart';
import 'package:url_launcher/url_launcher.dart';

const kGooglePlayStoreUrl =
    'https://play.google.com/store/apps/details?id=com.kdongsu5509.iamhere';

Future<void> openGooglePlayStore() async {
  final uri = Uri.parse(kGooglePlayStoreUrl);
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}

Future<void> showDownloadModal(
  BuildContext context, {
  Future<void> Function()? onLaunchPlayStore,
}) {
  final colors = ImHereColors.of(context);
  final metrics = ImHereMetrics.of(context);
  final textTheme = Theme.of(context).textTheme;

  return showDialog<void>(
    context: context,
    barrierColor: Colors.black54,
    builder: (dialogContext) => Dialog(
      backgroundColor: colors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      insetPadding: EdgeInsets.all(metrics.resolve(ImHereSpace.gutter)),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(metrics.resolve(ImHereRadius.lg)),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: EdgeInsets.all(metrics.resolve(ImHereSpace.lg)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const ImHereBadge(
                    label: '모바일 앱 다운로드',
                    tone: ImHereBadgeTone.action,
                  ),
                  IconButton(
                    tooltip: '설치 안내 닫기',
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    icon: ImHereIcon(
                      glyph: ImHereGlyph.close,
                      size: 20,
                      color: colors.textMuted,
                    ),
                  ),
                ],
              ),
              SizedBox(height: metrics.resolve(ImHereSpace.sm)),
              Semantics(
                header: true,
                child: Text('ImHere 앱 다운로드', style: textTheme.headlineMedium),
              ),
              SizedBox(height: metrics.resolve(ImHereSpace.xs)),
              Text(
                'Android 기기에서 Google Play를 통해 무료로 설치할 수 있어요.',
                style: textTheme.bodyMedium?.copyWith(color: colors.textMuted),
              ),
              SizedBox(height: metrics.resolve(ImHereSpace.lg)),
              ImHereButton(
                key: const Key('google-play-download-button'),
                label: 'Google Play에서 다운로드',
                size: ImHereButtonSize.lg,
                expand: true,
                onPressed: () async {
                  Navigator.of(dialogContext).pop();
                  if (onLaunchPlayStore != null) {
                    await onLaunchPlayStore();
                  } else {
                    await openGooglePlayStore();
                  }
                },
              ),
              SizedBox(height: metrics.resolve(ImHereSpace.xs)),
              const ImHereButton(
                key: Key('ios-unavailable-button'),
                label: 'iOS 앱 · 현재 제공 계획 없음',
                tone: ImHereButtonTone.weak,
                size: ImHereButtonSize.md,
                expand: true,
                onPressed: null,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
