import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iamhere/shell/bridge/bridge_event_emitter.dart';
import 'package:iamhere/shell/bridge/bridge_rpc_server.dart';
import 'package:iamhere/shell/shell_event_coordinator.dart';
import 'package:iamhere/shell/view/native_app_shell.dart';
import 'package:iamhere/shell/view/shell_status_view.dart';
import 'package:webview_flutter/webview_flutter.dart';

typedef ConnectivityProbe = Future<bool> Function();

enum WebViewHostState { loading, ready, offline, forceUpdate, fatalError }

class WebViewHost extends StatefulWidget {
  final Uri initialUrl;
  final BridgeRpcServer rpcServer;
  final ConnectivityProbe isOnline;
  final bool forceUpdate;
  final Stream<String>? pushPaths;
  final VoidCallback? onUpdate;
  final VoidCallback? onExit;

  const WebViewHost({
    super.key,
    required this.initialUrl,
    required this.rpcServer,
    required this.isOnline,
    this.forceUpdate = false,
    this.pushPaths,
    this.onUpdate,
    this.onExit,
  });

  @override
  State<WebViewHost> createState() => _WebViewHostState();
}

class _WebViewHostState extends State<WebViewHost> with WidgetsBindingObserver {
  late final WebViewController _controller;
  late final BridgeEventEmitter _emitter;
  late final ShellEventCoordinator _events;
  WebViewHostState _state = WebViewHostState.loading;
  StreamSubscription<String>? _pushSubscription;
  final List<String> _pendingPushPaths = [];
  late NativeShellPage _page;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _page = NativeShellPage.fromLocation(widget.initialUrl.toString());
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..addJavaScriptChannel(
        'ImHereBridge',
        onMessageReceived: (message) {
          unawaited(_handleBridgeMessage(message.message));
        },
      )
      ..addJavaScriptChannel(
        'ImHereShell',
        onMessageReceived: _handleShellMessage,
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) => _pageReady(),
          onUrlChange: (change) {
            final url = change.url;
            if (url != null) _updatePage(url);
          },
          onWebResourceError: (error) {
            if (error.isForMainFrame == false) return;
            unawaited(_handleLoadFailure());
          },
        ),
      );
    _emitter = BridgeEventEmitter(_controller.runJavaScript);
    _events = ShellEventCoordinator(_emitter);
    _pushSubscription = widget.pushPaths?.listen((path) {
      if (_state == WebViewHostState.ready) {
        unawaited(_events.pushPathOpened(path));
      } else {
        _pendingPushPaths.add(path);
      }
    });

    if (widget.forceUpdate) {
      _state = WebViewHostState.forceUpdate;
    } else {
      unawaited(_load());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_pushSubscription?.cancel());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        _state == WebViewHostState.ready) {
      unawaited(_events.appResumed());
    }
  }

  Future<void> _load() async {
    if (mounted) setState(() => _state = WebViewHostState.loading);
    if (!await widget.isOnline()) {
      if (mounted) setState(() => _state = WebViewHostState.offline);
      return;
    }
    try {
      await _controller.loadRequest(widget.initialUrl);
    } catch (_) {
      await _handleLoadFailure();
    }
  }

  void _pageReady() {
    if (!mounted) return;
    setState(() => _state = WebViewHostState.ready);
    final brightness = MediaQuery.platformBrightnessOf(context);
    unawaited(
      _events.themeChanged(brightness == Brightness.dark ? 'dark' : 'light'),
    );
    for (final path in List<String>.from(_pendingPushPaths)) {
      unawaited(_events.pushPathOpened(path));
    }
    _pendingPushPaths.clear();
  }

  Future<void> _handleLoadFailure() async {
    final online = await widget.isOnline();
    if (!mounted) return;
    setState(
      () => _state = online
          ? WebViewHostState.fatalError
          : WebViewHostState.offline,
    );
  }

  Future<void> _handleBridgeMessage(String message) async {
    final response = await widget.rpcServer.handle(message);
    await _emitter.sendMessage(response);
  }

  void _handleShellMessage(JavaScriptMessage message) {
    try {
      final decoded = jsonDecode(message.message);
      if (decoded is! Map<String, dynamic>) return;
      final path = decoded['path'];
      final title = decoded['title'];
      if (path is! String || title is! String) return;
      _updatePage(path, title: title);
    } on FormatException {
      return;
    }
  }

  void _updatePage(String location, {String? title}) {
    if (!mounted) return;
    final next = NativeShellPage.fromLocation(location, title: title);
    if (next.path == _page.path && next.title == _page.title) return;
    setState(() => _page = next);
  }

  Future<void> _navigate(String path) async {
    _updatePage(path);
    final fallbackUrl = widget.initialUrl.resolve(
      path.startsWith('/') ? path.substring(1) : path,
    );
    final script =
        '''
      (() => {
        if (typeof window.__imhereNavigate === 'function') {
          window.__imhereNavigate(${jsonEncode(path)});
          return;
        }
        window.location.assign(${jsonEncode(fallbackUrl.toString())});
      })();
    ''';
    await _controller.runJavaScript(script);
  }

  Future<void> _handleBack() async {
    if (await _controller.canGoBack()) {
      await _controller.goBack();
      return;
    }
    await _events.androidBackPressed();
    if (widget.onExit != null) {
      widget.onExit!();
    } else {
      await SystemNavigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<Object?>(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_handleBack());
      },
      child: switch (_state) {
        WebViewHostState.loading => const ShellStatusView.splash(),
        WebViewHostState.ready => NativeAppShell(
          page: _page,
          onNavigate: (path) => unawaited(_navigate(path)),
          onBack: () => unawaited(_handleBack()),
          child: WebViewWidget(controller: _controller),
        ),
        WebViewHostState.offline => ShellStatusView.offline(onRetry: _load),
        WebViewHostState.forceUpdate => ShellStatusView.forceUpdate(
          onUpdate: widget.onUpdate ?? () {},
        ),
        WebViewHostState.fatalError => ShellStatusView.fatalError(
          onRetry: _load,
        ),
      },
    );
  }
}
