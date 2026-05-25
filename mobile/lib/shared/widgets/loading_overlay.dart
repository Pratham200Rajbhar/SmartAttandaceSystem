
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:smart_attendance_app/app/theme.dart';

class LoadingOverlay extends StatelessWidget {
  final String? message;
  const LoadingOverlay({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
      child: Container(
        color: const Color(0xB303040C),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 40, height: 40,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: const AlwaysStoppedAnimation<Color>(SasColors.accentEmerald),
                ),
              ),
              if (message != null) ...[
                const SizedBox(height: 16),
                Text(message!, style: const TextStyle(color: SasColors.textSecondary, fontSize: 14)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
