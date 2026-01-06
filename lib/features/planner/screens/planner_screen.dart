import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:amanda_planner/features/planner/providers/task_provider.dart';
import 'package:amanda_planner/shared/layout/physical_layout.dart';
import 'package:amanda_planner/features/planner/widgets/monthly_calendar.dart';
import 'package:amanda_planner/features/planner/widgets/daily_view.dart';
import 'package:amanda_planner/features/planner/widgets/vertical_weekly_view.dart';
import 'package:amanda_planner/features/welcome/welcome_screen.dart';

import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

enum PlannerView { month, week, day }

class _HomeScreenState extends State<HomeScreen> {
  // Navigation State
  int _selectedYear = DateTime.now().year;
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
      _history.add(
        NavigationState(
          year: _selectedYear,
          monthIndex: _selectedMonthIndex,
          weekIndex: _selectedWeekIndex,
          view: _currentView,
          displayDate: _currentDisplayDate,
        ),
      );

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
      _forwardHistory.add(
        NavigationState(
          year: _selectedYear,
          monthIndex: _selectedMonthIndex,
          weekIndex: _selectedWeekIndex,
          view: _currentView,
          displayDate: _currentDisplayDate,
        ),
      );

      // 2. Pop from history
      final previous = _history.removeLast();

      // 3. Apply state
      _selectedMonthIndex = previous.monthIndex;
      _selectedWeekIndex = previous.weekIndex;
      _currentView = previous.view;
      _currentDisplayDate = previous.displayDate;
      _selectedYear = previous.year;
    });
  }

  void _goForward() {
    if (_forwardHistory.isEmpty) return;
    setState(() {
      // 1. Push current to history
      _history.add(
        NavigationState(
          year: _selectedYear,
          monthIndex: _selectedMonthIndex,
          weekIndex: _selectedWeekIndex,
          view: _currentView,
          displayDate: _currentDisplayDate,
        ),
      );

      // 2. Pop from forward
      final next = _forwardHistory.removeLast();

      // 3. Apply state
      _selectedMonthIndex = next.monthIndex;
      _selectedWeekIndex = next.weekIndex;
      _currentView = next.view;
      _currentDisplayDate = next.displayDate;
      _selectedYear = next.year;
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
          'Você tem ${overdueTasks.length} tarefas de ontem. Mover para hoje?',
        ),
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
      showLeftTabs:
          false, // User requested tabs ONLY in Month view (where they are internal)
      onTabSelected: (index) {
        _navigateTo(
          monthIndex: index,
          weekIndex: -1,
          view: PlannerView.month,
          displayDate: DateTime(_selectedYear, index + 1, 1),
        );
      },
      onWeekSelected: (index) {
        // Calculate start of the week for the header
        final firstDayOfMonth = DateTime(_selectedYear, _selectedMonthIndex + 1, 1);
        final firstDayOfGrid = firstDayOfMonth.subtract(
          Duration(days: firstDayOfMonth.weekday - 1),
        );
        final startOfWeek = firstDayOfGrid.add(Duration(days: index * 7));

        _navigateTo(
          monthIndex: _selectedMonthIndex,
          weekIndex: index,
          view: PlannerView.week,
          displayDate: startOfWeek,
        );
      },
      // Pass NULL if history is empty to hide arrows
      onBack: (_showWelcome || _history.isEmpty) ? null : _goBack,
      onForward: (_showWelcome || _forwardHistory.isEmpty) ? null : _goForward,
      child: Stack(
        children: [
          // 1. MAIN APP CONTENT
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildGlobalHeader(),
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
          const SizedBox(height: 10),
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
    return DailyView(date: _currentDisplayDate);
  }

  String _getMonthName(int index) {
    if (index < 0 || index > 11) return "";
    const months = [
      'Janeiro',
      'Fevereiro',
      'Março',
      'Abril',
      'Maio',
      'Junho',
      'Julho',
      'Agosto',
      'Setembro',
      'Outubro',
      'Novembro',
      'Dezembro',
    ];
    return months[index];
  }
  Widget _buildGlobalHeader() {
    // Format: "Segunda-feira, 5 de Janeiro de 2026"
    // Use the current locale (pt_BR)
    String dateStr = DateFormat("EEEE, d 'de' MMMM 'de' y", "pt_BR").format(
      _currentDisplayDate,
    );
    // Capitalize words (except 'de')
    dateStr = dateStr.split(' ').map((word) {
      if (word == 'de') return word;
      if (word.isEmpty) return '';
      return '${word[0].toUpperCase()}${word.substring(1)}';
    }).join(' ');

    return Container(
      padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Show Year Navigation Arrows ONLY if in Month View
              // (User asked for Year in header, keeping nav functionality similar to before)
              if (_currentView == PlannerView.month)
                IconButton(
                  icon: const Icon(Icons.chevron_left, color: Colors.black26),
                  onPressed: () {
                    setState(() {
                      _selectedYear--;
                      // Update display date to keep synced
                      _currentDisplayDate = DateTime(
                        _selectedYear,
                        _selectedMonthIndex + 1,
                        1,
                      );
                    });
                  },
                ),
              Text(
                dateStr,
                style: GoogleFonts.lato(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF24555D),
                ),
              ),
              if (_currentView == PlannerView.month)
                IconButton(
                  icon: const Icon(Icons.chevron_right, color: Colors.black26),
                  onPressed: () {
                    setState(() {
                      _selectedYear++;
                      _currentDisplayDate = DateTime(
                        _selectedYear,
                        _selectedMonthIndex + 1,
                        1,
                      );
                    });
                  },
                ),
            ],
          ),
          // Keep "Hoje" button logic? It was in MonthView before.
          // Let's bring it here but positioned right, or maybe user didn't ask for it explicitly but it's useful.
          // I will leave it out for now to keep it clean as requested: only date info.
          // Actually, let's keep it accessible if possible.
          Positioned(
            right: 20,
            child: TextButton.icon(
              onPressed: () {
                setState(() {
                  final now = DateTime.now();
                  _selectedYear = now.year;
                  _selectedMonthIndex = now.month - 1;
                  _currentDisplayDate = now;
                  _currentView = PlannerView.day; // Jump to today in day view? Or keep view?
                  // Previous "Hoje" in month view reset everything.
                  // Let's make it smarter: just go to today's date in current view?
                  // Or standard reset:
                  _selectedWeekIndex = -1; // Reset week
                  _currentView = PlannerView.month; // Defaulting back to month like before
                });
              },
              icon: const Icon(Icons.today, size: 18),
              label: const Text("Hoje"),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF24555D),
              ),
            ),
          ),
        ],
      ),
    );
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
