import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// A widget that catches errors in its child widget tree and displays a friendly error message.
/// This allows different sections of the app to have their own error handling.
class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final Widget Function(BuildContext context, Object error)? errorBuilder;
  final String sectionName;
  final VoidCallback? onRetry;

  const ErrorBoundary({
    Key? key,
    required this.child,
    this.errorBuilder,
    required this.sectionName,
    this.onRetry,
  }) : super(key: key);

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  Object? _error;
  FlutterExceptionHandler? _originalErrorHandler;

  @override
  void initState() {
    super.initState();
    _originalErrorHandler = FlutterError.onError;
    FlutterError.onError = _handleFlutterError;
  }

  void _handleFlutterError(FlutterErrorDetails details) {
    if (mounted) {
      setState(() {
        _error = details.exception;
      });
    }
    // Also forward to the original handler
    _originalErrorHandler?.call(details);
  }

  @override
  void dispose() {
    FlutterError.onError = _originalErrorHandler;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      if (widget.errorBuilder != null) {
        return widget.errorBuilder!(context, _error!);
      }

      // Default error UI
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Problem në seksionin "${widget.sectionName}"',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                kDebugMode 
                    ? 'Gabim: ${_error.toString()}'
                    : 'Ka ndodhur një gabim. Ju lutemi provoni përsëri.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              if (widget.onRetry != null)
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _error = null;
                    });
                    widget.onRetry?.call();
                  },
                  child: const Text('Provo përsëri'),
                ),
            ],
          ),
        ),
      );
    }

    return widget.child;
  }
}
