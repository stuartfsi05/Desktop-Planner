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
    // Premium Palette
    final deskColor = const Color(0xFF1F2937); // Professional Dark Desk (Gray 900)
    final binderColor = const Color(0xFF4C1D95); // Deep Violet Leather
    final paperColor = const Color(0xFFF9FAFB); // Cool White Paper
    final paperShadow = Colors.black.withOpacity(0.08);

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
                color: Colors.black.withOpacity(0.5),
                blurRadius: 40,
                offset: const Offset(0, 20),
              ),
            ],
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF5B21B6), // Lighter Violet
                Color(0xFF4C1D95), // Deep Violet
                Color(0xFF2E1065), // Darkest Violet
              ],
            )
          ),
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Stack(
            children: [
              // MAIN ROW CONTENT
              Row(
                children: [
                  // 2. Binder Left Spine (Narrower for realism)
                  Container(
                    width: 30,
                    decoration: const BoxDecoration(
                      border: Border(
                        right: BorderSide(color: Colors.black12, width: 1),
                      ),
                    ),
                  ),

                  // 3. Main Paper Area
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: paperColor,
                        // borderRadius: BorderRadius.zero, 
                        boxShadow: [
                          BoxShadow(color: paperShadow, blurRadius: 10, offset: const Offset(4, 0)),
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
                            // Content with padding for tabs
                            Padding(
                              padding: EdgeInsets.only(left: showLeftTabs ? 70.0 : 30.0, top: 50.0, right: 20, bottom: 20),
                              child: child,
                            ),
                            
                            // NAVIGATION BUTTONS (Top Left)
                            if (onBack != null || onForward != null)
                            Positioned(
                              left: showLeftTabs ? 75 : 35,
                              top: 16, 
                              child: Row(
                                children: [
                                  if (onBack != null) _buildNavButton(Icons.arrow_back_rounded, onBack),
                                  if (onBack != null && onForward != null) const SizedBox(width: 12),
                                  if (onForward != null) _buildNavButton(Icons.arrow_forward_rounded, onForward),
                                ],
                              ),
                            ),

                            // LEFT TABS (Weeks) - Inside the paper
                            if (showLeftTabs)
                              Positioned(
                                left: 0,
                                top: 120, // Align with calendar rows
                                bottom: 80,
                                width: 60, 
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

                  // 4. Right Tabs (Months)
                  SizedBox(
                    width: 50,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: _buildMonthTabs(context),
                    ),
                  ),
                ],
              ),
              
              // 5. SPIRAL BINDING OVERLAY
              // Positioned over the seam. Spine is 30px.
              // Spiral widget is 60px wide. Center is 30px.
              // To align center (30) with seam (30), left must be 0 relative to the Stack.
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
      size: const Size(60, 45), // Slightly taller for roundness
      painter: _SpiralPainter(),
    );
  }



  // ... (keep _buildMonthTabs, _buildWeekTabs, _buildTab, _buildNavButton) ...
  // Need to make sure I don't delete them. I will copy them back in the ReplacementContent?
  // Or I can use StartLine/EndLine carefully.
  // The current tool call replaces everything from `Widget build` down to end of file roughly (Line 31 to 321).
  // Check the line range again.
  // Lines 200-321 contain the helper methods. I should include them or just target the build method + _buildRing replacement.
  
  // Re-writing helper methods to be safe:

  // --- MONTH TABS (RIGHT) ---
  List<Widget> _buildMonthTabs(BuildContext context) {
    final months = [
      'Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun',
      'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'
    ];
    
    return List.generate(12, (index) {
      final isSelected = selectedIndex == index;
      return Expanded(
        child: _buildTab(
          context, 
          index, 
          months[index], 
          isSelected ? const Color(0xFFF472B6) : const Color(0xFFDDD6FE), 
          isLeft: false, 
          isSelected: isSelected
        ),
      );
    });
  }

  // --- WEEK TABS (LEFT) ---
  List<Widget> _buildWeekTabs(BuildContext context) {
      final weeks = ['S1', 'S2', 'S3', 'S4', 'S5'];
      
      return List.generate(5, (index) {
          final isSelected = selectedWeekIndex == index;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: _buildTab(
              context, 
              index, 
              weeks[index], 
              isSelected ? const Color(0xFFF472B6) : const Color(0xFFBFDBFE), 
              isLeft: true, 
              isSelected: isSelected, 
              onTap: () => onWeekSelected(index)
            ),
          );
      });
  }

  Widget _buildTab(BuildContext context, int index, String label, Color color, {required bool isLeft, required bool isSelected, VoidCallback? onTap}) {
    final tapHandler = onTap ?? () => onTabSelected(index);

    return GestureDetector(
      onTap: tapHandler,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        margin: EdgeInsets.only(
          bottom: 2, 
          left: isLeft ? (isSelected ? 12 : 0) : (isSelected ? 0 : 8), // Pop out direction
          right: isLeft ? (isSelected ? 0 : 8) : 2,
        ), 
        width: 40,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.only(
            topLeft: isLeft ? const Radius.circular(8) : Radius.zero,
            bottomLeft: isLeft ? const Radius.circular(8) : Radius.zero,
            topRight: isLeft ? Radius.zero : const Radius.circular(8),
            bottomRight: isLeft ? Radius.zero : const Radius.circular(8),
          ),
          boxShadow: [
            if (isSelected)
            BoxShadow(
              color: color.withOpacity(0.4),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: RotatedBox(
            quarterTurns: isLeft ? 0 : 0, 
            child: Text(
              label.toUpperCase(),
              textAlign: TextAlign.center,
              style: GoogleFonts.lato(
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : Colors.black54,
                fontSize: 10,
              ),
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
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              )
            ]
          ),
          child: Icon(icon, size: 18, color: const Color(0xFF4B5563)),
        ),
      ),
    );
  }
}

class _SpiralPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Coordinate reference:
    // x=0 is the left edge of the binder cover.
    // x=30 is the edge of the paper (seam).
    // range x=30 to 60 is on the paper.
    
    // 1. Hole Shadow (The hole in the paper)
    final holeCenter = Offset(size.width - 12, size.height / 2);
    final holeRadius = 3.5;
    
    // Draw hole depth (dark circle)
    final holePaint = Paint()
      ..color = const Color(0xFF1A1A1A) 
      ..style = PaintingStyle.fill;
      
    // Draw a small "rim" highlight for 3D effect on the hole
    final rimPaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    canvas.drawCircle(holeCenter, holeRadius, holePaint);
    canvas.drawCircle(holeCenter, holeRadius, rimPaint);

    // 2. Wire Path - Rounder Loop
    final path = Path();
    
    // Start tucked behind the spine (x=2 to look like it's coming from depth)
    final startPoint = Offset(2, size.height * 0.75);
    final endPoint = holeCenter;
    
    // Control points for a more circular/round arc
    // CP1 is high and left. CP2 is high and right near the hole.
    final cp1 = Offset(size.width * 0.1, -size.height * 0.4); 
    final cp2 = Offset(size.width * 0.9, -size.height * 0.2);

    path.moveTo(startPoint.dx, startPoint.dy);
    path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, endPoint.dx, endPoint.dy);

    // 3. Shadow of the wire on the paper
    final shadowPath = Path();
    // Shadow starts roughly at the seam (x=30)
    shadowPath.moveTo(25, size.height * 0.85); 
    shadowPath.cubicTo(
       size.width * 0.5, size.height * 0.2, 
       size.width * 0.85, size.height * 0.5, 
       endPoint.dx + 3, endPoint.dy + 3
    );
    
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.5);
      
    canvas.drawPath(shadowPath, shadowPaint);

    // 4. The Gold Wire with enhanced metallic gradient
    final gradient = const LinearGradient(
      colors: [
         Color(0xFF78350F), // Dark Bronze (Start - tucked behind)
         Color(0xFFB45309), // Copper
         Color(0xFFFDE68A), // Highlight Gold (Brightest top)
         Color(0xFFF59E0B), // Standard Gold
         Color(0xFFB45309), // Copper
         Color(0xFF78350F), // Dark (Entering hole)
      ],
      stops: [0.0, 0.15, 0.4, 0.65, 0.85, 1.0],
      begin: Alignment.bottomLeft,
      end: Alignment.topRight,
    );
    
    final wirePaint = Paint()
      ..shader = gradient.createShader(Rect.fromLTWH(0, -size.height, size.width, size.height * 2))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.0
      ..strokeCap = StrokeCap.round;
    
    canvas.drawPath(path, wirePaint);

    // 5. Specular Shine (Adds that extra metallic "pop")
    final shinePaint = Paint()
      ..color = Colors.white.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
      
    final shinePath = Path();
    shinePath.moveTo(size.width * 0.3, size.height * 0.1);
    shinePath.quadraticBezierTo(size.width * 0.5, -size.height * 0.1, size.width * 0.7, size.height * 0.15);
    canvas.drawPath(shinePath, shinePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
