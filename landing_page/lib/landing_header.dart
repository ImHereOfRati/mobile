import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:iamhere/components/components.dart';

import 'download_modal.dart';
import 'legal_document_page.dart';

class LandingHeader extends StatelessWidget implements PreferredSizeWidget {
  const LandingHeader({
    super.key,
    required this.activeDocument,
    required this.onHomeTap,
    required this.onDocumentTap,
    this.onDownloadTap,
  });

  final LegalDocumentType? activeDocument;
  final VoidCallback onHomeTap;
  final ValueChanged<LegalDocumentType> onDocumentTap;
  final VoidCallback? onDownloadTap;

  @override
  Size get preferredSize => const Size.fromHeight(68);

  @override
  Widget build(BuildContext context) {
    final colors = ImHereColors.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 760;
    return Material(
      color: colors.background,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1120),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: compact ? 16 : 32,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Semantics(
                              button: true,
                              label: 'ImHere 홈',
                              child: InkWell(
                                key: const Key('header-brand-button'),
                                borderRadius: BorderRadius.circular(12),
                                onTap: onHomeTap,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 6,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SvgPicture.asset(
                                        'assets/app-logo.svg',
                                        width: 20,
                                        height: 20,
                                        semanticsLabel: 'ImHere 로고',
                                      ),
                                      const SizedBox(width: 8),
                                      const ImHereLogo(scale: 5 / 7),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!compact) ...[
                              _NavTextButton(
                                key: const Key('header-privacy-button'),
                                label: '개인정보처리방침',
                                selected:
                                    activeDocument == LegalDocumentType.privacy,
                                onTap: () =>
                                    onDocumentTap(LegalDocumentType.privacy),
                              ),
                              const SizedBox(width: 4),
                              _NavTextButton(
                                key: const Key('header-terms-button'),
                                label: '서비스 약관',
                                selected:
                                    activeDocument == LegalDocumentType.terms,
                                onTap: () =>
                                    onDocumentTap(LegalDocumentType.terms),
                              ),
                              const SizedBox(width: 8),
                            ] else ...[
                              PopupMenuButton<String>(
                                key: const Key('header-legal-menu-button'),
                                tooltip: '메뉴',
                                color: colors.surface,
                                elevation: 1,
                                onSelected: (value) {
                                  if (value == 'privacy') {
                                    onDocumentTap(LegalDocumentType.privacy);
                                  } else if (value == 'terms') {
                                    onDocumentTap(LegalDocumentType.terms);
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'privacy',
                                    child: Text('개인정보처리방침'),
                                  ),
                                  const PopupMenuItem(
                                    value: 'terms',
                                    child: Text('서비스 약관'),
                                  ),
                                ],
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 8,
                                  ),
                                  child: Text(
                                    '메뉴',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: colors.textMuted,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                            ],
                            ImHereButton(
                              key: const Key('header-download-button'),
                              label: '앱 다운로드',
                              tone: ImHereButtonTone.primary,
                              size: ImHereButtonSize.sm,
                              onPressed:
                                  onDownloadTap ??
                                  () => showDownloadModal(context),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const ImHereBorder(tone: ImHereDividerTone.subtle),
          ],
        ),
      ),
    );
  }
}

class _NavTextButton extends StatelessWidget {
  const _NavTextButton({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ImHereButton(
    label: label,
    tone: selected ? ImHereButtonTone.secondary : ImHereButtonTone.ghost,
    size: ImHereButtonSize.sm,
    onPressed: onTap,
  );
}
