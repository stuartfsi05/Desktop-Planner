import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'task_provider.dart';

class WelcomeScreen extends StatefulWidget {
  final VoidCallback onDismiss;

  const WelcomeScreen({super.key, required this.onDismiss});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  late Timer _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      setState(() {
        _now = DateTime.now();
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _getGreeting() {
    final hour = _now.hour;
    if (hour < 12) return "Bom dia, Amanda.";
    if (hour < 18) return "Boa tarde, Amanda.";
    return "Boa noite, Amanda.";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: widget.onDismiss,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Cute Background (Pink Gradient & Pattern)
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFFFF0F5), // Lavender Blush (Light Pink)
                    Color(0xFFFFE4E1), // Misty Rose
                    Color(0xFFFFB6C1), // Light Pink
                  ],
                ),
              ),
            ),
            // Optional: You could add a subtle pattern overlay here if desired using a repeated icon or image asset
            // For now, we use a simple polkadots-like effect using a custom painter or just the gradient
            Positioned(
              right: -50,
              top: -50,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              left: -80,
              bottom: -80,
              child: Container(
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
              ),
            ),

            // 2. Main Content Centered/Layout
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 80.0, vertical: 60.0),
              child: Row(
                children: [
                  // LEFT SIDE: Greeting & Date
                  Expanded(
                    flex: 3,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                         Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(color: Colors.pink.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4)),
                            ],
                          ),
                          child: Text(
                            DateFormat('EEEE, dd/MM/yyyy', 'pt_BR').format(_now).toUpperCase(),
                            style: const TextStyle(
                              color: Color(0xFFD81B60), // Deep Pink
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                        Text(
                          DateFormat('HH:mm').format(_now),
                          style: const TextStyle(
                            color: Color(0xFF880E4F), // Dark Pink/Magenta
                            fontSize: 100,
                            fontWeight: FontWeight.w300,
                            fontFamily: 'Segoe UI',
                            height: 0.9,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          _getGreeting(),
                          style: const TextStyle(
                            color: Color(0xFF4A4A4A), // Soft Black
                            fontSize: 42,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                         const SizedBox(height: 10),
                         const Text(
                          "Vamos fazer hoje um dia incrível!",
                          style: TextStyle(
                            color: Color(0xFF757575),
                            fontSize: 20,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // RIGHT SIDE: Memo Pad (Tasks)
                  Expanded(
                    flex: 2,
                    child: Consumer<TaskProvider>(
                      builder: (context, provider, child) {
                        final highPriorityTasks = provider.tasks
                            .where((t) => !t.isCompleted && t.priority > 0)
                            .take(4)
                            .toList();

                        return Transform.rotate(
                          angle: 0.02, // Slight tilt for "sticky note" feel
                          child: Container(
                            margin: const EdgeInsets.all(20),
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.red.withOpacity(0.1),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                              border: Border.all(color: const Color(0xFFFFC1E3), width: 2), // Pale Pink Border
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFFF80AB), // Accent Pink
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.favorite, color: Colors.white, size: 20),
                                    ),
                                    const SizedBox(width: 16),
                                    const Text(
                                      "Foco Principal",
                                      style: TextStyle(
                                        color: Color(0xFF880E4F),
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),
                                if (highPriorityTasks.isEmpty)
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 20.0),
                                    child: Text(
                                      "Tudo tranquilo por enquanto! 🌸",
                                        style: TextStyle(color: Colors.black54, fontStyle: FontStyle.italic),
                                    ),
                                  )
                                else
                                  ...highPriorityTasks.map((task) => Padding(
                                    padding: const EdgeInsets.only(bottom: 16.0),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.check_circle_outline, color: Color(0xFFF48FB1), size: 18),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            task.title,
                                            style: const TextStyle(
                                              color: Color(0xFF424242),
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // 3. Bottom CTA
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 40.0),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 1.0, end: 0.0),
                  duration: const Duration(seconds: 1),
                  curve: Curves.easeInOut,
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: 0.5 + (value * 0.5), // Range 0.5 to 1.0
                      child: child,
                    );
                  },
                  child: const Text(
                    "Toque em qualquer lugar para começar ✨",
                    style: TextStyle(
                      color: Color(0xFF880E4F),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

