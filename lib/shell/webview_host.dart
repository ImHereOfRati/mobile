import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iamhere/shell/bridge/bridge_event_emitter.dart';
import 'package:iamhere/shell/bridge/bridge_rpc_server.dart';
import 'package:iamhere/shell/shell_event_coordinator.dart';
import 'package:iamhere/shell/view/fatal_error_view.dart';
import 'package:iamhere/shell/view/force_update_view.dart';
import 'package:iamhere/shell/view/offline_view.dart';
import 'package:iamhere/shell/view/splash_view.dart';
import 'package:webview_flutter/webview_flutter.dart';

typedef ConnectivityProbe = Future<bool> Function();

enum WebViewHostState { loading, ready, offline, forceUpdate, fatalError }

class WebViewHost extends StatefulWidget {
  final Uri initialUrl;
  final BridgeRpcServer rpcServer;
  final ConnectivityProbe isOnline;
  final bool forceUpdate;
  final VoidCallback? onUpdate;
  final VoidCallback? onExit;

  const WebViewHost({
    super.key,
    required this.initialUrl,
    required this.rpcServer,
    required this.isOnline,
    this.forceUpdate = false,
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..addJavaScriptChannel(
        'ImHereBridge',
        onMessageReceived: (message) {
          unawaited(_handleBridgeMessage(message.message));
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) => _pageReady(),
          onWebResourceError: (error) {
            if (error.isForMainFrame == false) return;
            unawaited(_handleLoadFailure());
          },
        ),
      );
    _emitter = BridgeEventEmitter(_controller.runJavaScript);
    _events = ShellEventCoordinator(_emitter);

    if (widget.forceUpdate) {
      _state = WebViewHostState.forceUpdate;
    } else {
      unawaited(_load());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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
        WebViewHostState.loading => const ShellSplashView(),
        WebViewHostState.ready => SafeArea(
          child: WebViewWidget(controller: _controller),
        ),
        WebViewHostState.offline => ShellOfflineView(onRetry: _load),
        WebViewHostState.forceUpdate => ShellForceUpdateView(
          onUpdate: widget.onUpdate ?? () {},
        ),
        WebViewHostState.fatalError => ShellFatalErrorView(onRetry: _load),
      },
    );
  }
}
