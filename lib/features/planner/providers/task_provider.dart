import 'package:flutter/material.dart';
import 'package:amanda_planner/core/database/database_helper.dart';

class Task {
  int? id;
  String title;
  String description;
  bool isCompleted;
  int priority; // 0: None, 1: Low, 2: Medium, 3: High
  DateTime dueDate;

  Task({
    this.id,
    required this.title,
    this.description = '',
    this.isCompleted = false,
    this.priority = 0,
    required this.dueDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'isCompleted': isCompleted ? 1 : 0,
      'priority': priority,
      'dueDate': dueDate.toIso8601String(),
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'],
      title: map['title'],
      description: map['description'] ?? '',
      isCompleted: map['isCompleted'] == 1,
      priority: map['priority'] ?? 0,
      dueDate: DateTime.parse(map['dueDate']),
    );
  }
}

class TaskProvider with ChangeNotifier {
  List<Task> _tasks = [];
  final DatabaseHelper _dbHelper = DatabaseHelper();

  List<Task> get tasks => _tasks;

  Future<void> loadTasks() async {
    final data = await _dbHelper.getTasks();
    _tasks = data.map((e) => Task.fromMap(e)).toList();

    final eventData = await _dbHelper.getEvents();
    _events = eventData.map((e) => CalendarEvent.fromMap(e)).toList();

    notifyListeners();
  }

  Future<void> addTask(
    String title, {
    String desc = '',
    int priority = 0,
    DateTime? customDate,
  }) async {
    final newTask = Task(
      title: title,
      description: desc,
      priority: priority,
      dueDate: customDate ?? DateTime.now(),
    );
    await _dbHelper.insertTask(newTask.toMap());
    await loadTasks();
  }

  Future<void> updateTask(Task task) async {
    await _dbHelper.updateTask(task.toMap());
    await loadTasks();
  }

  Future<void> deleteTask(int id) async {
    await _dbHelper.deleteTask(id);
    await loadTasks();
  }

  // Rollover Logic
  Future<List<Task>> checkRolloverTasks() async {
    await loadTasks(); // Ensure we have latest data
    final today = DateTime.now();
    final startOfToday = DateTime(today.year, today.month, today.day);

    final List<Task> overdueTasks = _tasks.where((t) {
      if (t.isCompleted) return false;
      // Check if due date is strictly before today (ignoring time if we store just dates, but here we compare vs start of today)
      return t.dueDate.isBefore(startOfToday);
    }).toList();

    return overdueTasks;
  }

  Future<void> rolloverTasks(List<Task> tasksToMove) async {
    final now = DateTime.now();
    for (var task in tasksToMove) {
      task.dueDate = now;
      await _dbHelper.updateTask(task.toMap());
    }
    await loadTasks();
  }

  // --- DASHBOARD LOGIC (Notes & Lists) ---
  String _currentNote = "";
  String get currentNote => _currentNote;

  final Map<String, List<DashboardItem>> _dashboardItems = {
    'priority': [],
    'morning': [],
    'afternoon': [],
  };

  List<DashboardItem> getItems(String type) => _dashboardItems[type] ?? [];

  // NOTE: This should be called when date changes in DailyView
  Future<void> loadDashboard(DateTime date) async {
    final dateStr = date.toIso8601String().split('T')[0];

    // Load Note
    _currentNote = await _dbHelper.getDailyNote(dateStr) ?? "";

    // Load Items
    for (var type in ['priority', 'morning', 'afternoon']) {
      final itemsData = await _dbHelper.getDashboardItems(dateStr, type);
      _dashboardItems[type] = itemsData
          .map((e) => DashboardItem.fromMap(e))
          .toList();
    }
    notifyListeners();
  }

  Future<void> saveNote(DateTime date, String content) async {
    final dateStr = date.toIso8601String().split('T')[0];
    _currentNote = content;
    await _dbHelper.saveDailyNote(dateStr, content);
    // Notify not strictly needed if only typing, but good for sync
  }

  Future<void> addDashboardItem(
    DateTime date,
    String type,
    String content,
  ) async {
    final dateStr = date.toIso8601String().split('T')[0];
    // Calculate new position (end of list)
    final int position = (_dashboardItems[type]?.length ?? 0);

    final newItem = DashboardItem(
      type: type,
      content: content,
      date: dateStr,
      position: position,
    );

    await _dbHelper.insertDashboardItem(newItem.toMap());
    await loadDashboard(date); // Reload to get ID
  }

  Future<void> toggleDashboardItem(DashboardItem item) async {
    item.isCompleted = !item.isCompleted;
    await _dbHelper.updateDashboardItem(item.toMap());
    notifyListeners();
  }

  Future<void> deleteDashboardItem(int id, DateTime date) async {
    await _dbHelper.deleteDashboardItem(id);
    await loadDashboard(date);
  }

  Future<void> moveDashboardItem(
    DashboardItem item,
    DateTime newDate,
    DateTime currentDate,
  ) async {
    final newDateStr = newDate.toIso8601String().split('T')[0];
    item.date = newDateStr;
    // We update the item with the new date.
    // Position might duplicate, but usually acceptable for this simple app.
    // Ideally we would fetch max position for new date, but distinct dates segregate lists.
    await _dbHelper.updateDashboardItem(item.toMap());
    await loadDashboard(currentDate); // Reload current view to remove item
  }

  // --- EVENTS LOGIC ---
  List<CalendarEvent> _events = [];
  List<CalendarEvent> get events => _events;

  Future<void> addEvent(String title, String description, DateTime date) async {
    final newEvent = CalendarEvent(
      title: title,
      description: description,
      date: date,
    );
    await _dbHelper.insertEvent(newEvent.toMap());
    await loadTasks(); // Reloads events too
  }

  Future<void> deleteEvent(int id) async {
    await _dbHelper.deleteEvent(id);
    await loadTasks();
  }

  Future<void> updateEvent(CalendarEvent event) async {
    await _dbHelper.updateEvent(event.toMap());
    await loadTasks();
  }

  List<CalendarEvent> getEventsForDay(DateTime date) {
    return _events.where((e) => DateUtils.isSameDay(e.date, date)).toList();
  }

  // --- WEEKLY NOTES LOGIC ---
  final Map<String, String> _weeklyNotes =
      {}; // Key: "YEAR_MONTH_WEEKINDEX_SIDE"

  String getWeeklyNote(int year, int monthIndex, int weekIndex, String side) {
    final key = "${year}_${monthIndex}_${weekIndex}_$side";
    return _weeklyNotes[key] ?? "";
  }

  Future<void> loadWeeklyNotes(int year, int monthIndex, int weekIndex) async {
    final sides = ['LEFT', 'RIGHT'];
    for (var side in sides) {
      final key = "${year}_${monthIndex}_${weekIndex}_$side";
      final content = await _dbHelper.getWeeklyNote(key);
      if (content != null) {
        _weeklyNotes[key] = content;
      } else {
        _weeklyNotes[key] = "";
      }
    }
    notifyListeners();
  }

  Future<void> saveWeeklyNote(
    int year,
    int monthIndex,
    int weekIndex,
    String side,
    String content,
  ) async {
    final key = "${year}_${monthIndex}_${weekIndex}_$side";
    _weeklyNotes[key] = content;
    await _dbHelper.saveWeeklyNote(key, content);
    // notifyListeners(); // Typing might be frequent, maybe don't notify on every char if managed locally
  }
}

class CalendarEvent {
  int? id;
  String title;
  String description;
  DateTime date;

  CalendarEvent({
    this.id,
    required this.title,
    this.description = '',
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'date': date.toIso8601String(),
    };
  }

  factory CalendarEvent.fromMap(Map<String, dynamic> map) {
    return CalendarEvent(
      id: map['id'],
      title: map['title'],
      description: map['description'] ?? '',
      date: DateTime.parse(map['date']),
    );
  }
}

class DashboardItem {
  int? id;
  String type; // 'priority', 'morning', 'afternoon'
  String content;
  bool isCompleted;
  String date;
  int position;

  DashboardItem({
    this.id,
    required this.type,
    required this.content,
    this.isCompleted = false,
    required this.date,
    this.position = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'content': content,
      'isCompleted': isCompleted ? 1 : 0,
      'date': date,
      'position': position,
    };
  }

  factory DashboardItem.fromMap(Map<String, dynamic> map) {
    return DashboardItem(
      id: map['id'],
      type: map['type'],
      content: map['content'],
      isCompleted: map['isCompleted'] == 1,
      date: map['date'],
      position: map['position'],
    );
  }
}
