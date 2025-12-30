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
        child: Stack(
          clipBehavior: Clip.none, // Allow spirals to hang over the edge
          children: [
            Container(
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
              child: Row(
                children: [
                  // 2. Padding/Space for Spine (Visual logic for spirals is now external)
                  const SizedBox(width: 15),

                  // 3. Main Paper Area
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: paperColor,
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

                  // 4. Right Tabs (Months)
                  SizedBox(
                    width: 50,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center, 
                      crossAxisAlignment: CrossAxisAlignment.start, 
                      children: [
                         const SizedBox(height: 40), 
                         Expanded(child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: _buildMonthTabs(context),
                         )),
                         const SizedBox(height: 40), 
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // 5. SPIRAL BINDING OVERLAY (EXTERNAL)
            // Positioned relative to the binder, but can overflow into the gray area
            Positioned(
              left: 10, // Adjust to overlap the binder edge perfectly
              top: 24,
              bottom: 24,
              width: 80, 
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(
                  12, 
                  (index) => Container(
                    height: 50, // Height increased to 50px as per design tip to avoid clipping
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
    return CustomPaint(
      size: const Size(80, 45), // Expanded size for wider loops
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
    // --- CONSTANTES DE GEOMETRIA (Física de Encadernação 3D) ---
    const double holeX = 48.0; 
    final double holeY = size.height * 0.4; // Ponto de saída do papel
    const double holeRadius = 4.0;
    
    // spineX: O ponto mais à esquerda (na mesa)
    const double spineX = -35.0; 
    const double archHeight = 26.0;

    // Limites Físicos (Locais) do Fichário
    const binderEdgeLocal = 14.0; // Onde o couro rosa começa
    const paperEdgeLocal = 29.0;  // Onde a folha branca começa

    // --- CAMADA 1: O Furo no Papel ---
    final holePaint = Paint()
      ..color = const Color(0xFF111111)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(holeX, holeY), holeRadius, holePaint);

    final holeRim = Paint()
      ..color = Colors.white.withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    canvas.drawArc(Rect.fromCircle(center: Offset(holeX, holeY), radius: holeRadius), 0.2, 2.7, false, holeRim);

    // --- DEFINIÇÃO DOS CAMINHOS (IDAS E VOLTAS) ---
    
    // 1. ARCO SUPERIOR (A PARTE QUE VAI POR CIMA)
    // Sai do furo, passa sobre o couro e vai para a mesa
    final upperPath = Path();
    upperPath.moveTo(holeX, holeY);
    upperPath.cubicTo(
      holeX + 12, holeY - 4,          // CP1: Saída do furo
      spineX + 20, holeY - archHeight, // CP2: Topo do arco (visível sobre o rosa)
      spineX, holeY - (archHeight * 0.3) // Ponto Externo (na mesa)
    );

    // 2. ARCO INFERIOR (A PARTE QUE VAI POR BAIXO - O RETORNO)
    // Volta da mesa e mergulha atrás da capa rosa
    final lowerPath = Path();
    lowerPath.moveTo(spineX, holeY - (archHeight * 0.3));
    lowerPath.cubicTo(
      spineX - 10, holeY + (archHeight * 0.2), // Faz a curva externa
      binderEdgeLocal - 5, holeY + (archHeight * 0.6), // Mirando para trás da capa
      binderEdgeLocal, holeY + (archHeight * 0.5) // Mergulha na borda da capa
    );

    // --- SETUP DE MATERIAIS ---
    const roseDark = Color(0xFF8B5E57);
    const roseMid = Color(0xFFE4B2A3);
    const roseLight = Color(0xFFFFF7F2); 

    // Paint para a Sombra
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5.0);

    // Paint para o Metal
    final metalGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [roseDark, roseMid, roseLight, roseMid, roseDark],
      stops: const [0.0, 0.3, 0.5, 0.7, 1.0],
    );
    final metalPaint = Paint()
      ..shader = metalGradient.createShader(Rect.fromLTWH(spineX, holeY - archHeight, holeX - spineX, archHeight * 2))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0 
      ..strokeCap = StrokeCap.round;

    final highlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;

    // --- EXECUÇÃO DO DESENHO EM CAMADAS (ORDER OF DEPTH) ---

    // A. DESENHAR O ARCO INFERIOR (O que passa por baixo)
    // Clipamos para que ele só apareça na área da MESA
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(-150, -100, binderEdgeLocal + 150, 1000));
    
    // Desenha sombra do retorno
    canvas.save();
    canvas.translate(3, 4);
    canvas.drawPath(lowerPath, shadowPaint);
    canvas.restore();
    
    // Desenha o metal do retorno
    canvas.drawPath(lowerPath, metalPaint);
    canvas.restore();

    // B. DESENHAR O ARCO SUPERIOR (O que passa por cima)
    // Sem clipping universal, ele deve cobrir o papel e o couro
    canvas.save();
    
    // Desenha sombra da ida
    canvas.save();
    canvas.translate(4, 5);
    canvas.drawPath(upperPath, shadowPaint);
    canvas.restore();
    
    // Desenha o metal da ida
    canvas.drawPath(upperPath, metalPaint);
    
    // Desenha o brilho especular na ida
    canvas.save();
    canvas.translate(-0.5, -1.0);
    canvas.drawPath(upperPath, highlightPaint);
    canvas.restore();
    
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
