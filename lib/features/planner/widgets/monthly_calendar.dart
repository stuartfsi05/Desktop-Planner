import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:amanda_planner/features/planner/providers/task_provider.dart';

class MonthlyCalendar extends StatelessWidget {
  final int monthIndex; // 0 = Jan, 11 = Dec
  final int year;
  final Function(DateTime) onDaySelected;
  final Function(int) onWeekSelected; // Callback for week tabs

  const MonthlyCalendar({
    super.key,
    required this.monthIndex,
    required this.year,
    required this.onDaySelected,
    required this.onWeekSelected,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Calculate Calendar Data
    final firstDayOfMonth = DateTime(year, monthIndex + 1, 1);
    final daysInMonth = DateUtils.getDaysInMonth(year, monthIndex + 1);
    
    // Grid starts Monday
    final int firstWeekday = firstDayOfMonth.weekday;
    // Mon(1)->0, Tue(2)->1 ... Sun(7)->6
    final int offset = firstWeekday - 1;
    
    final int totalSlots = daysInMonth + offset;
    // Force 6 rows to standardize cell size
    final int totalWeeks = 6;

    final List<String> weekDays = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];
    final theme = Theme.of(context);

    return Column(
      children: [
        // Header Row
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Row(
            children: [
               const SizedBox(width: 48), // Space for Week Tab
               Expanded(
                 child: Row(
                   mainAxisAlignment: MainAxisAlignment.spaceAround,
                   children: weekDays.map((day) => Expanded(
                     child: Center(
                       child: Text(
                         day.toUpperCase(), 
                         style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.grey)
                        ),
                     ),
                   )).toList(),
                 ),
               ),
            ],
          ),
        ),
        const Divider(height: 1),
        // Week Rows - Full Screen (Expanded)
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Column(
              children: List.generate(totalWeeks, (weekIndex) {
                 return Expanded(
                   child: Padding(
                     padding: const EdgeInsets.only(bottom: 8.0),
                     child: _buildWeekRow(context, weekIndex, offset, daysInMonth),
                   ),
                 );
              }),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWeekRow(BuildContext context, int weekIndex, int offset, int daysInMonth) {
     final theme = Theme.of(context);
     final weekColor = [
        Colors.blue.shade400,
        Colors.teal.shade400,
        Colors.orange.shade400,
        Colors.deepPurple.shade400,
        Colors.pink.shade400,
        Colors.cyan.shade400,
     ][weekIndex % 6];

    // Check if this week has ANY days in the current month
    bool hasDays = false;
    for (int i = 0; i < 7; i++) {
        int gIndex = (weekIndex * 7) + i;
        int dNum = gIndex - offset + 1;
        if (dNum >= 1 && dNum <= daysInMonth) {
            hasDays = true;
            break;
        }
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. COUPLED WEEK TAB (Only if week has days)
        if (hasDays)
          Tooltip(
            message: "Ver Semana ${weekIndex + 1}",
            child: InkWell(
              onTap: () => onWeekSelected(weekIndex),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 24, 
                margin: const EdgeInsets.only(right: 16),
                decoration: BoxDecoration(
                  color: weekColor,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(color: weekColor.withOpacity(0.4), blurRadius: 4, offset: const Offset(0,2))
                  ]
                ),
              ),
            ),
          )
        else
          // Maintain spacing even if hidden
          const SizedBox(width: 40),
        
        // 2. DAYS OF THE WEEK
        Expanded(
          child: Row(
            children: List.generate(7, (dayIndex) {
               int globalIndex = (weekIndex * 7) + dayIndex;
               int dayNum = globalIndex - offset + 1;
               
               if (dayNum < 1 || dayNum > daysInMonth) {
                 return const Expanded(child: SizedBox()); // Empty slot
               }
               
               final date = DateTime(year, monthIndex + 1, dayNum);
               final isToday = DateUtils.isSameDay(date, DateTime.now());
               
               return Expanded(
                 child: InkWell(
                    onTap: () => onDaySelected(date),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      margin: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                         color: isToday ? theme.colorScheme.primary.withOpacity(0.05) : Colors.white,
                         border: isToday 
                            ? Border.all(color: theme.colorScheme.primary.withOpacity(0.5)) 
                            : Border.all(color: Colors.grey.shade200),
                         borderRadius: BorderRadius.circular(8),
                         boxShadow: [
                            if (!isToday)
                              BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 2, offset: const Offset(0,1))
                         ]
                      ),
                      alignment: Alignment.topLeft, 
                      padding: const EdgeInsets.all(6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Day Number
                          Text(
                            "$dayNum",
                            style: isToday 
                              ? theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)
                              : theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade700),
                          ),
                          const SizedBox(height: 4),
                          // Events List
                          Expanded(
                            child: Consumer<TaskProvider>(
                              builder: (context, provider, _) {
                                final events = provider.getEventsForDay(date);
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: events.take(4).map((e) => Padding( // Increased take since we have more height
                                    padding: const EdgeInsets.only(bottom: 2.0),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 4, height: 4,
                                          decoration: BoxDecoration(
                                            color: theme.colorScheme.secondary,
                                            shape: BoxShape.circle
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            e.title,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 9, 
                                              color: Colors.grey.shade800,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )).toList(),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                 ),
               );
            }),
          ),
        ),
      ],
    );
  }
}
