import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:amanda_planner/features/planner/providers/task_provider.dart';
import 'package:amanda_planner/shared/widgets/formatted_text_editor.dart';

class VerticalWeeklyView extends StatefulWidget {
  final int weekIndex; // 0-4
  final int monthIndex; // 0-11
  final int year;
  final Function(DateTime) onDaySelected;

  const VerticalWeeklyView({
    super.key,
    required this.weekIndex,
    required this.monthIndex,
    required this.year,
    required this.onDaySelected,
  });

  @override
  _VerticalWeeklyViewState createState() => _VerticalWeeklyViewState();
}

class _VerticalWeeklyViewState extends State<VerticalWeeklyView> {

  @override
  void initState() {
    super.initState();
    // Load notes when widget initializes or updates
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadNotes();
    });
  }

  @override
  void didUpdateWidget(covariant VerticalWeeklyView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.weekIndex != widget.weekIndex || oldWidget.monthIndex != widget.monthIndex) {
      _loadNotes();
    }
  }

  void _loadNotes() async {
    final provider = Provider.of<TaskProvider>(context, listen: false);
    await provider.loadWeeklyNotes(widget.year, widget.monthIndex, widget.weekIndex);
    // Editor handles updates via Key
  }
  
  void _saveNote(String side, String content) {
    final provider = Provider.of<TaskProvider>(context, listen: false);
    // Debounce is ideal but relying on FormattedTextEditor to emit changes.
    // Given WeeklyView might have many small edits, maybe just save directly?
    // Provider.saveWeeklyNote writes to DB. Frequent writes are okay for local DB.
    provider.saveWeeklyNote(widget.year, widget.monthIndex, widget.weekIndex, side, content);
  }

  @override
  void dispose() {
    super.dispose();
  }

  List<DateTime> _getDaysInWeek() {
    int startDay = (widget.weekIndex * 7); // 0-based offset
    List<DateTime> days = [];
    final firstDayOfMonth = DateTime(widget.year, widget.monthIndex + 1, 1);
    
    for (int i = 0; i < 7; i++) {
        // Proper Date Math: Add days to the first of the month
        final date = firstDayOfMonth.add(Duration(days: startDay + i));
        days.add(date);
    }
    return days;
  }

  Future<void> _showAddTaskDialog(DateTime date) async {
    final titleController = TextEditingController();
    bool isSubmitting = false; 
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Nova Tarefa', style: Theme.of(context).textTheme.titleLarge),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Para ${date.day}/${date.month}', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey)),
            const SizedBox(height: 16),
            TextField(
              controller: titleController,
              autofocus: true,
              style: const TextStyle(fontSize: 16),
              decoration: InputDecoration(
                hintText: 'Digite a tarefa...',
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 1.5)
                ),
              ),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey))
          ),
          StatefulBuilder(
             builder: (context, setState) {
               return ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                onPressed: isSubmitting ? null : () async {
                  if (titleController.text.isNotEmpty) {
                     setState(() => isSubmitting = true); // Lock button
                     final provider = Provider.of<TaskProvider>(context, listen: false);
                     await provider.addTask(titleController.text, customDate: date);
                     
                     if (context.mounted) Navigator.pop(context);
                  }
                }, 
                child: isSubmitting 
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Adicionar'),
              );
             }
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final days = _getDaysInWeek();
    final taskProvider = Provider.of<TaskProvider>(context);

      return Row(
      children: [
        // --- LEFT SIDE ---
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(right: 4),
            child: Column(
              children: [
                Expanded(
                  flex: 3,
                  child: Row(
                    children: [
                      // Distinct Pastel Colors (Requested Palette)
                      Expanded(child: _buildDayColumn(days[0], const Color(0xFFFADADA), "Segunda", taskProvider)), // Pink
                      Expanded(child: _buildDayColumn(days[1], const Color(0xFFD6E6BE), "Terça", taskProvider)), // Green
                      Expanded(child: _buildDayColumn(days[2], const Color(0xFFAECCCC), "Quarta", taskProvider)), // Teal
                    ],
                  ),
                ),
                // Editable Note (Transparent bg, colored container)
                 _buildNoteSection(const Color(0xFFDAD8D3), "Notas da Semana", 'LEFT', taskProvider), // Grey
              ],
            ),
          ),
        ),

        // --- RIGHT SIDE ---
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(left: 4),
            child: Column(
              children: [
                Expanded(
                  flex: 3,
                  child: Row(
                    children: [
                      Expanded(child: _buildDayColumn(days[3], const Color(0xFFEDB1B1), "Quinta", taskProvider)), // Salmon
                      Expanded(child: _buildDayColumn(days[4], const Color(0xFFECE9AC), "Sexta", taskProvider)), // Yellow
                      Expanded(
                        child: Column(
                          children: [
                             Expanded(child: _buildDayColumn(days[5], const Color(0xFFC8B1C0), "Sábado", taskProvider)), // Purple/Grey
                             const SizedBox(height: 8),
                             Expanded(child: _buildDayColumn(days[6], const Color(0xFFC8B1C0), "Domingo", taskProvider)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Editable Note
                 _buildNoteSection(const Color(0xFFDAD8D3), "Notas da Semana", 'RIGHT', taskProvider), // Grey
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildNoteSection(Color color, String hint, String side, TaskProvider provider) {
    final content = provider.getWeeklyNote(widget.year, widget.monthIndex, widget.weekIndex, side);
    final noteKey = "weekly_note_${widget.year}_${widget.monthIndex}_${widget.weekIndex}_$side";

    return Container(
      height: 120,
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color, 
        border: Border.all(color: Colors.black.withOpacity(0.05)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           Text(hint, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black.withOpacity(0.4))),
           Expanded(
             child: FormattedTextEditor(
                key: ValueKey(noteKey),
                initialContent: content,
                placeholder: '',
                isCompact: true,
                onChanged: (val) => _saveNote(side, val),
             ),
           ),
        ],
      ),
    );
  }

  Widget _buildDayColumn(DateTime date, Color color, String weekDayName, TaskProvider provider) {
    // Filter tasks for this day
    final dayTasks = provider.tasks.where((t) => 
      t.dueDate.year == date.year && 
      t.dueDate.month == date.month && 
      t.dueDate.day == date.day
    ).toList();
    
    final dayEvents = provider.getEventsForDay(date);
    final totalItems = dayEvents.length + dayTasks.length;

    return GestureDetector(
      onTap: () => widget.onDaySelected(date), // Navigate to Day View
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: color,
          border: Border.all(color: Colors.black.withOpacity(0.05)),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header with Add Button
            Container(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       Text(
                        weekDayName.toUpperCase(),
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black45, letterSpacing: 0.5),
                      ),
                      Text(
                        "${date.day}", 
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)
                      ),
                     ],
                   ),
                  
                  InkWell(
                    onTap: () => _showAddTaskDialog(date),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Icon(Icons.add_circle, size: 20, color: Colors.grey.shade400),
                    ),
                  )
                ],
              ), 
            ),
            const Divider(height: 1, color: Colors.black12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(6.0),
                child: totalItems == 0
                  ? null 
                  : ListView.builder(
                      itemCount: totalItems,
                      itemBuilder: (context, index) {
                         // Show Events first, then Tasks
                        if (index < dayEvents.length) {
                           final event = dayEvents[index];
                           return Container(
                            margin: const EdgeInsets.only(bottom: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE0F2FE),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.blue.withOpacity(0.2)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 2, height: 12, 
                                  color: Colors.blue,
                                  margin: const EdgeInsets.only(right: 6),
                                ),
                                Expanded(
                                  child: Text(
                                    event.title,
                                    style: const TextStyle(
                                      fontSize: 10, 
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                InkWell(
                                  onTap: () {
                                     if(event.id != null) provider.deleteEvent(event.id!);
                                  },
                                  child: const Icon(Icons.close, size: 12, color: Colors.grey),
                                ),
                              ],
                            ),
                           );
                        } else {
                          final task = dayTasks[index - dayEvents.length];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.black.withOpacity(0.05)),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(top: 2.0),
                                  child: Container(
                                    width: 8, height: 8,
                                    decoration: BoxDecoration(
                                      border: Border.all(color: task.isCompleted ? Colors.grey : Colors.pinkAccent),
                                      shape: BoxShape.circle,
                                      color: task.isCompleted ? Colors.grey : null,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    task.title,
                                    style: TextStyle(
                                      fontSize: 10,
                                      height: 1.3,
                                      color: task.isCompleted ? Colors.grey : Colors.black87,
                                      decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                InkWell(
                                  onTap: () {
                                     // Verify ID exists before deleting
                                     if(task.id != null) provider.deleteTask(task.id!);
                                  },
                                  child: const Icon(Icons.close, size: 12, color: Colors.grey),
                                ),
                              ],
                            ),
                          );
                        }
                      },
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
