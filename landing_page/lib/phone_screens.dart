import 'package:flutter/material.dart';
import 'package:iamhere/components/components.dart';

/// Logical size of the phone content (Galaxy S26, 360 × 780 minus bezel).
const kPhoneScreen = Size(360, 760);
const _bezel = 10.0;
const _statusInset = 28.0;
const _gestureInset = 16.0;

/// Phone shell that lays its child out at a true 360 dp width, then scales the
/// whole device to [height]. Components keep their real proportions because
/// [ImHereMetrics] reads the overridden 360 dp viewport.
class PhoneFrame extends StatelessWidget {
  const PhoneFrame({super.key, required this.height, required this.child});

  final double height;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = ImHereColors.of(context);
    const outer = Size(360 + _bezel * 2, 760 + _bezel * 2);
    final screenData = MediaQuery.of(context).copyWith(
      size: kPhoneScreen,
      padding: const EdgeInsets.only(top: _statusInset, bottom: _gestureInset),
      viewPadding: const EdgeInsets.only(
        top: _statusInset,
        bottom: _gestureInset,
      ),
      textScaler: TextScaler.noScaling,
    );
    return SizedBox(
      width: height * outer.width / outer.height,
      height: height,
      child: FittedBox(
        fit: BoxFit.contain,
        child: Container(
          width: outer.width,
          height: outer.height,
          padding: const EdgeInsets.all(_bezel),
          decoration: BoxDecoration(
            color: ImHerePalette.neutral1000,
            borderRadius: BorderRadius.circular(48),
            boxShadow: [
              BoxShadow(
                color: colors.text.withValues(alpha: 0.14),
                blurRadius: 60,
                offset: const Offset(0, 24),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(38),
            child: MediaQuery(
              data: screenData,
              child: Material(
                color: colors.background,
                child: Stack(
                  children: [
                    Positioned.fill(child: child),
                    const Positioned(
                      top: 10,
                      left: 0,
                      right: 0,
                      child: Center(child: _Camera()),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Camera extends StatelessWidget {
  const _Camera();

  @override
  Widget build(BuildContext context) => Container(
    width: 12,
    height: 12,
    decoration: const BoxDecoration(
      color: ImHerePalette.neutral1000,
      shape: BoxShape.circle,
    ),
  );
}

/// The four app screens used by the scroll scenes, built from the shared
/// ImHere components.
enum PhoneScreenKind { place, contact, detect, history }

class PhoneScreen extends StatelessWidget {
  const PhoneScreen({super.key, required this.kind, this.t = 0});

  final PhoneScreenKind kind;

  /// 0 → 1 progress inside the current step; drives the live-looking parts.
  final double t;

  @override
  Widget build(BuildContext context) => _AppShell(
    navIndex: switch (kind) {
      PhoneScreenKind.place || PhoneScreenKind.detect => 0,
      PhoneScreenKind.contact => 1,
      PhoneScreenKind.history => 2,
    },
    child: switch (kind) {
      PhoneScreenKind.place => const PlaceScreen(),
      PhoneScreenKind.contact => const ContactScreen(),
      PhoneScreenKind.detect => DetectScreen(t: t),
      PhoneScreenKind.history => const HistoryScreen(),
    },
  );
}

/// The app shell from the design system: [ImHereAppHeader] pinned on top and
/// [ImHereNavigation] pinned at the bottom, with the screen in between.
class _AppShell extends StatelessWidget {
  const _AppShell({required this.navIndex, required this.child});

  final int navIndex;
  final Widget child;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      ImHereAppHeader(onNotificationTap: () {}),
      Expanded(
        child: MediaQuery.removePadding(
          context: context,
          removeTop: true,
          removeBottom: true,
          child: child,
        ),
      ),
      ImHereNavigation(
        items: const [
          ImHereNavItem(glyph: ImHereGlyph.place, label: '장소'),
          ImHereNavItem(glyph: ImHereGlyph.friends, label: '친구'),
          ImHereNavItem(glyph: ImHereGlyph.history, label: '기록'),
          ImHereNavItem(glyph: ImHereGlyph.settings, label: '설정'),
        ],
        index: navIndex,
        onChanged: (_) {},
      ),
    ],
  );
}

class PlaceScreen extends StatefulWidget {
  const PlaceScreen({super.key});

  @override
  State<PlaceScreen> createState() => _PlaceScreenState();
}

class _PlaceScreenState extends State<PlaceScreen> {
  static const _places = [
    ('우리 집', '서울 성동구 왕십리로 83', '도착 알림 · 반경 300m'),
    ('회사', '서울 강남구 테헤란로 152', '도착·출발 알림 · 반경 200m'),
  ];
  bool homeEnabled = true;
  bool workEnabled = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              ImHereSpace.gutter,
              ImHereSpace.md,
              ImHereSpace.gutter,
              ImHereSpace.xl,
            ),
            children: [
              ImHereButton(
                label: '장소 추가',
                icon: ImHereGlyph.add,
                tone: ImHereButtonTone.secondary,
                expand: true,
                onPressed: () {},
              ),
              const SizedBox(height: ImHereSpace.xl),
              const ImHereListHeader(title: '알림 켜짐'),
              ImHereSurface(
                padding: 0,
                child: _PlacePreviewRow(
                  name: _places[0].$1,
                  address: _places[0].$2,
                  condition: _places[0].$3,
                  enabled: homeEnabled,
                  onChanged: (value) => setState(() => homeEnabled = value),
                ),
              ),
              const SizedBox(height: ImHereSpace.lg),
              const ImHereListHeader(title: '알림 꺼짐'),
              ImHereSurface(
                padding: 0,
                child: _PlacePreviewRow(
                  name: _places[1].$1,
                  address: _places[1].$2,
                  condition: _places[1].$3,
                  enabled: workEnabled,
                  onChanged: (value) => setState(() => workEnabled = value),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PlacePreviewRow extends StatelessWidget {
  const _PlacePreviewRow({
    required this.name,
    required this.address,
    required this.condition,
    required this.enabled,
    required this.onChanged,
  });

  final String name;
  final String address;
  final String condition;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(ImHereSpace.md),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            ImHereAsset(glyph: ImHereGlyph.place, label: name, size: 40),
            const SizedBox(width: ImHereSpace.sm),
            Expanded(
              child: Text(name, style: Theme.of(context).textTheme.titleSmall),
            ),
            const ImHereIcon(glyph: ImHereGlyph.chevron, size: 20),
          ],
        ),
        const SizedBox(height: ImHereSpace.sm),
        Text(address, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: ImHereSpace.xs),
        Text(condition, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: ImHereSpace.xs),
        const ImHereBadge(label: '매일', tone: ImHereBadgeTone.neutral),
        const SizedBox(height: ImHereSpace.xs),
        const ImHereBorder(tone: ImHereDividerTone.subtle),
        ImHereSwitch(
          key: ValueKey('phone-place-toggle-$name'),
          label: '알림 사용',
          value: enabled,
          onChanged: onChanged,
        ),
      ],
    ),
  );
}

class ContactScreen extends StatelessWidget {
  const ContactScreen({super.key});

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Expanded(
        child: ListView(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: ImHereSpace.gutter),
          children: const [
            Row(
              children: [
                Expanded(
                  child: _FriendActionPreview(
                    glyph: ImHereGlyph.add,
                    title: '친구 찾기',
                    subtitle: '닉네임·이메일로 요청',
                  ),
                ),
                SizedBox(width: ImHereSpace.sm),
                Expanded(
                  child: _FriendActionPreview(
                    glyph: ImHereGlyph.person,
                    title: '연락처 추가',
                    subtitle: '기기에서 바로 선택',
                  ),
                ),
              ],
            ),
            SizedBox(height: ImHereSpace.sm),
            ImHereListRow(
              title: '받은 요청',
              leading: ImHereIcon(glyph: ImHereGlyph.bell, size: 22),
            ),
            ImHereBorder(tone: ImHereDividerTone.subtle),
            SizedBox(height: ImHereSpace.sm),
            ImHereListHeader(title: '친구 2명'),
            ImHereListHeader(title: '가나다'),
            ImHereListRow(
              title: '지민',
              description: 'ImHere 친구',
              leading: ImHereAvatar(name: '지민'),
            ),
            ImHereListRow(
              title: '민수',
              description: 'ImHere 친구',
              leading: ImHereAvatar(name: '민수'),
            ),
            ImHereListRow(
              title: '엄마',
              description: '010-****-1234',
              leading: ImHereAvatar(name: '엄마'),
              trailing: ImHereBadge(
                label: '연락처',
                tone: ImHereBadgeTone.neutral,
                size: ImHereBadgeSize.medium,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class _FriendActionPreview extends StatelessWidget {
  const _FriendActionPreview({
    required this.glyph,
    required this.title,
    required this.subtitle,
  });

  final ImHereGlyph glyph;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => ImHereSurface(
    padding: ImHereSpace.sm,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ImHereIcon(
          glyph: glyph,
          size: 20,
          color: ImHereColors.of(context).action,
        ),
        const SizedBox(height: ImHereSpace.xs),
        Text(title, style: Theme.of(context).textTheme.titleSmall),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: ImHereColors.of(context).textMuted,
          ),
        ),
      ],
    ),
  );
}

/// Background detection: distance shrinks with [t], and the "sent" card
/// slides in at the end.
class DetectScreen extends StatelessWidget {
  const DetectScreen({super.key, required this.t});

  final double t;

  @override
  Widget build(BuildContext context) {
    final colors = ImHereColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final remaining = (1200 * (1 - (t / 0.75).clamp(0.0, 1.0))).round();
    final arrived = t >= 0.75;
    final card = ((t - 0.75) / 0.25).clamp(0.0, 1.0);
    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: ImHereSpace.gutter),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  arrived ? '도착했어요' : '$remaining m',
                  style: textTheme.headlineLarge?.copyWith(
                    fontSize: 44,
                    height: 1.2,
                    color: arrived ? colors.action : colors.text,
                  ),
                ),
                const SizedBox(height: ImHereSpace.xs),
                Text(
                  '우리 집까지 · 반경 300m',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colors.textMuted,
                  ),
                ),
                const SizedBox(height: ImHereSpace.xl),
                Opacity(
                  opacity: card,
                  child: Transform.translate(
                    offset: Offset(0, 24 * (1 - card)),
                    child: const ImHereSurface(
                      padding: 0,
                      child: ImHereListRow(
                        title: '엄마에게 도착을 알렸어요',
                        description: '문자 전송 완료',
                        leading: Padding(
                          padding: EdgeInsets.only(left: ImHereSpace.md),
                          child: ImHereAsset(
                            glyph: ImHereGlyph.bell,
                            label: '알림',
                            size: 40,
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
      ],
    );
  }
}

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      ImHereSpace.gutter,
      ImHereSpace.xs,
      ImHereSpace.gutter,
      ImHereSpace.md,
    ),
    child: Column(
      children: const [
        Expanded(
          child: _ActivityPreviewSection(
            title: '받은 알림',
            titleText: '엄마가 도착했어요',
            body: '우리 집 · 방금 전',
          ),
        ),
        SizedBox(height: ImHereSpace.sm),
        Expanded(
          child: _ActivityPreviewSection(
            title: '친구 요청',
            titleText: '수진',
            body: '친구 요청을 보냈어요 · 오늘 09:12',
          ),
        ),
        SizedBox(height: ImHereSpace.sm),
        Expanded(
          child: _ActivityPreviewSection(
            title: '전송 기록',
            titleText: '회사에서 출발했어요',
            body: '엄마에게 문자 전송 완료 · 오늘 08:15',
            badge: '완료',
          ),
        ),
      ],
    ),
  );
}

class _ActivityPreviewSection extends StatelessWidget {
  const _ActivityPreviewSection({
    required this.title,
    required this.titleText,
    required this.body,
    this.badge,
  });

  final String title;
  final String titleText;
  final String body;
  final String? badge;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      ImHereListHeader(title: title, actionLabel: '전체 보기', onAction: () {}),
      Expanded(
        child: ImHereSurface(
          padding: ImHereSpace.sm,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      titleText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  if (badge != null) ...[
                    const SizedBox(width: ImHereSpace.xs),
                    ImHereBadge(
                      label: badge!,
                      tone: ImHereBadgeTone.success,
                      size: ImHereBadgeSize.medium,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: ImHereSpace.xxs),
              Text(
                body,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: ImHereColors.of(context).textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}
