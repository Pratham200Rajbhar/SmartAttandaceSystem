library;

import 'package:flutter/material.dart';

/// Animated gradient orb background shared across all screens.
///
/// Wrapped in RepaintBoundary to isolate the animation layer from content,
/// preventing unnecessary repaints of child widgets during animation ticks.
/// Both orbs render in a single AnimatedBuilder to reduce build callbacks.
class AnimatedBackground extends StatefulWidget {
  final Widget child;

  const AnimatedBackground({super.key, required this.child});

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 28),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return Stack(
      children: [
        // Solid base
        Container(color: const Color(0xFF000000)),

        // Static emerald glow center
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 0.65,
                colors: [
                  Color(0x1410B981),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // Animated orbs — both in a single builder to reduce frame callbacks
        RepaintBoundary(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final value = _controller.value;
              final inverseValue = 1.0 - value;

              return Stack(
                children: [
                  // Purple orb (top-left drift)
                  Positioned(
                    top: -80 + (value * 100),
                    left: -60 + (value * 80),
                    child: Container(
                      width: size.width * 0.8,
                      height: size.height * 0.5,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFF8B5CF6).withValues(alpha: 0.12),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Sky-blue orb (bottom-right drift)
                  Positioned(
                    bottom: -80 + (inverseValue * 100),
                    right: -60 + (inverseValue * 80),
                    child: Container(
                      width: size.width * 0.85,
                      height: size.height * 0.5,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFF38BDF8).withValues(alpha: 0.10),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),

        Positioned.fill(child: widget.child),
      ],
    );
  }
}
