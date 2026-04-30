import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../utils/responsive_helper.dart';
import 'feedback_dialog.dart';
import 'loading_widget.dart';

class ErrorWidget extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onRetry;
  final IconData? icon;
  final Color? iconColor;

  const ErrorWidget({
    super.key,
    required this.title,
    required this.message,
    this.onRetry,
    this.icon,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: ResponsiveHelper.getScreenPadding(context),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon ?? Icons.error_outline,
              size: ResponsiveHelper.getIconSize(context) * 3,
              color: iconColor ?? AppTheme.error,
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: iconColor ?? AppTheme.error,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: iconColor ?? AppTheme.error,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class NetworkErrorWidget extends StatelessWidget {
  final VoidCallback? onRetry;
  final String? customMessage;

  const NetworkErrorWidget({
    super.key,
    this.onRetry,
    this.customMessage,
  });

  @override
  Widget build(BuildContext context) {
    return ErrorWidget(
      title: 'Network Error',
      message: customMessage ?? 'Unable to connect to the server. Please check your internet connection and try again.',
      onRetry: onRetry,
      icon: Icons.wifi_off,
      iconColor: Colors.orange,
    );
  }
}

class DataNotFoundErrorWidget extends StatelessWidget {
  final VoidCallback? onRefresh;
  final String? customMessage;

  const DataNotFoundErrorWidget({
    super.key,
    this.onRefresh,
    this.customMessage,
  });

  @override
  Widget build(BuildContext context) {
    return ErrorWidget(
      title: 'No Data Found',
      message: customMessage ?? 'We couldn\'t find any data. Please try refreshing or check back later.',
      onRetry: onRefresh,
      icon: Icons.search_off,
      iconColor: AppTheme.textSecondary,
    );
  }
}

class PermissionErrorWidget extends StatelessWidget {
  final String permission;
  final VoidCallback? onRequestPermission;
  final VoidCallback? onOpenSettings;

  const PermissionErrorWidget({
    super.key,
    required this.permission,
    this.onRequestPermission,
    this.onOpenSettings,
  });
 @override
  Widget build(BuildContext context) {
    return Padding(
      padding: ResponsiveHelper.getScreenPadding(context),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.security,
            size: ResponsiveHelper.getIconSize(context) * 3,
            color: Colors.orange,
          ),
          const SizedBox(height: 24),
          Text(
            'Permission Required',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: Colors.orange,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'This app needs $permission permission to work properly.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          if (onRequestPermission != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ElevatedButton.icon(
                onPressed: onRequestPermission,
                icon: const Icon(Icons.lock_open),
                label: const Text('Grant Permission'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ),
          if (onOpenSettings != null)
            TextButton.icon(
              onPressed: onOpenSettings,
              icon: const Icon(Icons.settings),
              label: const Text('Open Settings'),
            ),
        ],
      ),
    );
  }
}

class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final Widget Function(Object error, StackTrace? stackTrace)? errorBuilder;

  const ErrorBoundary({
    super.key,
    required this.child,
    this.errorBuilder,
  });

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  Object? _error;
  StackTrace? _stackTrace;

  @override
  void initState() {
    super.initState();
    _resetError();
  }

  void _resetError() {
    setState(() {
      _error = null;
      _stackTrace = null;
    });
  }

  void _handleError(Object error, StackTrace? stackTrace) {
    setState(() {
      _error = error;
      _stackTrace = stackTrace;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return widget.errorBuilder?.call(_error!, _stackTrace) ??
          ErrorWidget(
            title: 'Something went wrong',
            message: 'An unexpected error occurred. Please try again.',
            onRetry: _resetError,
          );
    }

    return ErrorHandlingWidget(
      onError: _handleError,
      child: widget.child,
    );
  }
}

class ErrorHandlingWidget extends StatelessWidget {
  final Widget child;
  final void Function(Object error, StackTrace? stackTrace)? onError;

  const ErrorHandlingWidget({
    super.key,
    required this.child,
    this.onError,
  });

  @override
  Widget build(BuildContext context) {
    return child;
  }
}

class RetryWidget extends StatefulWidget {
  final Future<void> Function() onRetry;
  final Widget child;
  final int maxRetries;
  final Duration retryDelay;

  const RetryWidget({
    super.key,
    required this.onRetry,
    required this.child,
    this.maxRetries = 3,
    this.retryDelay = const Duration(seconds: 2),
  });

  @override
  State<RetryWidget> createState() => _RetryWidgetState();
}

class _RetryWidgetState extends State<RetryWidget> {
  int _retryCount = 0;
  bool _isLoading = false;
  Object? _lastError;
[5/1/2026 12:54 AM] سيون زكارياس: Future<void> _retry() async {
    if (_retryCount >= widget.maxRetries) {
      FeedbackDialog.showError(
        context,
        'Max Retries Reached',
        'Please try again later or contact support if the problem persists.',
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _lastError = null;
    });

    try {
      await widget.onRetry();
      setState(() {
        _retryCount = 0;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _retryCount++;
        _isLoading = false;
        _lastError = e;
      });

      if (_retryCount < widget.maxRetries) {
        Future.delayed(widget.retryDelay, _retry);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_lastError != null && _retryCount >= widget.maxRetries) {
      return ErrorWidget(
        title: 'Failed after $_retryCount attempts',
        message: 'Please try again later.',
        onRetry: () {
          setState(() {
            _retryCount = 0;
            _lastError = null;
          });
          _retry();
        },
      );
    }

    if (_isLoading) {
      return LoadingWidget(message: 'Retrying...');
    }

    return widget.child;
  }
}