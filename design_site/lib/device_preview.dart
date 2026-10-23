import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:iamhere/components/components.dart';

import 'catalog_entry.dart';
import 'catalog_preview.dart';

class DevicePreview extends StatefulWidget {
  const DevicePreview({super.key, required this.entry});

  final CatalogEntry entry;

  @override
  State<DevicePreview> createState() => _DevicePreviewState();
}

class _DevicePreviewState extends State<DevicePreview> {
  /// Galaxy S26: 1080 x 2340 px at 3x, so 360 x 780 dp.
  static const _referenceSize = Size(360, 780);
  static const _labelHeight = 32.0;

  /// Galaxy S26 system areas: status bar with the camera cutout on top and the
  /// gesture bar at the bottom. Content stays inside these insets.
  static const safeInsets = EdgeInsets.only(top: 32, bottom: 24);
  String? message;
  int navigationIndex = 0;

  @override
  void didUpdateWidget(DevicePreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.entry != widget.entry) message = null;
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      // Keep the S26 aspect ratio and shrink to whatever space is left; never
      // scale up past 1:1.
      final room = constraints.maxHeight.isFinite
          ? (constraints.maxHeight - _labelHeight).clamp(1.0, double.infinity)
          : double.infinity;
      final scale = math.min(
        1.0,
        math.min(
          constraints.maxWidth / _referenceSize.width,
          room / _referenceSize.height,
        ),
      );
      final width = _referenceSize.width * scale;
      final height = _referenceSize.height * scale;
      return SizedBox(
        width: constraints.maxWidth.isFinite ? constraints.maxWidth : width,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              height: _labelHeight,
              child: Align(
                alignment: Alignment.topCenter,
                child: Text(
                  'Galaxy S26 · 360 × 780 dp',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ),
            SizedBox(
              key: const Key('galaxy-s26-preview-frame'),
              width: width,
              height: height,
              child: DecoratedBox(
                position: DecorationPosition.foreground,
                decoration: BoxDecoration(
                  border: Border.all(color: ImHereColors.of(context).border),
                  borderRadius: BorderRadius.circular(32),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(32),
                  child: FittedBox(
                    fit: BoxFit.contain,
                    alignment: Alignment.topLeft,
                    child: SizedBox.fromSize(
                      size: _referenceSize,
                      child: MediaQuery(
                        data: MediaQuery.of(context).copyWith(
                          size: _referenceSize,
                          padding: safeInsets,
                          viewPadding: safeInsets,
                        ),
                        child: Material(
                          color: ImHereColors.of(context).surface,
                          child: Stack(
                            children: [
                              Column(
                                children: [
                                  _topBar(),
                                  Expanded(
                                    // The bars above and below own the insets.
                                    child: MediaQuery.removePadding(
                                      context: context,
                                      removeTop: true,
                                      removeBottom: true,
                                      child: _content(),
                                    ),
                                  ),
                                  _navigation(),
                                ],
                              ),
                              _SystemBars(
                                highlight:
                                    widget.entry == CatalogEntry.safeArea,
                              ),
                              if (message != null)
                                Positioned(
                                  top: safeInsets.top + 64,
                                  left: 12,
                                  right: 12,
                                  child: Semantics(
                                    liveRegion: true,
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        color: ImHereColors.of(context).text,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Text(
                                          message!,
                                          style: TextStyle(
                                            color: ImHereColors.of(
                                              context,
                                            ).background,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );

  /// App shell top bar: pinned to the top of every preview.
  Widget _topBar() => ImHereTopBar(
    title: widget.entry.title,
    onBack: () => setState(() => message = '이전 화면으로 돌아가요.'),
  );

  /// App shell navigation: pinned to the bottom of every preview.
  Widget _navigation() => ImHereNavigation(
    items: const [
      ImHereNavItem(glyph: ImHereGlyph.place, label: '장소'),
      ImHereNavItem(glyph: ImHereGlyph.friends, label: '친구', hasUpdate: true),
      ImHereNavItem(glyph: ImHereGlyph.history, label: '기록'),
      ImHereNavItem(glyph: ImHereGlyph.settings, label: '설정'),
    ],
    index: navigationIndex,
    onChanged: (value) => setState(() => navigationIndex = value),
    onAdd: () => setState(() => message = '장소 추가 화면을 열었어요.'),
    addTooltip: '장소 추가',
  );

  Widget _content() {
    final preview = CatalogPreview(
      entry: widget.entry,
      onMessage: (value) => setState(() => message = value),
    );
    return switch (widget.entry) {
      CatalogEntry.bottomAction => Align(
        alignment: Alignment.bottomCenter,
        child: preview,
      ),
      CatalogEntry.progress => Center(child: preview),
      _ => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(ImHereSpace.gutter),
          child: preview,
        ),
      ),
    };
  }
}

/// Status bar and gesture bar drawn over the preview. With [highlight] the two
/// unsafe zones are shaded so the inset is visible.
class _SystemBars extends StatelessWidget {
  const _SystemBars({required this.highlight});

  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final colors = ImHereColors.of(context);
    final insets = _DevicePreviewState.safeInsets;
    final shade = highlight ? colors.error.withValues(alpha: 0.14) : null;
    return IgnorePointer(
      child: ExcludeSemantics(
        child: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: insets.top,
              child: ColoredBox(
                color: shade ?? Colors.transparent,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '9:41',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: colors.text,
                        ),
                      ),
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: colors.text,
                          shape: BoxShape.circle,
                        ),
                      ),
                      Text(
                        '100%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: colors.text,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: insets.bottom,
              child: ColoredBox(
                color: shade ?? Colors.transparent,
                child: Center(
                  child: Container(
                    width: 108,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colors.text.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
