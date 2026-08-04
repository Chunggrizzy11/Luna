import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_spacing.dart';
import '../data/partner_repository.dart';
import '../domain/partner_models.dart';

/// Owner-facing page: generates and displays an 8-character pairing code
/// that expires after 5 minutes.
class PairingPage extends StatefulWidget {
  const PairingPage({super.key, required this.repository});

  final PartnerRepository repository;

  @override
  State<PairingPage> createState() => _PairingPageState();
}

class _PairingPageState extends State<PairingPage> {
  GenerateCodeResponse? _response;
  bool _loading = false;
  String? _error;
  Timer? _countdownTimer;
  Duration _remaining = Duration.zero;

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _generateCode() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final response = await widget.repository.generateCode();
      final expiresAt = DateTime.parse(response.expiresAt).toLocal();
      final now = DateTime.now();
      final remaining = expiresAt.difference(now);

      if (remaining.isNegative) {
        setState(() {
          _error = 'Mã đã hết hạn. Vui lòng tạo mã mới.';
          _loading = false;
        });
        return;
      }

      _countdownTimer?.cancel();
      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        final left = expiresAt.difference(DateTime.now());
        if (left.isNegative) {
          timer.cancel();
          setState(() => _remaining = Duration.zero);
        } else {
          setState(() => _remaining = left);
        }
      });

      setState(() {
        _response = response;
        _remaining = remaining;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Không thể tạo mã ghép đôi. Vui lòng thử lại.';
        _loading = false;
      });
    }
  }

  String _formatCountdown(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ghép đôi'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Instructions
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  children: [
                    Icon(
                      Icons.qr_code_2,
                      size: 48,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Mã ghép đôi 8 ký tự',
                      style: theme.textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Mã sẽ hết hạn sau 5 phút. '
                      'Hãy gửi mã này cho người bạn đời để họ nhập mã và ghép đôi.',
                      style: theme.textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Code display
            if (_response != null) ...[
              Card(
                color: colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    children: [
                      Text(
                        _response!.code,
                        style: theme.textTheme.displaySmall?.copyWith(
                          letterSpacing: 8,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onPrimaryContainer,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      // Countdown
                      Text(
                        'Còn lại: ${_formatCountdown(_remaining)}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      // Copy button
                      FilledButton.icon(
                        onPressed: () {
                          Clipboard.setData(
                            ClipboardData(text: _response!.code),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Đã sao chép mã ghép đôi.'),
                            ),
                          );
                        },
                        icon: const Icon(Icons.copy),
                        label: const Text('Sao chép mã'),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              // Regenerate button
              if (_remaining == Duration.zero)
                OutlinedButton(
                  onPressed: _generateCode,
                  child: const Text('Tạo mã mới'),
                ),
            ],

            // Error
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.md),
              Card(
                color: colorScheme.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Text(
                    _error!,
                    style: TextStyle(color: colorScheme.onErrorContainer),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],

            const Spacer(),

            // Generate button
            if (_response == null || _remaining == Duration.zero)
              FilledButton(
                onPressed: _loading ? null : _generateCode,
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Tạo mã ghép đôi'),
              ),
          ],
        ),
      ),
    );
  }
}
