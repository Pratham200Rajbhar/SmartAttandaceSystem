import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:smart_attendance_app/app/theme.dart';

/// Consolidates _ShimmerLoadingPlaceholder, _ShimmerCalendar,
/// _ShimmerNotifications, and _ShimmerAnalytics into a single configurable widget.
class ShimmerPlaceholder extends StatelessWidget {
  final int itemCount;
  final double itemHeight;
  final double spacing;

  const ShimmerPlaceholder({
    super.key,
    this.itemCount = 3,
    this.itemHeight = 80,
    this.spacing = SasSpacing.md,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: SasColors.glassBg,
      highlightColor: SasColors.glassBgHover,
      child: Column(
        children: List.generate(
          itemCount,
          (index) => Padding(
            padding: EdgeInsets.only(bottom: index < itemCount - 1 ? spacing : 0),
            child: Container(
              height: itemHeight,
              decoration: BoxDecoration(
                color: SasColors.glassBg,
                borderRadius: SasRadius.xlAll,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Shimmer variant for calendar grid loading state.
class ShimmerCalendarPlaceholder extends StatelessWidget {
  const ShimmerCalendarPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: SasColors.glassBg,
      highlightColor: SasColors.glassBgHover,
      child: Column(
        children: [
          Container(
            height: 280,
            decoration: BoxDecoration(
              color: SasColors.glassBg,
              borderRadius: SasRadius.xlAll,
            ),
          ),
          const SizedBox(height: SasSpacing.md),
          ...List.generate(
            2,
            (index) => Padding(
              padding: const EdgeInsets.only(bottom: SasSpacing.sm),
              child: Container(
                height: 60,
                decoration: BoxDecoration(
                  color: SasColors.glassBg,
                  borderRadius: SasRadius.xlAll,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
