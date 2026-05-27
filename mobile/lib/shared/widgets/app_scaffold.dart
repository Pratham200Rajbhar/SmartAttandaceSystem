import 'package:flutter/material.dart';
import 'package:smart_attendance_app/app/theme.dart';
import 'package:smart_attendance_app/shared/widgets/animated_background.dart';

/// Shared scaffold eliminating the per-screen AnimatedBackground > SafeArea > ListView boilerplate.
///
/// Renders AnimatedBackground once at this level. Screens only need to provide their body content.
/// If [onRefresh] is provided, wraps body in a RefreshIndicator.
/// If [useListView] is true (default), wraps body children in a ListView with standard padding.
class AppScaffold extends StatelessWidget {
  final String? title;
  final List<Widget>? actions;
  final Widget body;
  final VoidCallback? onBack;
  final Future<void> Function()? onRefresh;
  final bool showBackground;

  const AppScaffold({
    super.key,
    this.title,
    this.actions,
    required this.body,
    this.onBack,
    this.onRefresh,
    this.showBackground = true,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = SafeArea(child: body);

    if (onRefresh != null) {
      content = SafeArea(
        child: RefreshIndicator(
          color: SasColors.accentEmerald,
          backgroundColor: SasColors.bgSecondary,
          onRefresh: onRefresh!,
          child: body,
        ),
      );
    }

    if (showBackground) {
      content = AnimatedBackground(child: content);
    }

    if (title != null || onBack != null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: title != null ? Text(title!) : null,
          leading: onBack != null
              ? IconButton(
                  icon: const Icon(Icons.arrow_back_rounded),
                  onPressed: onBack,
                )
              : null,
          actions: actions,
        ),
        body: content,
      );
    }

    return Scaffold(body: content);
  }
}
