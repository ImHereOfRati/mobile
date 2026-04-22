import 'package:flutter/material.dart';

class InitializationErrorApp extends StatelessWidget {
  const InitializationErrorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(body: _buildBody()),
    );
  }

  Widget _buildBody() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Center(child: _buildContent()),
    );
  }

  Widget _buildContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.wifi_off_rounded, size: 64, color: Colors.grey),
        const SizedBox(height: 24),
        _buildTitle(),
        const SizedBox(height: 12),
        _buildDescription(),
      ],
    );
  }

  Widget _buildTitle() {
    return const Text(
      '인터넷 연결을 확인해주세요',
      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildDescription() {
    return const Text(
      '앱을 실행하기 위해 네트워크 연결이 필요합니다.\n연결 상태를 확인하고 앱을 다시 실행해주세요.',
      textAlign: TextAlign.center,
      style: TextStyle(color: Colors.grey),
    );
  }
}
