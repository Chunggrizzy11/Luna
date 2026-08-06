import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';

import '../../../core/theme/app_spacing.dart';
import '../data/partner_repository.dart';
import '../domain/partner_models.dart';
import 'partner_providers.dart';

/// Partner-facing page: enter an 8-character pairing code to pair with owner.
class JoinPairingPage extends ConsumerStatefulWidget {
  const JoinPairingPage({super.key, required this.repository});

  final PartnerRepository repository;

  @override
  ConsumerState<JoinPairingPage> createState() => _JoinPairingPageState();
}

class _JoinPairingPageState extends ConsumerState<JoinPairingPage> {
  final _codeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  String? _error;
  JoinPairingResponse? _success;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  String? _validateCode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập mã ghép đôi.';
    }
    final code = value.trim().toUpperCase();
    if (code.length != 8) {
      return 'Mã ghép đôi phải có đúng 8 ký tự.';
    }
    return null;
  }

  Future<void> _join() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final code = _codeController.text.trim().toUpperCase();
      final response = await widget.repository.join(code);
      
      // Invalidate the provider so the previous screen refreshes its status
      ref.invalidate(pairingStatusProvider);
      
      setState(() {
        _success = response;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Mã ghép đôi không hợp lệ hoặc đã hết hạn.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Success state
    if (_success != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Ghép đôi thành công')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 72,
                  color: colorScheme.primary,
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Ghép đôi thành công!',
                  style: theme.textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Bạn đã được ghép đôi với chủ tài khoản. '
                  'Bây giờ bạn có thể theo dõi lịch trình sức khỏe của họ.',
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xl),
                FilledButton(
                  onPressed: () {
                    ref.invalidate(pairingStatusProvider);
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go(AppRoutes.home);
                    }
                  },
                  child: const Text('Bắt đầu'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Input form
    return Scaffold(
      appBar: AppBar(title: const Text('Ghép đôi')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Form(
          key: _formKey,
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
                        Icons.link,
                        size: 48,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Nhập mã ghép đôi',
                        style: theme.textTheme.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Nhập 8 ký tự mã ghép đôi mà chủ tài khoản '
                        'đã gửi cho bạn.',
                        style: theme.textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              // Code input
              TextFormField(
                controller: _codeController,
                textAlign: TextAlign.center,
                textCapitalization: TextCapitalization.characters,
                maxLength: 8,
                style: theme.textTheme.headlineSmall?.copyWith(
                  letterSpacing: 4,
                ),
                decoration: InputDecoration(
                  hintText: 'XXXXXXXX',
                  counterText: '',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.vpn_key),
                ),
                validator: _validateCode,
              ),

              const SizedBox(height: AppSpacing.md),

              // Error
              if (_error != null) ...[
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
                const SizedBox(height: AppSpacing.md),
              ],

              // Join button
              FilledButton(
                onPressed: _loading ? null : _join,
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Ghép đôi'),
              ),

              const SizedBox(height: AppSpacing.sm),

              // Paste from clipboard
              OutlinedButton.icon(
                onPressed: () async {
                  final data = await Clipboard.getData(Clipboard.kTextPlain);
                  if (data?.text != null) {
                    final text = data!.text!.toUpperCase().replaceAll(
                          RegExp(r'[^A-Z0-9]'),
                          '',
                        );
                    if (text.length >= 8) {
                      _codeController.text = text.substring(0, 8);
                    }
                  }
                },
                icon: const Icon(Icons.paste),
                label: const Text('Dán từ clipboard'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
