import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smart_money_tracker/core/constants/app_colors.dart';
import 'package:smart_money_tracker/core/constants/app_sizes.dart';

class PremiumPieChart extends StatefulWidget {
  final Map<String, double> categoryAmounts;
  final String currencySymbol;

  const PremiumPieChart({
    super.key,
    required this.categoryAmounts,
    this.currencySymbol = '₹',
  });

  @override
  State<PremiumPieChart> createState() => _PremiumPieChartState();
}

class _PremiumPieChartState extends State<PremiumPieChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Sort categories by amount descending
    final sortedEntries = widget.categoryAmounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (sortedEntries.isEmpty) {
      return const SizedBox.shrink();
    }

    // Process entries to have at most 3 slices (top 2 + other)
    List<_PieSectionData> sections = [];
    double totalVolume = 0;
    for (var entry in sortedEntries) {
      totalVolume += entry.value;
    }

    if (sortedEntries.length <= 3) {
      for (var entry in sortedEntries) {
        sections.add(_PieSectionData(category: entry.key, amount: entry.value));
      }
    } else {
      sections.add(
        _PieSectionData(
          category: sortedEntries[0].key,
          amount: sortedEntries[0].value,
        ),
      );
      sections.add(
        _PieSectionData(
          category: sortedEntries[1].key,
          amount: sortedEntries[1].value,
        ),
      );
      double otherAmount = 0;
      for (int i = 2; i < sortedEntries.length; i++) {
        otherAmount += sortedEntries[i].value;
      }
      sections.add(_PieSectionData(category: 'Others', amount: otherAmount));
    }

    // Assign colors matching mockup:
    // Section 0 (Largest) -> Vibrant Orange
    // Section 1 (2nd Largest) -> Deep Slate/Navy Blue
    // Section 2 (3rd/Others) -> Indigo Purple
    final List<Color> colors = [
      const Color(0xFFFF6C37), // Orange
      const Color(0xFF2E3253), // Navy Blue
      const Color(0xFF8338EC), // Purple
    ];

    for (int i = 0; i < sections.length; i++) {
      sections[i].color = colors[i % colors.length];
    }

    // Calculate percentages
    for (var section in sections) {
      section.percentage = totalVolume > 0 ? (section.amount / totalVolume) : 0;
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141614) : AppColors.white,
        borderRadius: AppSizes.boxBorderRadius,
        boxShadow: [
          BoxShadow(
            color: isDark
                ? AppColors.black.withOpacity(0.3)
                : AppColors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: isDark
              ? AppColors.white.withOpacity(0.04)
              : AppColors.black.withOpacity(0.02),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Analytics',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.white : const Color(0xFF1C1E1C),
                ),
              ),
              Text(
                'View All',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white54 : Colors.black38,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Pie Chart paint area
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return CustomPaint(
                size: const Size(double.infinity, 260),
                painter: _PremiumPieChartPainter(
                  sections: sections,
                  animationValue: _animation.value,
                  isDark: isDark,
                  currencySymbol: widget.currencySymbol,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PieSectionData {
  final String category;
  final double amount;
  double percentage;
  Color color;

  _PieSectionData({
    required this.category,
    required this.amount,
    this.percentage = 0.0,
    this.color = AppColors.textMuted,
  });
}

class _PremiumPieChartPainter extends CustomPainter {
  final List<_PieSectionData> sections;
  final double animationValue;
  final bool isDark;
  final String currencySymbol;

  _PremiumPieChartPainter({
    required this.sections,
    required this.animationValue,
    required this.isDark,
    required this.currencySymbol,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 + 10);
    const double baseRadius = 54.0;
    final double radius = baseRadius * (0.8 + 0.2 * animationValue);

    // Sort sections for structural rendering matching the mockup:
    // Navy (Index 1) is drawn at the top/right, starting from -90 degrees
    // Purple (Index 2) is drawn at the bottom/right
    // Orange (Index 0) is drawn at the left
    Map<int, _PieSectionData> sectionMap = {};
    for (int i = 0; i < sections.length; i++) {
      sectionMap[i] = sections[i];
    }

    double currentAngle = -math.pi / 2; // Start at -90 degrees (top)

    // Slices in structural order: Index 1 (Navy), Index 2 (Purple), Index 0 (Orange)
    List<int> paintOrder = [];
    if (sections.length == 1) {
      paintOrder = [0];
    } else if (sections.length == 2) {
      paintOrder = [1, 0];
    } else if (sections.length >= 3) {
      paintOrder = [1, 2, 0];
    }

    Map<int, _SliceLayout> layouts = {};

    // 1. Calculate angles and layouts
    for (var idx in paintOrder) {
      final section = sectionMap[idx];
      if (section == null) continue;

      final sweep = 2 * math.pi * section.percentage * animationValue;
      final middleAngle = currentAngle + sweep / 2;

      // Explode offset vector
      const double maxExplode = 6.0;
      final double explode = maxExplode * animationValue;
      final dx = explode * math.cos(middleAngle);
      final dy = explode * math.sin(middleAngle);
      final sliceCenter = Offset(center.dx + dx, center.dy + dy);

      layouts[idx] = _SliceLayout(
        startAngle: currentAngle,
        sweepAngle: sweep,
        middleAngle: middleAngle,
        center: sliceCenter,
        color: section.color,
        percentageText: '${(section.percentage * 100).toStringAsFixed(0)}%',
        category: section.category,
        amountText: '$currencySymbol${_formatAmount(section.amount)}',
      );

      currentAngle += sweep;
    }

    // 2. Draw shadows first for depth
    for (var idx in paintOrder) {
      final layout = layouts[idx];
      if (layout == null) continue;

      final shadowPaint = Paint()
        ..color = AppColors.black.withOpacity(isDark ? 0.25 : 0.08)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

      final path = Path()
        ..moveTo(layout.center.dx, layout.center.dy)
        ..arcTo(
          Rect.fromCircle(center: layout.center, radius: radius),
          layout.startAngle,
          layout.sweepAngle,
          false,
        )
        ..close();

      canvas.drawPath(path, shadowPaint);
    }

    // 3. Draw actual color slices
    for (var idx in paintOrder) {
      final layout = layouts[idx];
      if (layout == null) continue;

      final slicePaint = Paint()
        ..color = layout.color
        ..style = PaintingStyle.fill
        ..isAntiAlias = true;

      canvas.drawArc(
        Rect.fromCircle(center: layout.center, radius: radius),
        layout.startAngle,
        layout.sweepAngle,
        true,
        slicePaint,
      );
    }

    // 4. Draw percentage text inside slices
    for (var idx in paintOrder) {
      final layout = layouts[idx];
      if (layout == null || layout.sweepAngle < 0.2) continue;

      // Draw inside slice at 60% radius
      final textRadius = radius * 0.58;
      final tx = layout.center.dx + textRadius * math.cos(layout.middleAngle);
      final ty = layout.center.dy + textRadius * math.sin(layout.middleAngle);

      final textSpan = TextSpan(
        text: layout.percentageText,
        style: GoogleFonts.outfit(
          color: AppColors.white,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      );

      final tp = TextPainter(text: textSpan, textDirection: TextDirection.ltr)
        ..layout();

      tp.paint(canvas, Offset(tx - tp.width / 2, ty - tp.height / 2));
    }

    // 5. Draw labels and leader lines
    for (var idx in paintOrder) {
      final layout = layouts[idx];
      if (layout == null) continue;

      // Label anchor points matching mockup
      Offset labelCenter;
      TextAlign textAlign;
      Offset lineStartAnchor;

      if (idx == 1) {
        // TOP label (Navy)
        labelCenter = Offset(size.width / 2, 8);
        textAlign = TextAlign.center;
        lineStartAnchor = Offset(size.width / 2, 42);
      } else if (idx == 0) {
        // BOTTOM-LEFT label (Orange)
        labelCenter = Offset(16, size.height - 48);
        textAlign = TextAlign.left;
        lineStartAnchor = Offset(68, size.height - 56);
      } else {
        // BOTTOM-RIGHT label (Purple)
        labelCenter = Offset(size.width - 16, size.height - 48);
        textAlign = TextAlign.right;
        lineStartAnchor = Offset(size.width - 68, size.height - 56);
      }

      // Draw label texts using TextPainter
      final titleSpan = TextSpan(
        text: layout.category,
        style: GoogleFonts.outfit(
          color: isDark
              ? AppColors.white.withOpacity(0.9)
              : const Color(0xFF1C1E1C),
          fontWeight: FontWeight.w600,
          fontSize: 12.5,
        ),
      );
      final titlePainter = TextPainter(
        text: titleSpan,
        textDirection: TextDirection.ltr,
        textAlign: textAlign,
      )..layout(maxWidth: size.width / 3);

      final amountSpan = TextSpan(
        text: layout.amountText,
        style: GoogleFonts.outfit(
          color: isDark ? Colors.white60 : Colors.black38,
          fontWeight: FontWeight.w500,
          fontSize: 11,
        ),
      );
      final amountPainter = TextPainter(
        text: amountSpan,
        textDirection: TextDirection.ltr,
        textAlign: textAlign,
      )..layout(maxWidth: size.width / 3);

      double textX = labelCenter.dx;
      if (textAlign == TextAlign.right) {
        textX -= titlePainter.width;
      } else if (textAlign == TextAlign.center) {
        textX -= titlePainter.width / 2;
      }

      double amountX = labelCenter.dx;
      if (textAlign == TextAlign.right) {
        amountX -= amountPainter.width;
      } else if (textAlign == TextAlign.center) {
        amountX -= amountPainter.width / 2;
      }

      // Paint label texts with dynamic entry fade-in
      final double textOpacity = math.max(
        0.0,
        math.min(1.0, (animationValue - 0.4) / 0.6),
      );
      if (textOpacity > 0) {
        canvas.save();
        canvas.saveLayer(
          Rect.fromLTWH(0, 0, size.width, size.height),
          Paint()..color = AppColors.white.withOpacity(textOpacity),
        );

        titlePainter.paint(canvas, Offset(textX, labelCenter.dy));
        amountPainter.paint(
          canvas,
          Offset(amountX, labelCenter.dy + titlePainter.height + 2),
        );

        canvas.restore();
        canvas.restore();
      }

      // Draw leader line from slice to label
      final sliceOuterPoint = Offset(
        layout.center.dx + radius * math.cos(layout.middleAngle),
        layout.center.dy + radius * math.sin(layout.middleAngle),
      );

      final linePaint = Paint()
        ..color = layout.color.withOpacity(0.85 * textOpacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3
        ..strokeCap = StrokeCap.round
        ..isAntiAlias = true;

      // Animate line drawing
      final lineEnd = Offset(
        sliceOuterPoint.dx +
            (lineStartAnchor.dx - sliceOuterPoint.dx) * textOpacity,
        sliceOuterPoint.dy +
            (lineStartAnchor.dy - sliceOuterPoint.dy) * textOpacity,
      );

      if (textOpacity > 0) {
        canvas.drawLine(sliceOuterPoint, lineEnd, linePaint);
      }
    }
  }

  String _formatAmount(double amount) {
    return AppColors.formatShortAmount(amount);
  }

  @override
  bool shouldRepaint(covariant _PremiumPieChartPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.isDark != isDark ||
        oldDelegate.sections != sections;
  }
}

class _SliceLayout {
  final double startAngle;
  final double sweepAngle;
  final double middleAngle;
  final Offset center;
  final Color color;
  final String percentageText;
  final String category;
  final String amountText;

  _SliceLayout({
    required this.startAngle,
    required this.sweepAngle,
    required this.middleAngle,
    required this.center,
    required this.color,
    required this.percentageText,
    required this.category,
    required this.amountText,
  });
}
