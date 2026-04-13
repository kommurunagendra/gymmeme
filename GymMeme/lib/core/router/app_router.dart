import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/archetypes/screens/quiz_screen.dart';
import '../../features/archetypes/screens/archetype_result_screen.dart';
import '../../features/meme_creator/screens/template_grid_screen.dart';
import '../../features/meme_creator/screens/meme_canvas_screen.dart';
import '../../features/activity_log/screens/daily_log_screen.dart';
import '../../features/activity_log/screens/weekly_report_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../widgets/main_scaffold.dart';

class AppRoutes {
  static const String home = '/';
  static const String quiz = '/quiz';
  static const String archetypeResult = '/archetype-result';
  static const String templateGrid = '/template-grid';
  static const String memeCanvas = '/meme-canvas';
  static const String dailyLog = '/daily-log';
  static const String weeklyReport = '/weekly-report';
  static const String profile = '/profile';
}

final appRouterProvider = Provider<RouterConfig<Object>>((_) => AppRouter());

class AppRouter extends RouterConfig<Object> {
  AppRouter()
      : super(
          routerDelegate: _Delegate(),
          routeInformationParser: _Parser(),
        );
}

class _Delegate extends RouterDelegate<Object>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin {
  @override
  final navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) => Navigator(
        key: navigatorKey,
        initialRoute: AppRoutes.home,
        onGenerateRoute: _onGenerateRoute,
      );

  @override
  Future<void> setNewRoutePath(Object configuration) async {}
}

class _Parser extends RouteInformationParser<Object> {
  @override
  Future<Object> parseRouteInformation(RouteInformation info) async =>
      info.uri.toString();
}

Route<dynamic> _onGenerateRoute(RouteSettings settings) {
  Widget page;
  switch (settings.name) {
    case AppRoutes.quiz:
      page = const QuizScreen();
    case AppRoutes.archetypeResult:
      final args = settings.arguments as Map<String, dynamic>;
      page = ArchetypeResultScreen(
        archetypeId: args['archetypeId'] as String,
        scores: Map<String, int>.from(args['scores'] as Map),
      );
    case AppRoutes.templateGrid:
      page = const TemplateGridScreen();
    case AppRoutes.memeCanvas:
      final args = settings.arguments as Map<String, dynamic>? ?? {};
      page = MemeCanvasScreen(
        templatePath: args['templatePath'] as String?,
        imagePath: args['imagePath'] as String?,
      );
    case AppRoutes.dailyLog:
      page = const DailyLogScreen();
    case AppRoutes.weeklyReport:
      page = const WeeklyReportScreen();
    case AppRoutes.profile:
      page = const ProfileScreen();
    default:
      page = const MainScaffold();
  }
  return MaterialPageRoute(builder: (_) => page, settings: settings);
}
