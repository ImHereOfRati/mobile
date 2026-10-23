import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:iamhere/components/components.dart';

import 'phone_screens.dart';
import 'scroll_scene.dart';

const _wideBreakpoint = 900.0;

bool _isWide(BuildContext context) =>
    MediaQuery.sizeOf(context).width >= _wideBreakpoint;

/// Keeps explicit line breaks authoritative: the text is laid out unwrapped
/// and only scaled down if a line is wider than the space, so lines never
/// re-wrap at an awkward spot.
class FitLines extends StatelessWidget {
  const FitLines({
    super.key,
    required this.child,
    this.alignment = Alignment.center,
  });

  final Widget child;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) =>
      FittedBox(fit: BoxFit.scaleDown, alignment: alignment, child: child);
}

/// Scene 1: headline fades away while the phone rises to the center.
class HeroScene extends StatelessWidget {
  const HeroScene({
    super.key,
    required this.progress,
    required this.viewportHeight,
    required this.onDownloadTap,
  });

  final double progress;
  final double viewportHeight;
  final VoidCallback onDownloadTap;

  @override
  Widget build(BuildContext context) {
    final colors = ImHereColors.of(context);
    final wide = _isWide(context);
    final vp = viewportHeight;
    final phoneHeight = math.min(vp * (wide ? 0.78 : 0.62), 680.0);
    final startTop = vp * (wide ? 0.64 : 0.7);
    final endTop = (vp - phoneHeight) / 2 + 12;
    final top =
        startTop + (endTop - startTop) * easeOut(span(progress, 0, 0.8));
    final textOpacity = 1 - span(progress, 0.05, 0.45);
    final cardIn = easeOut(span(progress, 0.62, 0.9));

    return Stack(
      children: [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Opacity(
            opacity: textOpacity,
            child: Transform.translate(
              offset: Offset(0, -90 * span(progress, 0, 0.5)),
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, wide ? 56 : 36, 20, 0),
                child: Column(
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SvgPicture.asset(
                          'assets/app-logo.svg',
                          width: wide ? 32 : 26,
                          height: wide ? 32 : 26,
                          semanticsLabel: 'ImHere 로고',
                        ),
                        const SizedBox(width: 10),
                        const ImHereLogo(scale: 5 / 7),
                      ],
                    ),
                    SizedBox(height: wide ? 24 : 16),
                    FitLines(
                      child: Text(
                        wide
                            ? '출발할 때, 도착할 때,\n연락은 ImHere가 대신 보낼게요'
                            : '출발할 때,\n도착할 때,\n연락은 ImHere가\n대신 보낼게요',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.displayLarge
                            ?.copyWith(
                              fontFamily: 'GmarketSansHeadline',
                              fontSize: wide ? 56 : 32,
                              fontWeight: FontWeight.w700,
                              height: 1.25,
                              letterSpacing: wide ? -1.8 : -1,
                              color: colors.text,
                            ),
                      ),
                    ),
                    SizedBox(height: wide ? 32 : 20),
                    ImHereButton(
                      key: const Key('hero-download-button'),
                      label: '앱 다운로드',
                      size: ImHereButtonSize.lg,
                      onPressed: onDownloadTap,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          top: top,
          left: 0,
          right: 0,
          child: Center(
            child: PhoneFrame(
              height: phoneHeight,
              child: DetectScreen(t: span(progress, 0.4, 1)),
            ),
          ),
        ),
        if (wide) ...[
          _FloatingCard(
            alignment: const Alignment(-0.42, -0.25),
            amount: cardIn,
            fromLeft: true,
            name: '지민',
            title: '지민님이 출발했어요',
            description: '푸시 · 방금 전',
          ),
          _FloatingCard(
            alignment: const Alignment(0.42, 0.2),
            amount: cardIn,
            fromLeft: false,
            name: '엄마',
            title: '엄마에게 도착을 알렸어요',
            description: '문자 · 전달됨',
          ),
        ],
      ],
    );
  }
}

class _FloatingCard extends StatelessWidget {
  const _FloatingCard({
    required this.alignment,
    required this.amount,
    required this.fromLeft,
    required this.name,
    required this.title,
    required this.description,
  });

  final Alignment alignment;
  final double amount;
  final bool fromLeft;
  final String name;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final colors = ImHereColors.of(context);
    return Align(
      alignment: alignment,
      child: Opacity(
        opacity: amount,
        child: Transform.translate(
          offset: Offset((fromLeft ? -1 : 1) * 60 * (1 - amount), 0),
          child: Container(
            width: 300,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(ImHereRadius.lg),
              boxShadow: [
                BoxShadow(
                  color: colors.text.withValues(alpha: 0.08),
                  blurRadius: 32,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: ImHereSurface(
              padding: ImHereSpace.xs,
              child: ImHereListRow(
                title: title,
                description: description,
                leading: ImHereAvatar(name: name),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Scene 2: a statement whose words light up one by one with the scroll.
class StatementScene extends StatelessWidget {
  const StatementScene({super.key, required this.progress});

  final double progress;

  static const _wideLines = [
    '자고 있어서, 운전 중이라서,',
    '깜빡해서.',
    '연락을 못 한 적, 있죠?',
    '그 연락, ImHere가 대신 보낼게요.',
  ];
  static const _wideAccentFrom = 3;

  static const _compactLines = [
    '자고 있어서,',
    '운전 중이라서,',
    '깜빡해서.',
    '연락을 못 한 적,',
    '있죠?',
    '그 연락,',
    'ImHere가 대신',
    '보낼게요.',
  ];
  static const _compactAccentFrom = 5;

  @override
  Widget build(BuildContext context) {
    final colors = ImHereColors.of(context);
    final wide = _isWide(context);
    final lines = wide ? _wideLines : _compactLines;
    final accentFrom = wide ? _wideAccentFrom : _compactAccentFrom;
    final words = [
      for (var l = 0; l < lines.length; l++)
        for (final w in lines[l].split(' ')) (line: l, word: w),
    ];
    final spans = <InlineSpan>[];
    for (var i = 0; i < words.length; i++) {
      final start = 0.06 + 0.8 * i / words.length;
      final local = span(progress, start, start + 0.8 * 3 / words.length);
      final accent = words[i].line >= accentFrom;
      final lit = accent ? colors.action : colors.text;
      final isLineEnd =
          i == words.length - 1 || words[i + 1].line != words[i].line;
      spans.add(
        TextSpan(
          text: words[i].word + (isLineEnd ? '\n' : ' '),
          style: TextStyle(color: Color.lerp(colors.divider, lit, local)),
        ),
      );
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: FitLines(
            child: Text.rich(
              TextSpan(children: spans),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                fontSize: wide ? 56 : 30,
                fontWeight: FontWeight.w800,
                height: 1.4,
                letterSpacing: wide ? -1.6 : -0.8,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Step {
  const _Step(this.eyebrow, this.title, this.description, this.screen);
  final String eyebrow;
  final String title;
  final String description;
  final PhoneScreenKind screen;
}

/// Scene 3: phone stays put; copy and screen swap as the scroll advances.
class FeatureScene extends StatelessWidget {
  const FeatureScene({
    super.key,
    required this.progress,
    required this.viewportHeight,
  });

  final double progress;
  final double viewportHeight;

  static const steps = [
    _Step(
      '장소와 반경',
      '가는 곳만\n골라두세요',
      '집, 회사, 터미널.\n알리고 싶은 장소와 반경만\n정하면 준비 끝이에요.',
      PhoneScreenKind.place,
    ),
    _Step(
      '받는 사람',
      '앱이 없는 분께는\n문자로 보내요',
      'ImHere 친구에겐 푸시로,\n설치하지 않은 부모님과\n지인에겐 문자로 전해요.',
      PhoneScreenKind.contact,
    ),
    _Step(
      '자동 감지',
      '앱을 꺼둬도\n알아서 보내요',
      '이동 중에 앱을 켜둘\n필요가 없어요.\n약속한 반경에 들어서면\n자동으로 나가요.',
      PhoneScreenKind.detect,
    ),
    _Step(
      '발송 기록',
      '누구에게 갔는지\n한눈에 확인해요',
      '출발·도착 알림이\n기록으로 남아서,\n잘 전달됐는지\n언제든 다시 볼 수 있어요.',
      PhoneScreenKind.history,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final wide = _isWide(context);
    final scaled = (progress * steps.length).clamp(0.0, steps.length - 0.0001);
    final index = scaled.floor();
    final local = scaled - index;
    final step = steps[index];
    final animate = !MediaQuery.disableAnimationsOf(context);
    final fade = animate ? const Duration(milliseconds: 320) : Duration.zero;

    final copy = _StepCopy(
      key: const Key('feature-copy'),
      step: step,
      index: index,
      scaled: scaled,
      duration: fade,
      wide: wide,
    );
    final phoneHeight = wide
        ? math.min(viewportHeight * 0.84, 700.0)
        : math.min(viewportHeight * 0.58, 520.0);
    final phone = AnimatedSwitcher(
      duration: fade,
      child: KeyedSubtree(
        key: ValueKey(index),
        child: PhoneFrame(
          height: phoneHeight,
          child: PhoneScreen(kind: step.screen, t: local),
        ),
      ),
    );

    if (wide) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1120),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Row(
              children: [
                Expanded(child: copy),
                const SizedBox(width: 48),
                phone,
                const SizedBox(width: 48),
              ],
            ),
          ),
        ),
      );
    }
    return Column(
      children: [
        Padding(padding: const EdgeInsets.fromLTRB(24, 28, 24, 0), child: copy),
        Expanded(
          child: ClipRect(
            child: OverflowBox(
              alignment: Alignment.topCenter,
              minHeight: 0,
              maxHeight: phoneHeight,
              child: Padding(
                padding: const EdgeInsets.only(top: 20),
                child: phone,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _StepCopy extends StatelessWidget {
  const _StepCopy({
    super.key,
    required this.step,
    required this.index,
    required this.scaled,
    required this.duration,
    required this.wide,
  });

  final _Step step;
  final int index;
  final double scaled;
  final Duration duration;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final colors = ImHereColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: wide
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < FeatureScene.steps.length; i++) ...[
              if (i > 0) const SizedBox(width: 6),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: (scaled - i).clamp(0.0, 1.0),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: colors.action,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
        SizedBox(height: wide ? 32 : 16),
        AnimatedSwitcher(
          duration: duration,
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween(
                begin: const Offset(0, 0.12),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          ),
          child: Column(
            key: ValueKey(index),
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: wide
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.center,
            children: [
              Text(
                step.eyebrow,
                style: textTheme.titleMedium?.copyWith(
                  fontSize: wide ? 18 : 15,
                  color: colors.action,
                ),
              ),
              SizedBox(height: wide ? 14 : 8),
              FitLines(
                alignment: wide ? Alignment.centerLeft : Alignment.center,
                child: Text(
                  step.title,
                  textAlign: wide ? TextAlign.start : TextAlign.center,
                  style: textTheme.displayLarge?.copyWith(
                    fontSize: wide ? 48 : 28,
                    fontWeight: FontWeight.w800,
                    height: 1.25,
                    letterSpacing: wide ? -1.4 : -0.6,
                    color: colors.text,
                  ),
                ),
              ),
              SizedBox(height: wide ? 20 : 10),
              FitLines(
                alignment: wide ? Alignment.centerLeft : Alignment.center,
                child: Text(
                  step.description,
                  textAlign: wide ? TextAlign.start : TextAlign.center,
                  style: textTheme.bodyLarge?.copyWith(
                    fontSize: wide ? 18 : 15,
                    height: wide ? 1.6 : 1.5,
                    color: colors.textMuted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Privacy promises as three big numbers that count up on entry.
class TrustSection extends StatelessWidget {
  const TrustSection({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = ImHereColors.of(context);
    final wide = _isWide(context);
    final textTheme = Theme.of(context).textTheme;
    final cards = [
      const _TrustCard(
        value: 0,
        unit: '번',
        title: '실시간 위치 추적',
        description: '정해둔 순간에만\n소식을 전해요.',
      ),
      const _TrustCard(
        value: 2,
        unit: '가지',
        title: '전달 방법',
        description: '앱 친구에겐 푸시로,\n앱이 없는 분께는\n문자로 보내요.',
      ),
      const _TrustCard(
        value: 1,
        unit: '번',
        title: '일회성 알림은 한 번만',
        description: '보내고 나면 알림이\n자동으로 꺼져서\n또 신경 쓸 일이 없어요.',
      ),
    ];
    return ColoredBox(
      color: colors.background,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1120),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: wide ? 32 : 20,
              vertical: wide ? 140 : 72,
            ),
            child: Column(
              children: [
                Reveal(
                  child: FitLines(
                    child: Text(
                      '필요한 순간에만\n알려요',
                      textAlign: TextAlign.center,
                      style: textTheme.displayLarge?.copyWith(
                        fontSize: wide ? 52 : 30,
                        fontWeight: FontWeight.w800,
                        height: 1.25,
                        letterSpacing: wide ? -1.6 : -0.8,
                        color: colors.text,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: wide ? 72 : 36),
                if (wide)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var i = 0; i < cards.length; i++) ...[
                        if (i > 0) const SizedBox(width: 20),
                        Expanded(
                          child: Reveal(
                            delay: Duration(milliseconds: 140 * i),
                            child: cards[i],
                          ),
                        ),
                      ],
                    ],
                  )
                else
                  for (var i = 0; i < cards.length; i++) ...[
                    if (i > 0) const SizedBox(height: 14),
                    Reveal(child: cards[i]),
                  ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TrustCard extends StatelessWidget {
  const _TrustCard({
    required this.value,
    required this.unit,
    required this.title,
    required this.description,
  });

  final int value;
  final String unit;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final colors = ImHereColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    return SizedBox(
      width: double.infinity,
      child: ImHereSurface(
        padding: ImHereSpace.lg,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 252),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RevealBuilder(
                builder: (context, visible) => TweenAnimationBuilder<double>(
                  duration: MediaQuery.disableAnimationsOf(context)
                      ? Duration.zero
                      : const Duration(milliseconds: 900),
                  curve: Curves.easeOutCubic,
                  tween: Tween(begin: 0, end: visible ? value.toDouble() : 0),
                  builder: (context, v, _) => Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '${v.round()}',
                          style: TextStyle(
                            fontSize: 64,
                            height: 1.1,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -2,
                            color: colors.action,
                          ),
                        ),
                        TextSpan(
                          text: unit,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: colors.action,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              FitLines(
                alignment: Alignment.centerLeft,
                child: Text(title, style: textTheme.titleLarge),
              ),
              const SizedBox(height: 8),
              FitLines(
                alignment: Alignment.centerLeft,
                child: Text(
                  description,
                  style: textTheme.bodyMedium?.copyWith(
                    height: 1.6,
                    color: colors.textMuted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Closing call to action.
class CtaSection extends StatelessWidget {
  const CtaSection({super.key, required this.onDownloadTap});

  final VoidCallback onDownloadTap;

  @override
  Widget build(BuildContext context) {
    final colors = ImHereColors.of(context);
    final wide = _isWide(context);
    return ColoredBox(
      color: colors.background,
      child: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 24,
            vertical: wide ? 160 : 96,
          ),
          child: Reveal(
            child: Column(
              children: [
                FitLines(
                  child: Text(
                    '이제 연락은\nImHere에게',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      fontSize: wide ? 64 : 36,
                      fontWeight: FontWeight.w800,
                      height: 1.25,
                      letterSpacing: wide ? -2 : -1,
                      color: colors.text,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const SizedBox(height: 40),
                ImHereButton(
                  key: const Key('cta-download-button'),
                  label: '앱 다운로드',
                  size: ImHereButtonSize.lg,
                  onPressed: onDownloadTap,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
