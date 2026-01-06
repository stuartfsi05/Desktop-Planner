import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:amanda_planner/features/planner/providers/task_provider.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:amanda_planner/shared/widgets/formatted_text_editor.dart';

class DailyView extends StatefulWidget {
  final DateTime date;

  const DailyView({super.key, required this.date});

  @override
  State<DailyView> createState() => _DailyViewState();
}

class _DailyViewState extends State<DailyView> {
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    // Load initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void didUpdateWidget(DailyView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.date != widget.date) {
      _loadData();
    }
  }

  void _loadData() async {
    final provider = Provider.of<TaskProvider>(context, listen: false);
    await provider.loadDashboard(widget.date);
    // Note: FormattedTextEditor handles content update via Key
  }

  void _onNoteChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 1000), () {
      Provider.of<TaskProvider>(
        context,
        listen: false,
      ).saveNote(widget.date, value);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {


    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 8,
      ), // Reduced padding
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Removed (Using Global Header now)
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // LEFT COLUMN: Notes & Appointments (Flex 2 - Reduced width to give more to Tasks)
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      // NOTES SECTION (Larger Block)
                      Expanded(
                        flex: 5, // More space for notes
                        child: DashboardSection(
                          title: "Anotações do Dia",
                          icon: Icons.edit_note,
                          headerColor: Colors.white,
                          titleColor: theme.colorScheme.primary,
                          // No fake toolbar action
                          child: Consumer<TaskProvider>(
                            builder: (context, provider, _) {
                              return Container(
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.only(
                                    bottomLeft: Radius.circular(16),
                                    bottomRight: Radius.circular(16),
                                  ),
                                ),
                                child: FormattedTextEditor(
                                  key: ValueKey(
                                    "daily_note_${widget.date.toIso8601String()}",
                                  ),
                                  initialContent: provider.currentNote,
                                  placeholder:
                                      "Digite aqui suas notas do dia...",
                                  onChanged: _onNoteChanged,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // APPOINTMENTS SECTION (Smaller Block)
                      Expanded(
                        flex: 4,
                        child: _buildAppointmentsSection(context),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),

                // RIGHT COLUMN: Checklists (Flex 3 - Wider columns for tasks)
                Expanded(
                  flex: 3,
                  child: Column(
                    children: [
                      // TOP: Priority Checklist
                      Expanded(
                        flex: 1,
                        child: _buildPrioritySection(
                          context,
                          title: 'Prioridades',
                          headerColor: const Color(0xFFFDE68A), // Light Gold
                          accentColor: const Color(
                            0xFFB45309,
                          ), // Copper/Dark Gold
                          icon: Icons.star_rounded,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // BOTTOM: 2 Generic Checklists
                      Expanded(
                        flex: 2,
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildChecklistSection(
                                context,
                                type: 'morning',
                                title: 'Manhã',
                                headerColor: const Color(
                                  0xFFBFDBFE,
                                ), // Soft Blue
                                accentColor: const Color(
                                  0xFF1E40AF,
                                ), // Dark Blue
                                icon: Icons.wb_sunny_rounded,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildChecklistSection(
                                context,
                                type: 'afternoon',
                                title: 'Tarde',
                                headerColor: const Color(
                                  0xFFDDD6FE,
                                ), // Soft Purple
                                accentColor: const Color(
                                  0xFF5B21B6,
                                ), // Dark Purple
                                icon: Icons.nightlight_round,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ... (keep _buildAddPriorityDialog and _buildAddItemDialog) ...
  Future<void> _showAddPriorityDialog(BuildContext context) async {
    String content = "";
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Nova Prioridade"),
        content: TextField(
          autofocus: true,
          decoration: const InputDecoration(hintText: "Descrição da tarefa"),
          onChanged: (v) => content = v,
          onSubmitted: (_) => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text("Adicionar"),
          ),
        ],
      ),
    );
    if (content.isNotEmpty) {
      if (mounted) {
        // Create as a TASK
        await Provider.of<TaskProvider>(context, listen: false).addTask(
          content,
          customDate: widget.date,
          priority: 3,
        ); // High priority?
      }
    }
  }

  Future<void> _showAddItemDialog(BuildContext context, String type) async {
    String content = "";
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Novo Item"),
        content: TextField(
          autofocus: true,
          decoration: const InputDecoration(hintText: "Nome do item"),
          onChanged: (v) => content = v,
          onSubmitted: (_) => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text("Adicionar"),
          ),
        ],
      ),
    );
    if (content.isNotEmpty) {
      if (mounted) {
        await Provider.of<TaskProvider>(
          context,
          listen: false,
        ).addDashboardItem(widget.date, type, content);
      }
    }
  }

  // NOTE: I'm not replacing the whole file so I rely on StartLine/EndLine logic or TargetContent.
  // Wait, I AM replacing a huge chunk. The previous tool call view_file shows line 62 start of build.
  // I must include all the helper methods I'm replacing if I use ReplaceFileContent with a huge chunk.

  // Actually, let's look at _buildAppointmentsSection specifically.

  Widget _buildChecklistSection(
    BuildContext context, {
    required String type,
    required String title,
    required Color headerColor,
    required Color accentColor,
    required IconData icon,
  }) {
    return DashboardSection(
      title: title,
      icon: icon,
      headerColor: headerColor,
      titleColor: accentColor,
      action: IconButton(
        icon: Icon(Icons.add_circle, color: accentColor, size: 20),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        onPressed: () => _showAddItemDialog(context, type),
        tooltip: "Adicionar Item",
      ),
      child: Consumer<TaskProvider>(
        builder: (context, provider, _) {
          final items = provider.getItems(type);
          if (items.isEmpty) {
            return Center(
              child: Text(
                "Nenhuma tarefa",
                style: TextStyle(
                  color: Colors.grey.withValues(alpha: 0.5),
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            itemCount: items.length,
            separatorBuilder: (_, __) =>
                Divider(height: 1, indent: 48, color: Colors.grey.shade100),
            itemBuilder: (context, index) {
              final item = items[index];
              return GestureDetector(
                onSecondaryTapDown: (details) async {
                  await _showPostponeMenu(
                    context,
                    details.globalPosition,
                    item,
                    provider,
                  );
                },
                child: ListTile(
                dense: true,
                visualDensity: VisualDensity.compact,
                contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                leading: Transform.scale(
                  scale: 0.9,
                  child: Checkbox(
                    activeColor: accentColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    side: BorderSide(
                      color: accentColor.withValues(alpha: 0.5),
                      width: 1.5,
                    ),
                    value: item.isCompleted,
                    onChanged: (v) => provider.toggleDashboardItem(item),
                  ),
                ),
                title: Text(
                  item.content,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    decoration: item.isCompleted
                        ? TextDecoration.lineThrough
                        : null,
                    color: item.isCompleted ? Colors.grey : Colors.black87,
                  ),
                ),
                trailing: IconButton(
                  icon: Icon(
                    Icons.close,
                    size: 16,
                    color: Colors.grey.shade300,
                  ),
                  onPressed: () =>
                      provider.deleteDashboardItem(item.id!, widget.date),
                  splashRadius: 16,
                ),
                ),
              );
            },
          );

        },
      ),
    );
  }

  Future<void> _showPostponeMenu(
    BuildContext context,
    Offset position,
    DashboardItem item,
    TaskProvider provider,
  ) async {
    final result = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx + 1,
        position.dy + 1,
      ),
      items: [
        const PopupMenuItem(
          value: 'tomorrow',
          child: Row(
            children: [
              Icon(Icons.event_repeat, size: 18, color: Colors.blue),
              SizedBox(width: 8),
              Text('Adiar para Amanhã'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'next_week',
          child: Row(
            children: [
              Icon(Icons.next_week, size: 18, color: Colors.orange),
              SizedBox(width: 8),
              Text('Adiar para Próxima Semana'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'pick_date',
          child: Row(
            children: [
              Icon(Icons.calendar_month, size: 18, color: Colors.purple),
              SizedBox(width: 8),
              Text('Escolher Data...'),
            ],
          ),
        ),
      ],
    );

    if (result == null) return;

    final currentDate = widget.date;
    DateTime? newDate;

    if (result == 'tomorrow') {
      newDate = currentDate.add(const Duration(days: 1));
    } else if (result == 'next_week') {
      newDate = currentDate.add(const Duration(days: 7));
    } else if (result == 'pick_date') {
      newDate = await showDatePicker(
        context: context,
        initialDate: currentDate.add(const Duration(days: 1)),
        firstDate: DateTime.now().subtract(const Duration(days: 365)),
        lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      );
    }

    if (newDate != null && context.mounted) {
      await provider.moveDashboardItem(item, newDate, currentDate);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Tarefa movida para ${DateFormat('dd/MM', 'pt_BR').format(newDate)}",
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Widget _buildPrioritySection(
    BuildContext context, {
    required String title,
    required Color headerColor,
    required Color accentColor,
    required IconData icon,
  }) {
    return DashboardSection(
      title: title,
      icon: icon,
      headerColor: headerColor,
      titleColor: accentColor,
      action: IconButton(
        icon: Icon(Icons.add_circle, color: accentColor, size: 20),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        onPressed: () => _showAddPriorityDialog(context),
        tooltip: "Adicionar Prioridade (Tarefa)",
      ),
      child: Consumer<TaskProvider>(
        builder: (context, provider, _) {
          // Filter TASKS for this day
          final tasks = provider.tasks
              .where(
                (t) =>
                    t.dueDate.year == widget.date.year &&
                    t.dueDate.month == widget.date.month &&
                    t.dueDate.day == widget.date.day,
              )
              .toList();

          if (tasks.isEmpty) {
            return Center(
              child: Text(
                "Nenhuma prioridade",
                style: TextStyle(
                  color: Colors.grey.withValues(alpha: 0.5),
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            itemCount: tasks.length,
            separatorBuilder: (_, __) =>
                Divider(height: 1, indent: 48, color: Colors.grey.shade100),
            itemBuilder: (context, index) {
              final task = tasks[index];
              return ListTile(
                dense: true,
                visualDensity: VisualDensity.compact,
                contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                leading: Transform.scale(
                  scale: 0.9,
                  child: Checkbox(
                    activeColor: accentColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    side: BorderSide(
                      color: accentColor.withValues(alpha: 0.5),
                      width: 1.5,
                    ),
                    value: task.isCompleted,
                    onChanged: (v) {
                      task.isCompleted = v ?? false;
                      provider.updateTask(task);
                    },
                  ),
                ),
                title: Text(
                  task.title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    decoration: task.isCompleted
                        ? TextDecoration.lineThrough
                        : null,
                    color: task.isCompleted ? Colors.grey : Colors.black87,
                  ),
                ),
                trailing: IconButton(
                  icon: Icon(
                    Icons.close,
                    size: 16,
                    color: Colors.grey.shade300,
                  ),
                  onPressed: () {
                    if (task.id != null) provider.deleteTask(task.id!);
                  },
                  splashRadius: 16,
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildAppointmentsSection(BuildContext context) {
    final theme = Theme.of(context);

    return DashboardSection(
      title: "Compromissos",
      icon: Icons.event_note,
      headerColor: theme.colorScheme.surface,
      titleColor: theme.colorScheme.primary,
      action: IconButton(
        icon: Icon(
          Icons.add_circle,
          color: theme.colorScheme.primary,
          size: 20,
        ),
        onPressed: () => _showAddEventDialog(context),
        tooltip: "Novo Compromisso",
        constraints: const BoxConstraints(),
        padding: EdgeInsets.zero,
      ),
      child: Consumer<TaskProvider>(
        builder: (context, provider, _) {
          final events = provider.getEventsForDay(widget.date);
          if (events.isEmpty) {
            return const Center(
              child: Text(
                "Agenda livre",
                style: TextStyle(color: Colors.black38),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ListTile(
                  visualDensity: VisualDensity.compact,
                  dense: true,
                  leading: Container(
                    width: 3,
                    height: 24,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                    margin: const EdgeInsets.symmetric(vertical: 4),
                  ),
                  title: Text(
                    event.title,
                    style: theme.textTheme.titleSmall?.copyWith(fontSize: 13),
                  ),
                  subtitle: event.description.isNotEmpty
                      ? Text(
                          event.description,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 11,
                          ),
                        )
                      : null,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.edit_outlined, // Edit Pencil
                          color: Colors.grey.shade400,
                          size: 18,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () {
                          if (event.id != null) {
                            _showEditEventDialog(context, event);
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: Icon(
                          Icons.delete_outline,
                          color: Colors.grey.shade400,
                          size: 18,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () {
                          if (event.id != null) provider.deleteEvent(event.id!);
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _showAddEventDialog(BuildContext context) async {
    final titleController = TextEditingController();
    final detailsController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Novo Compromisso"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: "Título",
                hintText: "Reunião, Médico...",
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: detailsController,
              decoration: const InputDecoration(
                labelText: "Detalhes (Opcional)",
                hintText: "Horário, Local...",
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.isNotEmpty) {
                Provider.of<TaskProvider>(context, listen: false).addEvent(
                  titleController.text,
                  detailsController.text,
                  widget.date,
                );
                Navigator.pop(context);
              }
            },
            child: const Text("Salvar"),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditEventDialog(
    BuildContext context,
    CalendarEvent event,
  ) async {
    final titleController = TextEditingController(text: event.title);
    final detailsController = TextEditingController(text: event.description);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Editar Compromisso"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: "Título",
                hintText: "Reunião, Médico...",
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: detailsController,
              decoration: const InputDecoration(
                labelText: "Detalhes (Opcional)",
                hintText: "Horário, Local...",
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.isNotEmpty) {
                // Update existing event object
                event.title = titleController.text;
                event.description = detailsController.text;

                Provider.of<TaskProvider>(
                  context,
                  listen: false,
                ).updateEvent(event);
                Navigator.pop(context);
              }
            },
            child: const Text("Salvar"),
          ),
        ],
      ),
    );
  }

  // DashboardSection Class (Re-declared for completeness inside replacement if needed,
  // but better to just replace the class DashboardSection if it's separate.)
  // Wait, DashboardSection is at the bottom of the file. I need to make sure I don't delete it or duplicate it if I'm replacing "StartLine: 62".
  // The file has 621 lines.
  // I will END the replacement BEFORE DashboardSection class definition if possible, or include it.
  // DashboardSection starts at line 549.
  // My replacement above includes _buildAppointmentsSection which ends around line 546.
  // I will try to target lines 62 to 547.
}

class DashboardSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final Widget? action;
  final Color headerColor;
  final Color titleColor;

  const DashboardSection({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
    this.action,
    required this.headerColor,
    this.titleColor = Colors.black87,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.05),
            blurRadius: 10,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          // Thinner Header
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 10,
            ), // Reduced height
            decoration: BoxDecoration(
              color: headerColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              crossAxisAlignment:
                  CrossAxisAlignment.center, // Ensure vertical alignment
              children: [
                Icon(icon, size: 18, color: titleColor.withValues(alpha: 0.8)),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: titleColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                if (action != null) action!,
              ],
            ),
          ),
          const Divider(height: 1, color: Colors.transparent),
          // Body
          Expanded(child: child),
        ],
      ),
    );
  }
}
