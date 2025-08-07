import 'package:flutter/material.dart';

class LoadingWidget extends StatelessWidget {
  const LoadingWidget({super.key, this.message, this.size, this.color});
  final String? message;
  final double? size;
  final Color? color;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: size ?? 40,
              height: size ?? 40,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(
                  color ?? Theme.of(context).primaryColor,
                ),
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: 16),
              Text(
                message!,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      );
}

class LoadingOverlay extends StatelessWidget {
  const LoadingOverlay({
    required this.child,
    required this.isLoading,
    super.key,
    this.loadingMessage,
  });
  final Widget child;
  final bool isLoading;
  final String? loadingMessage;

  @override
  Widget build(BuildContext context) => Stack(
        children: [
          child,
          if (isLoading)
            ColoredBox(
              color: Colors.black.withValues(alpha: 0.3),
              child:
                  LoadingWidget(message: loadingMessage, color: Colors.white),
            ),
        ],
      );
}

class SmallLoadingWidget extends StatelessWidget {
  const SmallLoadingWidget({super.key, this.color});
  final Color? color;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            color ?? Theme.of(context).primaryColor,
          ),
        ),
      );
}
