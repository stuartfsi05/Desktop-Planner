import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PhysicalPlannerLayout extends StatelessWidget {
  final Widget child;
  final int selectedIndex; // Month index (Right tabs)
  final Function(int) onTabSelected;
  
  // Weekly Navigation (Left tabs)
  final int selectedWeekIndex; // 0-4
  final Function(int) onWeekSelected;
  final bool showLeftTabs; // Control visibility

  // Navigation Buttons
  final VoidCallback? onBack;
  final VoidCallback? onForward;

  const PhysicalPlannerLayout({
    super.key,
    required this.child,
    required this.selectedIndex,
    required this.onTabSelected,
    this.selectedWeekIndex = 0,
    required this.onWeekSelected,
    this.showLeftTabs = true,
    this.onBack,
    this.onForward,
  });

  @override
  Widget build(BuildContext context) {
    // New Palette
    final deskColor = const Color(0xFFDAD8D3); // Warm Grey Background
    final binderColor = const Color(0xFFEA9DAB); // Pink Binder
    final paperColor = const Color(0xFFFAFAFA); // White Paper
    final paperShadow = Colors.black.withOpacity(0.1);

    return Scaffold(
      backgroundColor: deskColor,
      body: Center(
        child: Container(
          // Limits the binder max size for large screens
          constraints: const BoxConstraints(maxWidth: 1400, maxHeight: 950),
          margin: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: binderColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 30,
                offset: const Offset(0, 15),
              ),
            ],
            // Subtle gradient for binder texture
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFF2B5C0), // Lighter Pink
                Color(0xFFEA9DAB), // Base Pink
                Color(0xFFD68A98), // Darker Pink
              ],
            )
          ),
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Stack(
            children: [
              // MAIN ROW CONTENT
              Row(
                children: [
                  // 2. Padding/Space for Spine (Visual logic moved to Occlusion layer)
                  const SizedBox(width: 30),

                  // 3. Main Paper Area
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: paperColor,
                        // borderRadius: BorderRadius.zero, 
                        boxShadow: [
                          BoxShadow(color: paperShadow, blurRadius: 8, offset: const Offset(2, 0)),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.zero,
                        child: Stack(
                          children: [
                             // subtle texture
                            Positioned.fill(
                              child: Opacity(
                                opacity: 0.03,
                                child: Image.network(
                                  'https://www.transparenttextures.com/patterns/lined-paper.png', 
                                  repeat: ImageRepeat.repeat,
                                  errorBuilder: (c, e, s) => const SizedBox(),
                                ),
                              ),
                            ),
                            
                            // LEFT TABS (Weeks) - Inside the paper?
                            // User request: "Deixar as abas da lateral direitas coladas no quadro branco"
                            // Left tabs are internal navigation. Let's keep them as is or adjust if requested.
                            // Assuming "Abas da lateral direita" refers to Months.
                            
                            // Content with padding for tabs
                            Padding(
                              padding: EdgeInsets.only(left: showLeftTabs ? 60.0 : 30.0, top: 50.0, right: 30, bottom: 20),
                              child: child,
                            ),
                            
                            // NAVIGATION BUTTONS (Top Left)
                            if (onBack != null || onForward != null)
                            Positioned(
                              left: showLeftTabs ? 65 : 34,
                              top: 16, 
                              child: Row(
                                children: [
                                  if (onBack != null) _buildNavButton(Icons.arrow_back_rounded, onBack),
                                  if (onBack != null && onForward != null) const SizedBox(width: 12),
                                  if (onForward != null) _buildNavButton(Icons.arrow_forward_rounded, onForward),
                                ],
                              ),
                            ),

                            // LEFT TABS (Weeks)
                            if (showLeftTabs)
                              Positioned(
                                left: 0,
                                top: 120, // Align with calendar rows
                                bottom: 80,
                                width: 50, 
                                child: Column(
                                   mainAxisAlignment: MainAxisAlignment.center,
                                   children: _buildWeekTabs(context),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // 4. Right Tabs (Months) - "Coladas no quadro branco"
                  // We remove the SizedBox width constraint or ensure the tabs fill it completely without margin
                  SizedBox(
                    width: 50,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center, // Center vertically with margin
                      crossAxisAlignment: CrossAxisAlignment.start, // Align to left (touching paper)
                      children: [
                         const SizedBox(height: 40), // Top margin "binder style"
                         Expanded(child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: _buildMonthTabs(context),
                         )),
                         const SizedBox(height: 40), // Bottom margin
                      ],
                    ),
                  ),
                ],
              ),
              
              // 5. SPIRAL BINDING OVERLAY
              Positioned(
                left: 0, 
                top: 0,
                bottom: 0,
                width: 60, 
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(
                    12, 
                    (index) => _buildSpiralRing(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSpiralRing() {
    return CustomPaint(
      size: const Size(60, 45), 
      painter: _SpiralPainter(),
    );
  }

  // --- MONTH TABS (RIGHT) ---
  List<Widget> _buildMonthTabs(BuildContext context) {
    final months = [
      'Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun',
      'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'
    ];
    // Specific Palette for Months
    final colors = [
       const Color(0xFFFADADA), // Pink
       const Color(0xFFD6E6BE), // Green
       const Color(0xFFAECCCC), // Teal
       const Color(0xFFEDB1B1), // Salmon
       const Color(0xFFECE9AC), // Yellow
       const Color(0xFFC8B1C0), // Purple/Grey
       const Color(0xFFFADADA), // Repeat...
       const Color(0xFFD6E6BE),
       const Color(0xFFAECCCC),
       const Color(0xFFEDB1B1),
       const Color(0xFFECE9AC),
       const Color(0xFFC8B1C0),
    ];
    
    return List.generate(12, (index) {
      final isSelected = selectedIndex == index;
      return Expanded(
        child: _buildTab(
          context, 
          index, 
          months[index], 
          colors[index], 
          isLeft: false, 
          isSelected: isSelected
        ),
      );
    });
  }

  // --- WEEK TABS (LEFT) ---
  List<Widget> _buildWeekTabs(BuildContext context) {
      final weeks = ['S1', 'S2', 'S3', 'S4', 'S5'];
      // Weeks colors: reusing month palette or simple? 
      // User request only specified RIGHT tabs palette. Let's keep weeks simple or match.
      // Let's match the theme.
      
      return List.generate(5, (index) {
          final isSelected = selectedWeekIndex == index;
          return Expanded(
            child: _buildTab(
              context, 
              index, 
              weeks[index], 
              isSelected ? const Color(0xFF24555D) : const Color(0xFFDAD8D3), 
              isLeft: true, 
              isSelected: isSelected, 
              onTap: () => onWeekSelected(index),
              textColor: isSelected ? Colors.white : Colors.black87
            ),
          );
      });
  }

  Widget _buildTab(BuildContext context, int index, String label, Color color, {required bool isLeft, required bool isSelected, VoidCallback? onTap, Color? textColor}) {
    final tapHandler = onTap ?? () => onTabSelected(index);

    return GestureDetector(
      onTap: tapHandler,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        margin: EdgeInsets.only(
          bottom: 1, // Tiny gap for separate tabs feel
          left: isLeft ? 0 : 0, // No margin, flush with paper
          right: isLeft ? 0 : (isSelected ? 0 : 4), // Selected tabs stick out more? Or just flush.
        ), 
        // If right tab:
        // Flush left (touching paper). 
        width: 50,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.only(
            topLeft: isLeft ? const Radius.circular(8) : Radius.zero,
            bottomLeft: isLeft ? const Radius.circular(8) : Radius.zero,
            topRight: isLeft ? Radius.zero : const Radius.circular(10), // Rounded outer edge
            bottomRight: isLeft ? Radius.zero : const Radius.circular(10),
          ),
          boxShadow: [
            if (isSelected)
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(2, 2),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: RotatedBox(
          quarterTurns: 0, // Keep text horizontal or vertical? Usually abbreviated months are readable horizontal if short.
          // Or rotate -1 for vertical tabs.
          // Code had RotatedBox but quarterTurns 0.
          child: Text(
            label.toUpperCase(),
            textAlign: TextAlign.center,
            style: GoogleFonts.lato(
              fontWeight: FontWeight.bold,
              color: textColor ?? const Color(0xFF24555D), // Dark Teal Text
              fontSize: 10,
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildNavButton(IconData icon, VoidCallback? onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey.shade300),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              )
            ]
          ),
          child: Icon(icon, size: 15, color: const Color(0xFF24555D)),
        ),
      ),
    );
  }
}

class _SpiralPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Save state for clipping
    canvas.save();

    // Move clipping to the left (X=8) to allow the ring to be visible over the cover
    canvas.clipRect(Rect.fromLTWH(8, -size.height, size.width - 8, size.height * 2));

    // 1. Hole Settings
    final holeCenter = Offset(size.width - 12, size.height / 2);
    final holeRadius = 4.0;
    
    // 2. Realistic "Punched" Hole
    final holePaint = Paint()
      ..color = const Color(0xFF2D2D2D) // Dark internal hole
      ..style = PaintingStyle.fill;
    canvas.drawCircle(holeCenter, holeRadius, holePaint);

    // Paper thickness highlight (white rim at the bottom)
    final rimPaint = Paint()
      ..color = Colors.white.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawArc(
      Rect.fromCircle(center: holeCenter, radius: holeRadius),
      0.2, 2.8, 
      false,
      rimPaint,
    );

    // 3. Drop Shadow on Paper (Drawn BEFORE the metal)
    final shadowPath = Path();
    shadowPath.moveTo(size.width * 0.45, size.height * 0.4);
    shadowPath.quadraticBezierTo(
      size.width * 0.85, 0, 
      holeCenter.dx + 1.5, holeCenter.dy + 1.5
    );

    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.5);
    canvas.drawPath(shadowPath, shadowPaint);

    // 4. Rose Gold Cylindrical Wire
    final path = Path();
    // Start deep behind the cover
    final startPoint = Offset(-5, size.height * 0.85); 
    final endPoint = holeCenter;
    
    // Wider elliptical path to cover more of the spine area
    final cp1 = Offset(size.width * -0.1, -size.height * 0.6); 
    final cp2 = Offset(size.width * 1.1, -size.height * 0.3);
    path.moveTo(startPoint.dx, startPoint.dy);
    path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, endPoint.dx, endPoint.dy);

    // High-Contrast Metallic Gradient (Rose Gold)
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        const Color(0xFF5E3A3A),
        const Color(0xFF8B5A5A),
        const Color(0xFFFFD1D1),
        const Color(0xFFE5989B),
        const Color(0xFF8B5A5A),
        const Color(0xFF5E3A3A),
      ],
      stops: const [0.0, 0.15, 0.45, 0.7, 0.85, 1.0],
    );

    final wirePaint = Paint()
      ..shader = gradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.8
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, wirePaint);

    // 5. Specular Reflection
    final shinePaint = Paint()
      ..color = Colors.white.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    final shinePath = Path();
    shinePath.moveTo(size.width * 0.15, size.height * 0.2); // Shine starts earlier
    shinePath.quadraticBezierTo(
      size.width * 0.5, -size.height * 0.25, 
      size.width * 0.85, size.height * 0.15
    );
    canvas.drawPath(shinePath, shinePaint);

    // Restore state after clipping
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
