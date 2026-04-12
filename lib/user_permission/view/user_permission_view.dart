import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iamhere/router/app_routes.dart';
import 'package:iamhere/user_permission/view_model/user_permission_view_model.dart';

import 'widgets/finish_page.dart';
import 'widgets/intro_page.dart';
import 'widgets/permission_page.dart';

class UserPermissionView extends ConsumerStatefulWidget {
  const UserPermissionView({super.key});

  @override
  ConsumerState<UserPermissionView> createState() => _UserPermissionViewState();
}

class _UserPermissionViewState extends ConsumerState<UserPermissionView> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _onFinish() {
    AppRoutes.goToAuth(context);
  }

  @override
  Widget build(BuildContext context) {
    final asyncPermissionState = ref.watch(userPermissionViewModelProvider);

    return asyncPermissionState.when(
      loading: () => const Scaffold(
        backgroundColor: Color(0xFFF5F5F7),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF0071E3)),
        ),
      ),
      error: (error, _) => Scaffold(
        backgroundColor: const Color(0xFFF5F5F7),
        body: Center(
          child: Text(
            '초기화 오류: $error',
            style: const TextStyle(
              fontFamily: 'BMHANNAAir',
              color: Color(0xFF1D1D1F),
            ),
          ),
        ),
      ),
      data: (permissionItems) {
        final totalPages = permissionItems.length + 2;

        return Scaffold(
          backgroundColor: const Color(0xFFF5F5F7),
          body: SafeArea(
            child: Column(
              children: [
                _buildProgressBar(totalPages),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: totalPages,
                    onPageChanged: (index) =>
                        setState(() => _currentPage = index),
                    itemBuilder: (context, index) {
                      if (index == 0) return IntroPage(onNext: _nextPage);
                      if (index == totalPages - 1) {
                        return FinishPage(onFinish: _onFinish);
                      }
                      return PermissionPage(
                        pageIndex: _currentPage,
                        item: permissionItems[index - 1],
                        onNext: _nextPage,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProgressBar(int totalPages) {
    final progress = totalPages > 0 ? (_currentPage + 1) / totalPages : 0.0;

    return Container(
      height: 3.h,
      color: const Color(0xFFE5E5EA),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: progress,
        child: Container(color: const Color(0xFF0071E3)),
      ),
    );
  }
}
