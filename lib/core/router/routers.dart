import 'package:go_router/go_router.dart';
import 'package:iamhere/core/di/di_setup.dart';
import 'package:iamhere/core/router/app_routes.dart';
import 'package:iamhere/feature/auth/view/auth_view.dart';
import 'package:iamhere/feature/auth/view_model/auth_view_model.dart';
import 'package:iamhere/feature/friend/view/add_friend_view.dart';
import 'package:iamhere/feature/friend/view/contact_view.dart';
import 'package:iamhere/feature/friend/view/friend_request_list_view.dart';
import 'package:iamhere/feature/friend/view/friend_restriction_list_view.dart';
import 'package:iamhere/feature/geofence/view/geofence_enroll_view.dart';
import 'package:iamhere/feature/geofence/view/geofence_view.dart';
import 'package:iamhere/feature/record/view/notification_list_view.dart';
import 'package:iamhere/feature/record/view/record_friend_request_list_view.dart';
import 'package:iamhere/feature/record/view/record_view.dart';
import 'package:iamhere/feature/record/view/send_history_list_view.dart';
import 'package:iamhere/feature/setting/view/setting_view.dart';
import 'package:iamhere/feature/terms/view/terms_detail_view.dart';
import 'package:iamhere/feature/terms/view/terms_list_view.dart';
import 'package:iamhere/shared/component/view_component/default_view.dart';

import 'custom_page_transition/buttom_up_transition.dart';
import 'custom_page_transition/simple_transition.dart';

final List<RouteBase> appRoutes = [
  GoRoute(
    path: AppRoutes.auth,
    builder: (context, state) => AuthView(getIt<AuthViewModel>()),
  ),
  GoRoute(
    path: AppRoutes.termsConsent,
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
        path: AppRoutes.geofence,
        pageBuilder: (context, state) => buildPageWithSimpleTransition(
          context: context,
          state: state,
          child: const GeofenceView(),
        ),
        routes: [
          GoRoute(
            path: 'enroll',
            pageBuilder: (context, state) => buildPageWithBottomUpTransition(
              context: context,
              state: state,
              child: const GeofenceEnrollView(),
            ),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.contact,
        pageBuilder: (context, state) => buildPageWithSimpleTransition(
          context: context,
          state: state,
          child: const ContactView(),
        ),
        routes: [
          GoRoute(
            path: 'add',
            pageBuilder: (context, state) => buildPageWithSimpleTransition(
              context: context,
              state: state,
              child: const AddFriendView(),
            ),
          ),
          GoRoute(
            path: 'requests',
            pageBuilder: (context, state) => buildPageWithSimpleTransition(
              context: context,
              state: state,
              child: const FriendRequestListView(),
            ),
          ),
          GoRoute(
            path: 'restrictions',
            pageBuilder: (context, state) => buildPageWithSimpleTransition(
              context: context,
              state: state,
              child: const FriendRestrictionListView(),
            ),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.record,
        pageBuilder: (context, state) => buildPageWithSimpleTransition(
          context: context,
          state: state,
          child: const RecordView(),
        ),
        routes: [
          GoRoute(
            path: 'notifications',
            pageBuilder: (context, state) => buildPageWithSimpleTransition(
              context: context,
              state: state,
              child: const NotificationListView(),
            ),
          ),
          GoRoute(
            path: 'friend-requests',
            pageBuilder: (context, state) => buildPageWithSimpleTransition(
              context: context,
              state: state,
              child: const RecordFriendRequestListView(),
            ),
          ),
          GoRoute(
            path: 'send-history',
            pageBuilder: (context, state) => buildPageWithSimpleTransition(
              context: context,
              state: state,
              child: const SendHistoryListView(),
            ),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.setting,
        pageBuilder: (context, state) => buildPageWithSimpleTransition(
          context: context,
          state: state,
          child: const SettingView(),
        ),
      ),
    ],
  ),
];
