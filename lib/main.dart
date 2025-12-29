import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'database_helper.dart';
import 'task_provider.dart';
import 'physical_layout.dart';
import 'monthly_calendar.dart';
import 'daily_view.dart';
import 'vertical_weekly_view.dart';
import 'welcome_screen.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  WindowOptions windowOptions = const WindowOptions(
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
      providers: [
        ChangeNotifierProvider(create: (_) => TaskProvider()),
      ],
      child: MaterialApp(
        title: "Amanda's Pro Planner",
        debugShowCheckedModeBanner: false,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('pt', 'BR'),
        ],
        locale: const Locale('pt', 'BR'),
        theme: ThemeData(
          useMaterial3: true,
          primaryColor: const Color(0xFF6D28D9), // Deep Violet
          scaffoldBackgroundColor: const Color(0xFFF9FAFB), // Cool Gray 50
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF6D28D9),
            secondary: const Color(0xFFF472B6), // Soft Pink
            surface: Colors.white,
            background: const Color(0xFFF9FAFB),
          ),
          textTheme: GoogleFonts.latoTextTheme().copyWith(
            displayLarge: GoogleFonts.playfairDisplay(fontSize: 32, fontWeight: FontWeight.bold, color: const Color(0xFF1F2937)),
            displayMedium: GoogleFonts.playfairDisplay(fontSize: 28, fontWeight: FontWeight.bold, color: const Color(0xFF1F2937)),
            headlineSmall: GoogleFonts.lato(fontSize: 24, fontWeight: FontWeight.w600, color: const Color(0xFF374151)),
            titleMedium: GoogleFonts.lato(fontSize: 18, fontWeight: FontWeight.w600, color: const Color(0xFF1F2937)),
            bodyMedium: GoogleFonts.lato(fontSize: 14, color: const Color(0xFF4B5563)),
          ),

          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: const Color(0xFFF3F4F6),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF6D28D9), width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
        home: const HomeScreen(),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

enum PlannerView { month, week, day }

class _HomeScreenState extends State<HomeScreen> {
  // Navigation State
  final int _selectedYear = DateTime.now().year;
  int _selectedMonthIndex = DateTime.now().month - 1; 
  int _selectedWeekIndex = -1; 
  PlannerView _currentView = PlannerView.month;
  
  // Day View State
  DateTime _currentDisplayDate = DateTime.now();

  // History Stacks
  final List<NavigationState> _history = [];
  final List<NavigationState> _forwardHistory = [];

  // Welcome Screen State
  bool _showWelcome = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkRollover();
    });
  }

  // Navigation Logic
  void _navigateTo({
    required int monthIndex,
    required int weekIndex,
    required PlannerView view,
    required DateTime displayDate,
    bool clearForward = true,
  }) {
    setState(() {
      // 1. Push current state to history
      _history.add(NavigationState(
        year: _selectedYear,
        monthIndex: _selectedMonthIndex,
        weekIndex: _selectedWeekIndex,
        view: _currentView,
        displayDate: _currentDisplayDate,
      ));

      // 2. Clear forward history if it's a new navigation
      if (clearForward) {
        _forwardHistory.clear();
      }

      // 3. Update state
      _selectedMonthIndex = monthIndex;
      _selectedWeekIndex = weekIndex;
      _currentView = view;
      _currentDisplayDate = displayDate;
    });
  }

  void _goBack() {
    if (_history.isEmpty) return;
    setState(() {
      // 1. Push current to forward
      _forwardHistory.add(NavigationState(
        year: _selectedYear,
        monthIndex: _selectedMonthIndex,
        weekIndex: _selectedWeekIndex,
        view: _currentView,
        displayDate: _currentDisplayDate,
      ));

      // 2. Pop from history
      final previous = _history.removeLast();
      
      // 3. Apply state
      _selectedMonthIndex = previous.monthIndex;
      _selectedWeekIndex = previous.weekIndex;
      _currentView = previous.view;
      _currentDisplayDate = previous.displayDate;
      // _selectedYear = previous.year; // If we supported year change
    });
  }

  void _goForward() {
    if (_forwardHistory.isEmpty) return;
    setState(() {
      // 1. Push current to history
      _history.add(NavigationState(
        year: _selectedYear,
        monthIndex: _selectedMonthIndex,
        weekIndex: _selectedWeekIndex,
        view: _currentView,
        displayDate: _currentDisplayDate,
      ));

      // 2. Pop from forward
      final next = _forwardHistory.removeLast();

      // 3. Apply state
      _selectedMonthIndex = next.monthIndex;
      _selectedWeekIndex = next.weekIndex;
      _currentView = next.view;
      _currentDisplayDate = next.displayDate;
    });
  }

  Future<void> _checkRollover() async {
    final provider = Provider.of<TaskProvider>(context, listen: false);
    await provider.loadTasks();
    final overdueTasks = await provider.checkRolloverTasks();
    if (overdueTasks.isNotEmpty && mounted) {
      _showRolloverDialog(overdueTasks);
    }
  }

  Future<void> _showRolloverDialog(List<Task> overdueTasks) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Tarefas Pendentes'),
        content: Text(
            'Você tem ${overdueTasks.length} tarefas de ontem. Mover para hoje?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Não, deixar lá'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD8B4FE),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sim, Mover para Hoje'),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      final provider = Provider.of<TaskProvider>(context, listen: false);
      await provider.rolloverTasks(overdueTasks);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tarefas movidas para hoje!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PhysicalPlannerLayout(
      selectedIndex: _selectedMonthIndex,
      selectedWeekIndex: _selectedWeekIndex,
      showLeftTabs: false, // User requested tabs ONLY in Month view (where they are internal)
      onTabSelected: (index) {
        _navigateTo(
          monthIndex: index,
          weekIndex: -1,
          view: PlannerView.month,
          displayDate: DateTime(_selectedYear, index + 1, 1),
        );
      },
      onWeekSelected: (index) {
        _navigateTo(
          monthIndex: _selectedMonthIndex,
          weekIndex: index,
          view: PlannerView.week,
          displayDate: _currentDisplayDate,
        );
      },
      // Pass NULL if history is empty to hide arrows
      onBack: (_showWelcome || _history.isEmpty) ? null : _goBack,
      onForward: (_showWelcome || _forwardHistory.isEmpty) ? null : _goForward,
      child: Stack(
        children: [
          // 1. MAIN APP CONTENT
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // _buildHeader() removed to maximize space
              Expanded(child: _buildBody()),
            ],
          ),

          // 2. WELCOME SCREEN OVERLAY
          if (_showWelcome)
            Positioned.fill(
              child: WelcomeScreen(
                onDismiss: () {
                  setState(() => _showWelcome = false);
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_currentView) {
      case PlannerView.month:
        return _buildMonthCalendar();
      case PlannerView.week:
        return VerticalWeeklyView(
          weekIndex: _selectedWeekIndex, 
          monthIndex: _selectedMonthIndex,
          year: _selectedYear,
          onDaySelected: (date) {
            _navigateTo(
              monthIndex: _selectedMonthIndex,
              weekIndex: _selectedWeekIndex,
              view: PlannerView.day,
              displayDate: date,
            );
          },
        );
      case PlannerView.day:
        return _buildDailyViewWithTasks();
      default:
        return const Center(child: Text("Selecione um mês ou semana."));
    }
  }

  Widget _buildMonthCalendar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      child: Column(
        children: [
          Text(
            "${_getMonthName(_selectedMonthIndex)} de $_selectedYear",
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black54),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: MonthlyCalendar(
              monthIndex: _selectedMonthIndex,
              year: _selectedYear,
              onDaySelected: (date) {
                _navigateTo(
                  monthIndex: _selectedMonthIndex,
                  weekIndex: -1,
                  view: PlannerView.day,
                  displayDate: date,
                );
              },
              onWeekSelected: (weekIndex) {
                 _navigateTo(
                  monthIndex: _selectedMonthIndex,
                  weekIndex: weekIndex,
                  view: PlannerView.week,
                  displayDate: _currentDisplayDate,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyViewWithTasks() {
    // We compose the dashboard-style daily view here
    // But we also need to inject the "SmartTaskCard" list somewhere?
    // User requested "Daily" is the dashboard. 
    // Let's use DailyView (dashboard) and maybe append the task list below or overlay it?
    // Actually, in the DailyView (dashboard), there are "checklists". 
    // For now, let's just show the DailyView widgets.
    
    // Combining the Dashboard UI (DailyView) with the functional Task List
    // We can put the TaskList inside one of the columns of DailyView if we fully integrate.
    // Ideally, DailyView should just BE the view.
    // For now, let's wrap DailyView and maybe show the task list in a separate tab or section?
    // Or replace one of the "Generic Lists" with the real task list.
    
    // Let's verify the user intent: "Visão diária deve ser... [Image]".
    // The image has specific lists.
    // I will return the DailyView widget for now.
    return DailyView(date: _currentDisplayDate);
  }


  
  String _getViewName() {
    if (_currentView == PlannerView.month) return _getMonthName(_selectedMonthIndex);
    if (_currentView == PlannerView.week) return "${_getMonthName(_selectedMonthIndex)} - Sem ${_selectedWeekIndex + 1}";
    if (_currentView == PlannerView.day) return DateFormat('d MMM', 'pt_BR').format(_currentDisplayDate);
    return "";
  }

  // Helper
  String _getMonthName(int index) {
      if (index < 0 || index > 11) return "";
      const months = ['Janeiro','Fevereiro','Março','Abril','Maio','Junho','Julho','Agosto','Setembro','Outubro','Novembro','Dezembro'];
      return months[index];
  }
}

class NavigationState {
  final int year;
  final int monthIndex;
  final int weekIndex;
  final PlannerView view;
  final DateTime displayDate;

  NavigationState({
    required this.year,
    required this.monthIndex,
    required this.weekIndex,
    required this.view,
    required this.displayDate,
  });
}
