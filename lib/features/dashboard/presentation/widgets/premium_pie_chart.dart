import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:smart_money_tracker/core/constants/app_colors.dart';
import 'package:smart_money_tracker/core/constants/app_sizes.dart';
import 'package:smart_money_tracker/core/theme/app_text_styles.dart';

class PremiumPieChart extends StatelessWidget {
  final Map<String, double> categoryAmounts;
  final String currencySymbol;
  final double totalAmount;
  final bool isExpense;

  const PremiumPieChart({
    super.key,
    required this.categoryAmounts,
    this.currencySymbol = '₹',
    required this.totalAmount,
    required this.isExpense,
  });

  @override
  Widget build(BuildContext context) {
    final sortedEntries = categoryAmounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (sortedEntries.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(height: AppSizes.h16),
        // Donut Chart with Callouts
        SizedBox(
          height: 400, // Significantly increased height for more label space
          width: double.infinity,
          child: CustomPaint(
            painter: _DonutChartPainter(
              categoryAmounts: categoryAmounts,
              totalAmount: totalAmount,
              currencySymbol: currencySymbol,
              context: context,
            ),
          ),
        ),
        SizedBox(height: AppSizes.h24),
        // Total Amount Summary
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: AppSizes.w24,
            vertical: AppSizes.h12,
          ),
          decoration: BoxDecoration(
            color: AppColors.getSurfaceContainer(context),
            borderRadius: BorderRadius.circular(100),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isExpense ? 'Total Expenses: ' : 'Total Income: ',
                style: AppTextStyles.body(context).copyWith(
                  color: AppColors.getTextMuted(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '$currencySymbol${AppColors.formatShortAmount(totalAmount)}',
                style: AppTextStyles.body(context).copyWith(
                  fontWeight: FontWeight.bold,
                  color: isExpense ? AppColors.error : AppColors.success,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  final Map<String, double> categoryAmounts;
  final double totalAmount;
  final String currencySymbol;
  final BuildContext context;

  _DonutChartPainter({
    required this.categoryAmounts,
    required this.totalAmount,
    required this.currencySymbol,
    required this.context,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (totalAmount <= 0) return;

    final isDark = AppColors.isDark(context);
    final center = Offset(size.width / 2, size.height / 2);
    
    // Adjusted radius for a full pie chart
    final minDimension = math.min(size.width, size.height);
    final radius = minDimension * 0.22; 
    final outerRadius = radius;
    
    final paint = Paint()
      ..style = PaintingStyle.fill;

    double startAngle = -math.pi / 2;

    final sortedEntries = categoryAmounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Green palette representing the app's primary color with high contrast light variations
    final List<Color> premiumPalette = isDark 
        ? [
            AppColors.primary, // 0xFF006A34
            const Color(0xFF2E9D5C), 
            const Color(0xFF55B576), 
            const Color(0xFF7DCD92),
            const Color(0xFFA6E5AF),
            const Color(0xFFCFFCDA),
            const Color(0xFF004D25),
            const Color(0xFF003819),
            const Color(0xFF9CCC65),
          ]
        : [
            AppColors.primary, // 0xFF006A34
            const Color(0xFF34A853),
            const Color(0xFF66BB6A),
            const Color(0xFF9CCC65),
            const Color(0xFFC5E1A5),
            const Color(0xFFE8F5E9),
            const Color(0xFFB2DFDB),
            const Color(0xFF4DB6AC),
            const Color(0xFF00897B),
          ];

    List<_SliceData> slices = [];
    int colorIndex = 0;
    for (var entry in sortedEntries) {
      if (entry.value <= 0) continue;
      final sweepAngle = (entry.value / totalAmount) * 2 * math.pi;
      final midAngle = startAngle + sweepAngle / 2;
      slices.add(_SliceData(
        key: entry.key,
        value: entry.value,
        startAngle: startAngle,
        sweepAngle: sweepAngle,
        midAngle: midAngle,
        color: premiumPalette[colorIndex % premiumPalette.length],
      ));
      startAngle += sweepAngle;
      colorIndex++;
    }

    // Draw arcs and percentages
    for (var slice in slices) {
      paint.color = slice.color;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        slice.startAngle,
        slice.sweepAngle,
        true, // useCenter = true for a full pie slice
        paint,
      );

      final percentage = (slice.value / totalAmount) * 100;
      if (percentage > 5) {
        final textPainter = TextPainter(
          text: TextSpan(
            text: '${percentage.toStringAsFixed(1)}%',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        
        final textOffset = Offset(
          center.dx + radius * math.cos(slice.midAngle) - textPainter.width / 2,
          center.dy + radius * math.sin(slice.midAngle) - textPainter.height / 2,
        );
        textPainter.paint(canvas, textOffset);
      }
    }

    // Layout Callouts
    List<_LabelData> rightLabels = [];
    List<_LabelData> leftLabels = [];

    for (var slice in slices) {
      final isRightSide = math.cos(slice.midAngle) >= 0;
      final anchorX = center.dx + outerRadius * math.cos(slice.midAngle);
      final anchorY = center.dy + outerRadius * math.sin(slice.midAngle);
      
      final label = _LabelData(
        slice: slice,
        anchor: Offset(anchorX, anchorY),
        isRightSide: isRightSide,
      );
      
      if (isRightSide) {
        rightLabels.add(label);
      } else {
        leftLabels.add(label);
      }
    }

    rightLabels.sort((a, b) => a.anchor.dy.compareTo(b.anchor.dy));
    leftLabels.sort((a, b) => a.anchor.dy.compareTo(b.anchor.dy));

    final minSpacing = 36.0; // Ample spacing to prevent labels from fighting
    _resolveOverlaps(rightLabels, minSpacing, size.height);
    _resolveOverlaps(leftLabels, minSpacing, size.height);

    final linePaint = Paint()
      ..color = isDark ? Colors.white38 : Colors.grey.shade500
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (var label in [...rightLabels, ...leftLabels]) {
      final sign = label.isRightSide ? 1.0 : -1.0;

      // Small circle on the pie edge
      canvas.drawCircle(label.anchor, 3, Paint()..color = AppColors.getSurface(context));
      canvas.drawCircle(label.anchor, 3, linePaint);

      final path = Path();
      path.moveTo(label.anchor.dx, label.anchor.dy);
      
      // 1. Radially out to clear the slice
      final r2 = outerRadius + 10;
      final pt2 = Offset(
        center.dx + r2 * math.cos(label.slice.midAngle),
        center.dy + r2 * math.sin(label.slice.midAngle),
      );
      path.lineTo(pt2.dx, pt2.dy);
      
      // 2. Angled straight line to a fixed X distance
      final fixedX = center.dx + sign * (outerRadius + 22);
      path.lineTo(fixedX, label.targetY);
      
      // 3. Short horizontal stub
      final endX = fixedX + sign * 10;
      path.lineTo(endX, label.targetY);
      
      canvas.drawPath(path, linePaint);

      // Draw Text
      final titleStyle = TextStyle(
        color: isDark ? Colors.white70 : Colors.black87,
        fontSize: 11,
        fontWeight: FontWeight.w400,
      );
      final amountStyle = TextStyle(
        color: isDark ? Colors.white : Colors.black,
        fontSize: 12,
        fontWeight: FontWeight.bold,
      );

      final titlePainter = TextPainter(
        text: TextSpan(text: label.slice.key, style: titleStyle),
        textDirection: TextDirection.ltr,
        textAlign: label.isRightSide ? TextAlign.left : TextAlign.right,
      );
      titlePainter.layout();

      final amountStr = '$currencySymbol${AppColors.formatShortAmount(label.slice.value)}';

      final amountPainter = TextPainter(
        text: TextSpan(text: amountStr, style: amountStyle),
        textDirection: TextDirection.ltr,
        textAlign: label.isRightSide ? TextAlign.left : TextAlign.right,
      );
      amountPainter.layout();

      final textPadding = 4.0;
      final textStartX = label.isRightSide 
          ? endX + textPadding 
          : endX - textPadding - math.max(titlePainter.width, amountPainter.width);

      // Draw column (title above amount)
      titlePainter.paint(
        canvas, 
        Offset(
          label.isRightSide 
              ? textStartX 
              : textStartX + math.max(0.0, amountPainter.width - titlePainter.width), 
          label.targetY - titlePainter.height - 1
        )
      );
      amountPainter.paint(
        canvas, 
        Offset(
          label.isRightSide 
              ? textStartX 
              : textStartX + math.max(0.0, titlePainter.width - amountPainter.width), 
          label.targetY + 1
        )
      );
    }
  }

  void _resolveOverlaps(List<_LabelData> labels, double minSpacing, double height) {
    if (labels.isEmpty) return;
    
    for (var label in labels) {
      label.targetY = label.anchor.dy;
    }

    // Push down
    for (int i = 1; i < labels.length; i++) {
      if (labels[i].targetY < labels[i - 1].targetY + minSpacing) {
        labels[i].targetY = labels[i - 1].targetY + minSpacing;
      }
    }

    // Push up if they overflow at the bottom
    double maxBottom = height - 15; // 15 padding
    if (labels.last.targetY > maxBottom) {
      double overflow = labels.last.targetY - maxBottom;
      for (int i = labels.length - 1; i >= 0; i--) {
        if (i == labels.length - 1) {
          labels[i].targetY -= overflow;
        } else {
          if (labels[i].targetY > labels[i + 1].targetY - minSpacing) {
            labels[i].targetY = labels[i + 1].targetY - minSpacing;
          }
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _SliceData {
  final String key;
  final double value;
  final double startAngle;
  final double sweepAngle;
  final double midAngle;
  final Color color;

  _SliceData({
    required this.key,
    required this.value,
    required this.startAngle,
    required this.sweepAngle,
    required this.midAngle,
    required this.color,
  });
}

class _LabelData {
  final _SliceData slice;
  final Offset anchor;
  final bool isRightSide;
  double targetY = 0;

  _LabelData({
    required this.slice,
    required this.anchor,
    required this.isRightSide,
  });
}
