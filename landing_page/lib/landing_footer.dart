import 'package:flutter/material.dart';
import 'package:iamhere/components/components.dart';

import 'legal_document_page.dart';

class LandingFooter extends StatelessWidget {
  const LandingFooter({
    super.key,
    required this.onDocumentTap,
    required this.onDownloadTap,
  });

  final ValueChanged<LegalDocumentType> onDocumentTap;
  final VoidCallback onDownloadTap;

  @override
  Widget build(BuildContext context) {
    final colors = ImHereColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final compact = MediaQuery.sizeOf(context).width < 720;

    return ColoredBox(
      color: colors.surfaceSubtle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ImHereBorder(tone: ImHereDividerTone.muted),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1120),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 20 : 32,
                  vertical: compact ? 40 : 56,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const ImHereLogo(scale: 5 / 7),
                    const SizedBox(height: 12),
                    Text(
                      '출발·도착 연락을 대신 전하는 자동 출발·도착 알림 서비스',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Wrap(
                      spacing: 20,
                      runSpacing: 12,
                      children: [
                        _FooterLink(
                          key: const Key('footer-privacy-link'),
                          label: '개인정보처리방침',
                          strong: true,
                          onTap: () => onDocumentTap(LegalDocumentType.privacy),
                        ),
                        _FooterLink(
                          key: const Key('footer-terms-link'),
                          label: '서비스 약관',
                          onTap: () => onDocumentTap(LegalDocumentType.terms),
                        ),
                        _FooterLink(
                          key: const Key('footer-download-link'),
                          label: 'Google Play 다운로드',
                          onTap: onDownloadTap,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const ImHereBorder(tone: ImHereDividerTone.subtle),
                    const SizedBox(height: 20),
                    Text(
                      '© ImHere. Android 앱은 Google Play에서 무료로 이용할 수 있습니다.',
                      style: textTheme.bodySmall?.copyWith(
                        color: colors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FooterLink extends StatelessWidget {
  const _FooterLink({
    super.key,
    required this.label,
    required this.onTap,
    this.strong = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool strong;

  @override
  Widget build(BuildContext context) => ImHereButton(
    label: label,
    tone: strong ? ImHereButtonTone.neutral : ImHereButtonTone.ghost,
    size: ImHereButtonSize.sm,
    onPressed: onTap,
  );
}
