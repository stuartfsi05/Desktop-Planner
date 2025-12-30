import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';

import 'package:amanda_planner/core/database/database_helper.dart';
import 'package:amanda_planner/features/planner/providers/task_provider.dart';
import 'package:amanda_planner/features/planner/screens/planner_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  const WindowOptions windowOptions = WindowOptions(
    size: Size(1280, 800),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.normal,
  );
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  DatabaseHelper.setupDatabaseFactory();

  runApp(const DesktopPlannerApp());
}

class DesktopPlannerApp extends StatelessWidget {
  const DesktopPlannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => TaskProvider())],
      child: MaterialApp(
        title: "Amanda's Pro Planner",
        debugShowCheckedModeBanner: false,

        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          FlutterQuillLocalizations.delegate,
        ],
        supportedLocales: const [Locale('pt', 'BR')],

        theme: ThemeData(
          useMaterial3: true,
          primaryColor: const Color(0xFF24555D),
          scaffoldBackgroundColor: const Color(0xFFDAD8D3),
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF24555D),
            secondary: const Color(0xFFEA9DAB),
            surface: Colors.white,
          ),
          textTheme: GoogleFonts.latoTextTheme(),
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
