import 'package:go_router/go_router.dart';
import 'package:iamhere/auth/view/auth_view.dart';
import 'package:iamhere/auth/view_model/auth_view_model.dart';
import 'package:iamhere/contact/view/contact_view.dart';
import 'package:iamhere/geofence/view/geofence_enroll_view.dart';
import 'package:iamhere/geofence/view/geofence_view.dart';
import 'package:iamhere/record/view/record_view.dart';
import 'package:iamhere/setting/view/setting_view.dart';
import 'package:iamhere/shared/component/view_component/default_view.dart';
import 'package:iamhere/shared/infrastructure/di/di_setup.dart';
import 'package:iamhere/terms/view/terms_detail_view.dart';
import 'package:iamhere/terms/view/terms_list_view.dart';
import 'package:iamhere/user_permission/view/user_permission_view.dart';

import 'custom_page_transition/buttom_up_transition.dart';
import 'custom_page_transition/simple_transition.dart';

final List<RouteBase> appRoutes = [
  GoRoute(
    path: '/user-permission',
    pageBuilder: (context, state) => buildPageWithSimpleTransition(
      context: context,
      state: state,
      child: const UserPermissionView(),
    ),
  ),
  GoRoute(
    path: '/auth',
    builder: (context, state) => AuthView(getIt<AuthViewModel>()),
  ),
  GoRoute(
    path: '/terms-consent',
    pageBuilder: (context, state) => buildPageWithSimpleTransition(
      context: context,
      state: state,
      child: const TermsListView(),
    ),
  ),
  GoRoute(
    path: '/terms-detail/:termId',
    pageBuilder: (context, state) => buildPageWithSimpleTransition(
      context: context,
      state: state,
      child: TermsDetailView(
        termDefinitionId: int.parse(state.pathParameters['termId']!),
      ),
    ),
  ),
  ShellRoute(
    builder: (context, state, child) => DefaultView(child: child),
    routes: [
      GoRoute(
        path: '/geofence',
        pageBuilder: (context, state) => buildPageWithSimpleTransition(
          context: context,
          state: state,
          child: const GeofenceView(),
        ),
        routes: [
          GoRoute(
            path: '/enroll',
            pageBuilder: (context, state) => buildPageWithBottomUpTransition(
              context: context,
              state: state,
              child: const GeofenceEnrollView(),
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/contact',
        pageBuilder: (context, state) => buildPageWithSimpleTransition(
          context: context,
          state: state,
          child: const ContactView(),
        ),
      ),
      GoRoute(
        path: '/record',
        pageBuilder: (context, state) => buildPageWithSimpleTransition(
          context: context,
          state: state,
          child: const RecordView(),
        ),
      ),
      GoRoute(
        path: '/setting',
        pageBuilder: (context, state) => buildPageWithSimpleTransition(
          context: context,
          state: state,
          child: const SettingView(),
        ),
      ),
    ],
  ),
];
