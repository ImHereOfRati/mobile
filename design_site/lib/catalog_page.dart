import 'package:flutter/material.dart';
import 'package:iamhere/components/components.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'catalog_entry.dart';
import 'device_preview.dart';

const _sectionLabels = {
  CatalogSection.introduction: '시작',
  CatalogSection.foundation: '기본 규칙',
  CatalogSection.component: '컴포넌트',
};

class CatalogPage extends StatefulWidget {
  const CatalogPage({
    super.key,
    required this.dark,
    required this.onThemeChanged,
  });

  final bool dark;
  final ValueChanged<bool> onThemeChanged;

  @override
  State<CatalogPage> createState() => _CatalogPageState();
}

/// One screen, no page scroll: the left panel holds the title, the section
/// switch and the entry chips; the right side holds the phone preview scaled
/// to the remaining height. Narrow windows keep the preview and move the entry
/// list into a drawer.
class _CatalogPageState extends State<CatalogPage> {
  CatalogEntry selected = CatalogEntry.start;

  void _select(CatalogEntry entry) => setState(() => selected = entry);

  @override
  Widget build(BuildContext context) {
    final colors = ImHereColors.of(context);
    final wide = MediaQuery.sizeOf(context).width >= 900;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              'assets/app-logo.svg',
              width: 23,
              height: 23,
              semanticsLabel: 'ImHere 로고',
            ),
            const SizedBox(width: 10),
            ImHereLogo(scale: 5 / 7, caption: wide ? 'Design' : null),
          ],
        ),
        backgroundColor: colors.background,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            tooltip: widget.dark ? '밝은 화면 보기' : '어두운 화면 보기',
            icon: Icon(
              widget.dark
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
            ),
            onPressed: () => widget.onThemeChanged(!widget.dark),
          ),
        ],
      ),
      drawer: wide
          ? null
          : Drawer(
              child: SafeArea(
                child: Builder(
                  builder: (drawerContext) => CatalogNavigation(
                    selected: selected,
                    onSelected: (entry) {
                      _select(entry);
                      Navigator.pop(drawerContext);
                    },
                  ),
                ),
              ),
            ),
      body: wide
          ? Padding(
              padding: const EdgeInsets.fromLTRB(48, 16, 48, 24),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 520),
                        child: _SidePanel(
                          selected: selected,
                          onSelected: _select,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                  Expanded(
                    child: Center(child: DevicePreview(entry: selected)),
                  ),
                ],
              ),
            )
          : Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: CatalogContent(entry: selected),
            ),
    );
  }
}

class _SidePanel extends StatelessWidget {
  const _SidePanel({required this.selected, required this.onSelected});

  final CatalogEntry selected;
  final ValueChanged<CatalogEntry> onSelected;

  @override
  Widget build(BuildContext context) {
    final sections = CatalogSection.values;
    final entries = CatalogEntry.values
        .where((entry) => entry.section == selected.section)
        .toList();
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            selected.title,
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 8),
          _FixedDescription(
            selected: selected,
            builder: (text) => ImHereParagraph(text: text, muted: true),
          ),
          const SizedBox(height: 24),
          const ImHereBorder(),
          const SizedBox(height: 16),
          _NoMotion(
            child: ImHereSegmentedControl(
              labels: [for (final s in sections) _sectionLabels[s]!],
              index: sections.indexOf(selected.section),
              onChanged: (i) => onSelected(
                CatalogEntry.values.firstWhere(
                  (entry) => entry.section == sections[i],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          _NoMotion(
            child: Wrap(
              spacing: 8,
              children: [
                for (final entry in entries)
                  ImHereChip(
                    key: ValueKey(entry),
                    label: entry.title,
                    selected: entry == selected,
                    onChanged: (_) => onSelected(entry),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Description slot sized by the longest description of every entry, so what
/// sits below it never shifts when the selection changes. Every description is
/// laid out invisibly; only the selected one is shown.
class _FixedDescription extends StatelessWidget {
  const _FixedDescription({required this.selected, required this.builder});

  final CatalogEntry selected;
  final Widget Function(String text) builder;

  @override
  Widget build(BuildContext context) => SizedBox(
    key: const Key('catalog-description'),
    width: double.infinity,
    child: Stack(
      alignment: Alignment.topLeft,
      children: [
        for (final entry in CatalogEntry.values)
          Visibility(
            visible: entry == selected,
            maintainSize: true,
            maintainAnimation: true,
            maintainState: true,
            maintainSemantics: false,
            child: builder(entry.description),
          ),
      ],
    ),
  );
}

/// Switching sections swaps whole groups of controls, so their color
/// transitions would only read as flicker here. Components honor
/// `disableAnimations`, which is also what the system accessibility setting
/// sets.
class _NoMotion extends StatelessWidget {
  const _NoMotion({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => MediaQuery(
    data: MediaQuery.of(context).copyWith(disableAnimations: true),
    child: child,
  );
}

/// Entry list for the narrow-window drawer.
class CatalogNavigation extends StatelessWidget {
  const CatalogNavigation({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final CatalogEntry selected;
  final ValueChanged<CatalogEntry> onSelected;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      Text('디자인 시스템', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 20),
      for (final section in CatalogSection.values) ...[
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            _sectionLabels[section]!,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        for (final entry in CatalogEntry.values.where(
          (entry) => entry.section == section,
        ))
          _item(context, entry),
      ],
    ],
  );

  Widget _item(BuildContext context, CatalogEntry entry) => ListTile(
    title: Text(entry.title),
    dense: true,
    selected: selected == entry,
    selectedTileColor: ImHereColors.of(context).surfaceSubtle,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    onTap: () => onSelected(entry),
  );
}

/// Title, description and a phone preview that takes the remaining height.
/// Needs a bounded height.
class CatalogContent extends StatelessWidget {
  const CatalogContent({super.key, required this.entry});

  final CatalogEntry entry;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(entry.title, style: Theme.of(context).textTheme.headlineLarge),
        const SizedBox(height: 4),
        _FixedDescription(
          selected: entry,
          builder: (text) => Text(
            text,
            maxLines: 6,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: ImHereColors.of(context).textMuted,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: Center(child: DevicePreview(entry: entry)),
        ),
      ],
    );
  }
}
