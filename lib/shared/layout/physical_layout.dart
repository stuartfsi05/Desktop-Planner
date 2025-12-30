import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PhysicalPlannerLayout extends StatelessWidget {
  final Widget child;
  final int selectedIndex;
  final Function(int) onTabSelected;
  final int selectedWeekIndex;
  final Function(int) onWeekSelected;
  final bool showLeftTabs;
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
    const Color deskColor = Color(0xFFDAD8D3);
    const Color binderColor = Color(0xFFEA9DAB);
    const Color paperColor = Color(0xFFFAFAFA);
    final Color paperShadow = Colors.black.withValues(alpha: 0.1);

    return Scaffold(
      backgroundColor: deskColor,
      body: Center(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              constraints: const BoxConstraints(maxWidth: 1400, maxHeight: 950),
              margin: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: binderColor,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 30,
                    offset: const Offset(0, 15),
                  ),
                ],
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFF2B5C0),
                    Color(0xFFEA9DAB),
                    Color(0xFFD68A98),
                  ],
                ),
              ),
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Row(
                children: [
                  const SizedBox(width: 15),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: paperColor,
                        boxShadow: [
                          BoxShadow(
                            color: paperShadow,
                            blurRadius: 8,
                            offset: const Offset(2, 0),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.zero,
                        child: Stack(
                          children: [
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
                            Padding(
                              padding: EdgeInsets.only(
                                left: showLeftTabs ? 60.0 : 30.0,
                                top: 50.0,
                                right: 30,
                                bottom: 20,
                              ),
                              child: child,
                            ),
                            if (onBack != null || onForward != null)
                              Positioned(
                                left: showLeftTabs ? 65 : 34,
                                top: 16,
                                child: Row(
                                  children: [
                                    if (onBack != null)
                                      _buildNavButton(
                                        Icons.arrow_back_rounded,
                                        onBack,
                                      ),
                                    if (onBack != null && onForward != null)
                                      const SizedBox(width: 12),
                                    if (onForward != null)
                                      _buildNavButton(
                                        Icons.arrow_forward_rounded,
                                        onForward,
                                      ),
                                  ],
                                ),
                              ),
                            if (showLeftTabs)
                              Positioned(
                                left: 0,
                                top: 120,
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
                  SizedBox(
                    width: 50,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 40),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: _buildMonthTabs(context),
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 10,
              top: 24,
              bottom: 24,
              width: 80,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(
                  12,
                  (index) => Container(
                    height: 50,
                    alignment: Alignment.center,
                    child: _buildSpiralRing(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpiralRing() {
    return const CustomPaint(size: Size(80, 45), painter: _SpiralPainter());
  }

  List<Widget> _buildMonthTabs(BuildContext context) {
    const months = [
      'Jan',
      'Fev',
      'Mar',
      'Abr',
      'Mai',
      'Jun',
      'Jul',
      'Ago',
      'Set',
      'Out',
      'Nov',
      'Dez',
    ];
    const colors = [
      Color(0xFFFADADA),
      Color(0xFFD6E6BE),
      Color(0xFFAECCCC),
      Color(0xFFEDB1B1),
      Color(0xFFECE9AC),
      Color(0xFFC8B1C0),
      Color(0xFFFADADA),
      Color(0xFFD6E6BE),
      Color(0xFFAECCCC),
      Color(0xFFEDB1B1),
      Color(0xFFECE9AC),
      Color(0xFFC8B1C0),
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
          isSelected: isSelected,
        ),
      );
    });
  }

  List<Widget> _buildWeekTabs(BuildContext context) {
    const weeks = ['S1', 'S2', 'S3', 'S4', 'S5'];

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
          textColor: isSelected ? Colors.white : Colors.black87,
        ),
      );
    });
  }

  Widget _buildTab(
    BuildContext context,
    int index,
    String label,
    Color color, {
    required bool isLeft,
    required bool isSelected,
    VoidCallback? onTap,
    Color? textColor,
  }) {
    final tapHandler = onTap ?? () => onTabSelected(index);

    return GestureDetector(
      onTap: tapHandler,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        margin: EdgeInsets.only(
          bottom: 1,
          right: isLeft ? 0 : (isSelected ? 0 : 4),
        ),
        width: 50,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.only(
            topLeft: isLeft ? const Radius.circular(8) : Radius.zero,
            bottomLeft: isLeft ? const Radius.circular(8) : Radius.zero,
            topRight: isLeft ? Radius.zero : const Radius.circular(10),
            bottomRight: isLeft ? Radius.zero : const Radius.circular(10),
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(2, 2),
              ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          label.toUpperCase(),
          textAlign: TextAlign.center,
          style: GoogleFonts.lato(
            fontWeight: FontWeight.bold,
            color: textColor ?? const Color(0xFF24555D),
            fontSize: 10,
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
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, size: 15, color: const Color(0xFF24555D)),
        ),
      ),
    );
  }
}

class _SpiralPainter extends CustomPainter {
  const _SpiralPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const double holeX = 48.0;
    final double holeY = size.height * 0.4;
    const double holeRadius = 4.0;
    const double spineX = -35.0;
    const double archHeight = 26.0;
    const double binderEdge = 14.0;

    final Paint holePaint = Paint()
      ..color = const Color(0xFF111111)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(holeX, holeY), holeRadius, holePaint);

    final Paint holeRim = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    canvas.drawArc(
      Rect.fromCircle(center: Offset(holeX, holeY), radius: holeRadius),
      0.2,
      2.7,
      false,
      holeRim,
    );

    final Path upperPath = Path();
    upperPath.moveTo(holeX, holeY);
    upperPath.cubicTo(
      holeX + 12,
      holeY - 4,
      spineX + 20,
      holeY - archHeight,
      spineX,
      holeY - (archHeight * 0.3),
    );

    final Path lowerPath = Path();
    lowerPath.moveTo(spineX, holeY - (archHeight * 0.3));
    lowerPath.cubicTo(
      spineX - 10,
      holeY + (archHeight * 0.4),
      binderEdge - 10,
      holeY + (archHeight * 0.9),
      binderEdge,
      holeY + (archHeight * 0.8),
    );

    const roseDark = Color(0xFF8B5E57);
    const roseMid = Color(0xFFE4B2A3);
    const roseLight = Color(0xFFFFF7F2);

    final Paint shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5.0);

    const LinearGradient metalGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [roseDark, roseMid, roseLight, roseMid, roseDark],
      stops: [0.0, 0.3, 0.5, 0.7, 1.0],
    );

    final Paint metalPaint = Paint()
      ..shader = metalGradient.createShader(
        Rect.fromLTWH(
          spineX,
          holeY - archHeight,
          holeX - spineX,
          archHeight * 2,
        ),
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round;

    final Paint highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;

    // Drawing Lower Arc (Behind Binder)
    canvas.save();
    canvas.clipRect(const Rect.fromLTWH(-150, -100, binderEdge + 150, 1000));
    canvas.save();
    canvas.translate(3, 4);
    canvas.drawPath(lowerPath, shadowPaint);
    canvas.restore();
    canvas.drawPath(lowerPath, metalPaint);
    canvas.restore();

    // Drawing Upper Arc (Over Binder)
    canvas.save();
    canvas.save();
    canvas.translate(4, 5);
    canvas.drawPath(upperPath, shadowPaint);
    canvas.restore();
    canvas.drawPath(upperPath, metalPaint);
    canvas.save();
    canvas.translate(-0.5, -1.0);
    canvas.drawPath(upperPath, highlightPaint);
    canvas.restore();
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
