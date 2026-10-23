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
    ('우리 집', '서울 성동구 왕십리로 83', ImHereGlyph.home),
    ('회사', '서울 강남구 테헤란로 152', ImHereGlyph.place),
    ('터미널', '서울 서초구 신반포로 194', ImHereGlyph.place),
  ];
  static const _radii = ['100m', '300m', '500m'];

  String place = '우리 집';
  String radius = '300m';
  bool enabled = true;

  @override
  Widget build(BuildContext context) {
    final colors = ImHereColors.of(context);
    return Column(
      children: [
        Expanded(
          child: ListView(
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: ImHereSpace.gutter),
            children: [
              const ImHereListHeader(title: '도착을 알릴 장소'),
              for (final p in _places)
                ImHereListRow(
                  key: ValueKey('phone-place-${p.$1}'),
                  title: p.$1,
                  description: p.$2,
                  leading: ImHereAsset(glyph: p.$3, label: p.$1, size: 40),
                  trailing: place == p.$1
                      ? const ImHereBadge(
                          label: '선택됨',
                          size: ImHereBadgeSize.medium,
                        )
                      : null,
                  onTap: () => setState(() => place = p.$1),
                ),
              const SizedBox(height: ImHereSpace.md),
              const ImHereListHeader(title: '알림 반경'),
              Wrap(
                spacing: 8,
                children: [
                  for (final r in _radii)
                    ImHereChip(
                      key: ValueKey('phone-radius-$r'),
                      label: r,
                      selected: radius == r,
                      onChanged: (_) => setState(() => radius = r),
                    ),
                ],
              ),
              const SizedBox(height: ImHereSpace.md),
              ImHereSwitch(
                label: '한 번만 알리고 끄기',
                value: enabled,
                onChanged: (v) => setState(() => enabled = v),
              ),
              const SizedBox(height: ImHereSpace.sm),
              Text(
                '$place에서 $radius 안에 들어오면 알려요.',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: colors.textMuted),
              ),
              const SizedBox(height: ImHereSpace.md),
              ImHereButton(
                label: '알림 만들기',
                size: ImHereButtonSize.lg,
                expand: true,
                onPressed: () {},
              ),
            ],
          ),
        ),
      ],
    );
  }
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
            ImHereListHeader(title: '친구'),
            ImHereListRow(
              title: '지민',
              description: 'ImHere 사용 중',
              leading: ImHereAvatar(name: '지민'),
              trailing: ImHereBadge(
                label: '앱 푸시',
                size: ImHereBadgeSize.medium,
              ),
            ),
            ImHereListRow(
              title: '민수',
              description: 'ImHere 사용 중',
              leading: ImHereAvatar(name: '민수'),
              trailing: ImHereBadge(
                label: '앱 푸시',
                size: ImHereBadgeSize.medium,
              ),
            ),
            SizedBox(height: ImHereSpace.md),
            ImHereListHeader(title: '연락처'),
            ImHereListRow(
              title: '엄마',
              description: '010-****-1234',
              leading: ImHereAvatar(name: '엄마'),
              trailing: ImHereBadge(
                label: '문자',
                tone: ImHereBadgeTone.success,
                size: ImHereBadgeSize.medium,
              ),
            ),
            SizedBox(height: ImHereSpace.md),
            ImHereCallout(
              title: '앱이 없어도 괜찮아요',
              text: '설치하지 않은 분께는 도착하는 순간 문자로 전해요.',
            ),
          ],
        ),
      ),
    ],
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

  static const _rows = [
    ('엄마', '우리 집 도착', '오늘 18:42', '문자'),
    ('지민', '회사 출발', '오늘 08:15', '푸시'),
    ('민수', '터미널 도착', '어제 21:03', '푸시'),
    ('엄마', '우리 집 도착', '어제 18:37', '문자'),
  ];

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Expanded(
        child: ListView(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: ImHereSpace.gutter),
          children: [
            const ImHereListHeader(title: '최근 알림'),
            for (final r in _rows)
              ImHereListRow(
                title: '${r.$1}에게 · ${r.$2}',
                description: r.$3,
                leading: ImHereAvatar(name: r.$1),
                trailing: ImHereBadge(
                  label: '${r.$4} 전달됨',
                  tone: ImHereBadgeTone.success,
                  size: ImHereBadgeSize.medium,
                ),
              ),
          ],
        ),
      ),
    ],
  );
}
