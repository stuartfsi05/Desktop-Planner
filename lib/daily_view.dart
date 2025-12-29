import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'task_provider.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

class DailyView extends StatefulWidget {
  final DateTime date;

  const DailyView({
    super.key,
    required this.date,
  });

  @override
  State<DailyView> createState() => _DailyViewState();
}

class _DailyViewState extends State<DailyView> {
  final TextEditingController _notesController = TextEditingController();
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
    _notesController.text = provider.currentNote;
  }

  void _onNoteChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 1000), () {
      Provider.of<TaskProvider>(context, listen: false).saveNote(widget.date, value);
    });
  }

  @override
  void dispose() {
    _notesController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Format: "Monday, January 1st" (in PT-BR)
    String dateStr = DateFormat('EEEE, d', 'pt_BR').format(widget.date);
    String monthStr = DateFormat('MMMM', 'pt_BR').format(widget.date);
    // Capitalize
    dateStr = dateStr[0].toUpperCase() + dateStr.substring(1);
    monthStr = monthStr[0].toUpperCase() + monthStr.substring(1);
    
    final fullTitle = "$dateStr de $monthStr";
    final theme = Theme.of(context);

    // Standardized smaller font
    final titleStyle = GoogleFonts.lato(
      fontSize: 24, 
      fontWeight: FontWeight.bold, 
      color: theme.primaryColor
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 12, 32, 24), // Reduced top padding
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header shifted UP relative to arrow
          Center(
            child: Transform.translate(
              offset: const Offset(0, -5), // Visual adjustment
              child: Text(
                fullTitle,
                style: titleStyle,
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // LEFT COLUMN: Notes & Appointments (Flex 3)
                Expanded(
                  flex: 3, 
                  child: Column(
                    children: [
                      // NOTES SECTION (Larger Block)
                      Expanded(
                        flex: 2, // More space for notes
                        child: DashboardSection(
                          title: "Anotações do Dia",
                          icon: Icons.edit_note,
                          headerColor: theme.colorScheme.surface, 
                          titleColor: theme.colorScheme.primary,
                          child: TextField(
                            controller: _notesController,
                            onChanged: _onNoteChanged,
                            maxLines: null,
                            expands: true,
                            style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
                            decoration: InputDecoration(
                              hintText: "Digite aqui suas notas do dia...",
                              hintStyle: TextStyle(color: Colors.grey.shade400),
                              border: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: const EdgeInsets.all(20),
                              fillColor: Colors.transparent, 
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // APPOINTMENTS SECTION (Smaller Block)
                      Expanded(
                        flex: 1, // Less space for appointments
                        child: _buildAppointmentsSection(context),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                
                // RIGHT COLUMN: Checklists (Flex 2 - Wider)
                Expanded(
                  flex: 2, 
                  child: Column(
                    children: [
                      // TOP: Priority Checklist (Top Right)
                      Expanded(
                        flex: 1, // Smaller (was 1, now relative to total column flex)
                        child: _buildPrioritySection(
                          context, 
                          title: 'Prioridades', 
                          headerColor: Colors.orange.shade50, 
                          accentColor: Colors.orange.shade800,
                          icon: Icons.star_rounded,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // BOTTOM: 2 Generic Checklists
                      Expanded(
                        flex: 2, // Larger (was 1, now 2x priority)
                        child: Row(
                          children: [
                            Expanded(child: _buildChecklistSection(
                              context,
                              type: 'morning',
                              title: 'Manhã',
                              headerColor: Colors.blue.shade50,
                              accentColor: Colors.blue.shade700,
                              icon: Icons.wb_sunny_rounded,
                            )),
                            const SizedBox(width: 16),
                            Expanded(child: _buildChecklistSection(
                              context,
                              type: 'afternoon',
                              title: 'Tarde',
                              headerColor: Colors.indigo.shade50,
                              accentColor: Colors.indigo.shade700,
                              icon: Icons.nightlight_round,
                            )),
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

  // ... (keep _buildChecklistSection and _buildPrioritySection as is or with minor tweaks if needed, but flex changes above handle layout) ...
  // Actually I need to keep the file valid, so I must not cut off methods unless I replace them too.
  // I will assume ReplaceFileContent works by replacing the target range.
  // The TargetContent below will target the Build method and DashboardSection class to update headers.

  Widget _buildChecklistSection(
    BuildContext context, 
    {required String type, required String title, required Color headerColor, required Color accentColor, required IconData icon}
  ) {
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
                style: TextStyle(color: Colors.grey.withOpacity(0.5), fontSize: 13, fontStyle: FontStyle.italic)
              )
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            itemCount: items.length,
            separatorBuilder: (_, __) => Divider(height: 1, indent: 48, color: Colors.grey.shade100),
            itemBuilder: (context, index) {
              final item = items[index];
              return ListTile(
                dense: true,
                visualDensity: VisualDensity.compact,
                contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                leading: Transform.scale(
                  scale: 0.9,
                  child: Checkbox(
                    activeColor: accentColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    side: BorderSide(color: accentColor.withOpacity(0.5), width: 1.5),
                    value: item.isCompleted, 
                    onChanged: (v) => provider.toggleDashboardItem(item),
                  ),
                ),
                title: Text(
                  item.content, 
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    decoration: item.isCompleted ? TextDecoration.lineThrough : null,
                    color: item.isCompleted ? Colors.grey : Colors.black87,
                  )
                ),
                trailing: IconButton(
                   icon: Icon(Icons.close, size: 16, color: Colors.grey.shade300),
                   onPressed: () => provider.deleteDashboardItem(item.id!, widget.date),
                   splashRadius: 16,
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildPrioritySection(
    BuildContext context, 
    {required String title, required Color headerColor, required Color accentColor, required IconData icon}
  ) {
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
          final tasks = provider.tasks.where((t) => 
            t.dueDate.year == widget.date.year &&
            t.dueDate.month == widget.date.month &&
            t.dueDate.day == widget.date.day
          ).toList();

          if (tasks.isEmpty) {
            return Center(
              child: Text(
                "Nenhuma prioridade", 
                style: TextStyle(color: Colors.grey.withOpacity(0.5), fontSize: 13, fontStyle: FontStyle.italic)
              )
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            itemCount: tasks.length,
            separatorBuilder: (_, __) => Divider(height: 1, indent: 48, color: Colors.grey.shade100),
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    side: BorderSide(color: accentColor.withOpacity(0.5), width: 1.5),
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
                    decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                    color: task.isCompleted ? Colors.grey : Colors.black87,
                  )
                ),
                trailing: IconButton(
                   icon: Icon(Icons.close, size: 16, color: Colors.grey.shade300),
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
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
          ElevatedButton(
            onPressed: () {
               Navigator.pop(context);
            }, 
            child: const Text("Adicionar")
          )
        ],
      )
    );
    if (content.isNotEmpty) {
      if (mounted) {
        // Create as a TASK
        await Provider.of<TaskProvider>(context, listen: false).addTask(content, customDate: widget.date, priority: 3); // High priority?
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
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
          ElevatedButton(
            onPressed: () {
               Navigator.pop(context);
            }, 
            child: const Text("Adicionar")
          )
        ],
      )
    );
    if (content.isNotEmpty) {
      if (mounted) {
        await Provider.of<TaskProvider>(context, listen: false).addDashboardItem(widget.date, type, content);
      }
    }
  }

  Widget _buildAppointmentsSection(BuildContext context) {
    final titleController = TextEditingController();
    final detailsController = TextEditingController();
    final theme = Theme.of(context);

    return DashboardSection(
      title: "Compromissos",
      icon: Icons.event_note,
      headerColor: theme.colorScheme.surface,
      titleColor: theme.colorScheme.primary, 
      child: Column(
        children: [
          // List of Events
          Expanded(
            child: Consumer<TaskProvider>(
              builder: (context, provider, _) {
                final events = provider.getEventsForDay(widget.date);
                if (events.isEmpty) {
                  return const Center(child: Text("Agenda livre", style: TextStyle(color: Colors.black38)));
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
                          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset:const Offset(0,2))
                        ]
                      ),
                      child: ListTile(
                        visualDensity: VisualDensity.compact,
                        dense: true,
                        leading: Container(
                          width: 3, 
                          height: 24, 
                          decoration: BoxDecoration(
                            color: theme.colorScheme.secondary,
                            borderRadius: BorderRadius.circular(2)
                          ),
                          margin: const EdgeInsets.symmetric(vertical: 4),
                        ),
                        title: Text(event.title, style: theme.textTheme.titleSmall?.copyWith(fontSize: 13)),
                        subtitle: event.description.isNotEmpty 
                          ? Text(event.description, style: theme.textTheme.bodySmall?.copyWith(fontSize: 11)) 
                          : null,
                        trailing: IconButton(
                          icon: Icon(Icons.delete_outline, color: Colors.grey.shade400, size: 18),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () {
                             if(event.id != null) provider.deleteEvent(event.id!);
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          
          const Divider(height: 1),
          // Compact Input Section
          Container(
            padding: const EdgeInsets.all(8.0),
            color: Colors.grey.shade50,
            child: Row(
               children: [
                 Expanded(
                   flex: 4,
                   child: SizedBox(
                     height: 32,
                     child: TextField(
                       controller: titleController,
                       style: const TextStyle(fontSize: 13),
                       decoration: InputDecoration(
                         hintText: "Título",
                         contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                         border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide.none),
                         filled: true,
                         fillColor: Colors.white,
                       ),
                     ),
                   ),
                 ),
                 const SizedBox(width: 8),
                 Expanded(
                   flex: 5,
                   child: SizedBox(
                     height: 32,
                     child: TextField(
                       controller: detailsController,
                       style: const TextStyle(fontSize: 13),
                       decoration: InputDecoration(
                         hintText: "Detalhes...",
                         contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                         border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide.none),
                         filled: true,
                         fillColor: Colors.white,
                       ),
                     ),
                   ),
                 ),
                 const SizedBox(width: 8),
                 SizedBox(
                   width: 32, height: 32,
                   child: IconButton(
                     style: IconButton.styleFrom(
                       backgroundColor: theme.colorScheme.primary,
                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                       padding: EdgeInsets.zero,
                     ),
                     icon: const Icon(Icons.add, color: Colors.white, size: 18),
                     onPressed: () {
                        if (titleController.text.isNotEmpty) {
                          Provider.of<TaskProvider>(context, listen: false).addEvent(
                            titleController.text,
                            detailsController.text,
                            widget.date,
                          );
                          titleController.clear();
                          detailsController.clear();
                        }
                     },
                   ),
                 )
               ],
            ),
          ),
        ],
      ),
    );
  }
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
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          )
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          // Thinner Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), // Reduced height
            decoration: BoxDecoration(
              color: headerColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center, // Ensure vertical alignment
              children: [
                Icon(icon, size: 18, color: titleColor.withOpacity(0.8)),
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
