import 'package:flutter/material.dart';
import 'package:iamhere/components/components.dart';

import 'download_modal.dart';
import 'landing_footer.dart';
import 'landing_header.dart';
import 'legal_document_page.dart';
import 'scenes.dart';
import 'scroll_scene.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({
    super.key,
    this.initialDocument,
    this.termFetcher,
    this.onLaunchPlayStore,
  });

  final LegalDocumentType? initialDocument;
  final LegalTermFetcher? termFetcher;
  final Future<void> Function()? onLaunchPlayStore;

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  final ScrollController _scrollController = ScrollController();
  late LegalDocumentType? _activeDocument = widget.initialDocument;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _goHome() {
    setState(() => _activeDocument = null);
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _openDocument(LegalDocumentType type) {
    setState(() => _activeDocument = type);
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
  }

  void _openDownloadModal() {
    showDownloadModal(context, onLaunchPlayStore: widget.onLaunchPlayStore);
  }

  @override
  Widget build(BuildContext context) {
    final colors = ImHereColors.of(context);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: LandingHeader(
        activeDocument: _activeDocument,
        onHomeTap: _goHome,
        onDocumentTap: _openDocument,
        onDownloadTap: _openDownloadModal,
      ),
      body: _activeDocument != null
          ? SingleChildScrollView(
              key: const Key('landing-scroll-view'),
              controller: _scrollController,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  LegalDocumentSection(
                    documentType: _activeDocument!,
                    onBackToHome: _goHome,
                    termFetcher: widget.termFetcher,
                  ),
                  _footer(),
                ],
              ),
            )
          : LayoutBuilder(
              builder: (context, constraints) =>
                  _scenes(colors, constraints.maxHeight),
            ),
    );
  }

  LandingFooter _footer() => LandingFooter(
    onDocumentTap: _openDocument,
    onDownloadTap: _openDownloadModal,
  );

  Widget _scenes(ImHereColors colors, double vp) {
    final compact = MediaQuery.sizeOf(context).width < 900;
    return CustomScrollView(
      key: const Key('landing-scroll-view'),
      controller: _scrollController,
      physics: compact
          ? const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics())
          : const ClampingScrollPhysics(),
      slivers: [
        SceneSliver(
          viewportHeight: vp,
          scrollExtent: vp * (compact ? 0.62 : 0.9),
          background: colors.background,
          builder: (context, p) => HeroScene(
            progress: p,
            viewportHeight: vp,
            onDownloadTap: _openDownloadModal,
          ),
        ),
        SceneSliver(
          viewportHeight: vp,
          scrollExtent: vp * (compact ? 0.95 : 1.6),
          background: colors.surfaceSubtle,
          builder: (context, p) => StatementScene(progress: p),
        ),
        SceneSliver(
          viewportHeight: vp,
          scrollExtent: vp * (compact ? 2.4 : 3.6),
          background: colors.background,
          builder: (context, p) =>
              FeatureScene(progress: p, viewportHeight: vp),
        ),
        const SliverToBoxAdapter(child: TrustSection()),
        SliverToBoxAdapter(
          child: CtaSection(onDownloadTap: _openDownloadModal),
        ),
        SliverToBoxAdapter(child: _footer()),
      ],
    );
  }
}
