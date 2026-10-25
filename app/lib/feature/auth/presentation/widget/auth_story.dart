import 'dart:async';

import 'package:flutter/material.dart';
import 'package:iamhere/components/components.dart';

class AuthStory extends StatefulWidget {
  const AuthStory({super.key});

  @override
  State<AuthStory> createState() => _AuthStoryState();
}

class _AuthStoryState extends State<AuthStory> with WidgetsBindingObserver {
  Timer? _rotationTimer;
  int _sceneIndex = 0;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _isActive =
        WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncRotation();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _isActive = state == AppLifecycleState.resumed;
    _syncRotation();
  }

  void _syncRotation() {
    final shouldRotate =
        _isActive &&
        TickerMode.of(context) &&
        !MediaQuery.disableAnimationsOf(context) &&
        !MediaQuery.accessibleNavigationOf(context);
    if (!shouldRotate) {
      _rotationTimer?.cancel();
      _rotationTimer = null;
    } else {
      _rotationTimer ??= Timer.periodic(const Duration(seconds: 5), (_) {
        if (mounted) {
          setState(() => _sceneIndex = (_sceneIndex + 1) % 2);
        }
      });
    }
  }

  @override
  void dispose() {
    _rotationTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final metrics = ImHereMetrics.of(context);
    final isStatement = _sceneIndex == 0;

    return SizedBox(
      width: double.infinity,
      height: MediaQuery.textScalerOf(context).scale(metrics.resolve(224)),
      child: ClipRect(
        child: AnimatedSwitcher(
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 350),
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(0.16, 0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
              child: child,
            ),
          ),
          child: isStatement
              ? const _StatementPreview(key: ValueKey('statement'))
              : const _DetectionPreview(key: ValueKey('detection')),
        ),
      ),
    );
  }
}

class _StatementPreview extends StatelessWidget {
  const _StatementPreview({super.key});

  static const _lines = [
    '자고 있어서, 운전 중이라서,',
    '깜빡해서.',
    '연락을 못 한 적, 있죠?',
    '그 연락, ImHere가 대신 보낼게요.',
  ];

  @override
  Widget build(BuildContext context) {
    final colors = ImHereColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final words = [
      for (var line = 0; line < _lines.length; line++)
        for (final word in _lines[line].split(' ')) (line: line, text: word),
    ];

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(seconds: 5),
      builder: (context, progress, child) {
        return SizedBox(
          width: double.infinity,
          child: Text.rich(
            TextSpan(
              children: [
                for (var index = 0; index < words.length; index++)
                  TextSpan(
                    text:
                        '${words[index].text}${index == words.length - 1
                            ? ''
                            : words[index + 1].line != words[index].line
                            ? '\n'
                            : ' '}',
                    style: TextStyle(
                      color: Color.lerp(
                        colors.divider,
                        words[index].line == _lines.length - 1
                            ? colors.action
                            : colors.text,
                        ((progress - index * 0.8 / words.length) / 0.18).clamp(
                          0.0,
                          1.0,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            textAlign: TextAlign.center,
            style: textTheme.headlineLarge?.copyWith(height: 1.35),
          ),
        );
      },
    );
  }
}

class _DetectionPreview extends StatelessWidget {
  const _DetectionPreview({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = ImHereColors.of(context);
    final metrics = ImHereMetrics.of(context);
    final textTheme = Theme.of(context).textTheme;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 2400),
      builder: (context, progress, child) {
        final remaining = (1200 * (1 - (progress / 0.75).clamp(0.0, 1.0)))
            .round();
        final arrived = progress >= 0.75;
        return AnimatedSwitcher(
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 350),
          child: arrived
              ? const _ArrivalNotification(
                  key: Key('auth-arrival-notification'),
                )
              : Column(
                  key: const ValueKey('remaining-distance'),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$remaining m',
                      key: const Key('auth-detect-distance'),
                      style: textTheme.headlineLarge?.copyWith(
                        fontSize: 44,
                        height: 1.2,
                      ),
                    ),
                    SizedBox(height: metrics.resolve(ImHereSpace.xxs)),
                    Text(
                      '우리 집까지 · 반경 300m',
                      style: textTheme.bodyLarge?.copyWith(
                        color: colors.textMuted,
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}

class _ArrivalNotification extends StatelessWidget {
  const _ArrivalNotification({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = ImHereColors.of(context);
    final metrics = ImHereMetrics.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.notifications_active_rounded,
          size: metrics.resolve(36),
          color: colors.action,
        ),
        SizedBox(width: metrics.resolve(ImHereSpace.md)),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('우리 집 도착', style: textTheme.titleMedium),
            Text('엄마에게 도착을 알렸어요', style: textTheme.bodyLarge),
            Text(
              '문자 전송 완료',
              style: textTheme.bodyMedium?.copyWith(color: colors.textMuted),
            ),
          ],
        ),
      ],
    );
  }
}
