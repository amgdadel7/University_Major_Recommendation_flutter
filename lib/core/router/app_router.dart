import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/home/presentation/pages/main_page.dart';
import '../../features/grades/presentation/pages/grades_page.dart';
import '../../features/survey/presentation/pages/interests_survey_page.dart';
import '../../features/survey/presentation/pages/goals_survey_page.dart';
import '../../features/survey/presentation/pages/learning_style_survey_page.dart';
import '../../features/recommendations/presentation/pages/major_details_page.dart';
import '../../features/universities/presentation/pages/university_details_page.dart';
import '../../features/applications/presentation/pages/application_form_page.dart';
import '../../features/applications/presentation/pages/application_details_page.dart';
import '../../features/profile/presentation/pages/settings_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/splash',
    debugLogDiagnostics: true,
    routes: [
      // Splash
      GoRoute(
        path: '/splash',
        name: 'splash',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const SplashPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      ),
      
      // Auth Routes
      GoRoute(
        path: '/login',
        name: 'login',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const LoginPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            );
          },
        ),
      ),
      
      GoRoute(
        path: '/register',
        name: 'register',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const RegisterPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            );
          },
        ),
      ),
      
      // Main App Routes with Bottom Navigation
      GoRoute(
        path: '/',
        name: 'main',
        builder: (context, state) => const MainPage(),
      ),
      
      // Grades
      GoRoute(
        path: '/grades',
        name: 'grades',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const GradesPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      ),
      
      // Survey Routes
      GoRoute(
        path: '/survey/interests',
        name: 'interests_survey',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const InterestsSurveyPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            );
          },
        ),
      ),
      
      GoRoute(
        path: '/survey/goals',
        name: 'goals_survey',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const GoalsSurveyPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            );
          },
        ),
      ),
      
      GoRoute(
        path: '/survey/learning-style',
        name: 'learning_style_survey',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const LearningStyleSurveyPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            );
          },
        ),
      ),
      
      // Major Details
      GoRoute(
        path: '/major/:id',
        name: 'major_details',
        pageBuilder: (context, state) {
          final majorId = state.pathParameters['id']!;
          return CustomTransitionPage(
            key: state.pageKey,
            child: MajorDetailsPage(majorId: majorId),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          );
        },
      ),
      
      // University Details
      GoRoute(
        path: '/university/:id',
        name: 'university_details',
        pageBuilder: (context, state) {
          final universityId = state.pathParameters['id']!;
          return CustomTransitionPage(
            key: state.pageKey,
            child: UniversityDetailsPage(universityId: universityId),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          );
        },
      ),
      
      // Application
      GoRoute(
        path: '/apply/:universityId/:majorId',
        name: 'application',
        pageBuilder: (context, state) {
          final universityId = state.pathParameters['universityId']!;
          final majorId = state.pathParameters['majorId']!;
          return CustomTransitionPage(
            key: state.pageKey,
            child: ApplicationFormPage(
              universityId: universityId,
              majorId: majorId,
            ),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.0, 1.0),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              );
            },
          );
        },
      ),
      
      // Application Details
      GoRoute(
        path: '/application/:id',
        name: 'application_details',
        pageBuilder: (context, state) {
          final applicationId = state.pathParameters['id']!;
          return CustomTransitionPage(
            key: state.pageKey,
            child: ApplicationDetailsPage(applicationId: applicationId),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          );
        },
      ),
      
      // Edit Application
      GoRoute(
        path: '/application/edit/:id',
        name: 'edit_application',
        pageBuilder: (context, state) {
          final applicationId = state.pathParameters['id']!;
          final application = state.extra;
          return CustomTransitionPage(
            key: state.pageKey,
            child: ApplicationFormPage(
              applicationId: applicationId,
              application: application,
            ),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.0, 1.0),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              );
            },
          );
        },
      ),
      
      // Profile
      GoRoute(
        path: '/profile',
        name: 'profile',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const ProfilePage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      ),
      
      // Settings
      GoRoute(
        path: '/settings',
        name: 'settings',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const SettingsPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            );
          },
        ),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Error: ${state.error}'),
      ),
    ),
  );
}

