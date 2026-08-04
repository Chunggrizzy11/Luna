import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../statistics/data/statistics_repository.dart';
import '../../settings/data/settings_repository.dart';
import '../domain/settings_models.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsRepo = ref.watch(settingsRepositoryProvider);
    final statisticsRepo = ref.watch(statisticsRepositoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Cài đặt')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _AppSection(
            title: 'Dữ liệu',
            icon: Icons.backup,
            children: [
              _SettingTile(
                icon: Icons.cloud_upload,
                title: 'Xuất dữ liệu',
                subtitle: 'Tải xuống tất cả dữ liệu của bạn',
                onTap: () => _exportData(context, settingsRepo),
              ),
              _SettingTile(
                icon: Icons.cloud_download,
                title: 'Nhập dữ liệu',
                subtitle: 'Nhập dữ liệu đã xuất từ thiết bị khác',
                onTap: () => _importData(context, settingsRepo),
              ),
            ],
          ),
          _AppSection(
            title: 'Bảo mật',
            icon: Icons.security,
            children: [
              _SettingTile(
                icon: Icons.pin,
                title: 'Khóa ứng dụng',
                subtitle: 'Bật khóa ứng dụng bằng PIN',
                onTap: () => _toggleAppLock(context),
              ),
              _SettingTile(
                icon: Icons.fingerprint,
                title: 'Xác thực sinh trắc học',
                subtitle: 'Bật/xoá xác thực sinh trắc học',
                onTap: () => _toggleBiometricAuth(context),
              ),
            ],
          ),
          _AppSection(
            title: 'Thống kê',
            icon: Icons.bar_chart,
            children: [
              _SettingTile(
                icon: Icons.insights,
                title: 'Biểu đồ chu kỳ',
                subtitle: 'Xem thống kê lịch sử chu kỳ',
                onTap: () => _viewCycleStats(context, statisticsRepo),
              ),
              _SettingTile(
                icon: Icons.timeline,
                title: 'Biểu đồ tâm trạng',
                subtitle: 'Xem biểu đồ tâm trạng',
                onTap: () => _viewMoodStats(context, statisticsRepo),
              ),
            ],
          ),
          _AppSection(
            title: 'Khác',
            icon: Icons.more_horiz,
            children: [
              _SettingTile(
                icon: Icons.info,
                title: 'Phiên bản',
                subtitle: 'Thông tin về phiên bản ứng dụng',
                onTap: () => _showVersionInfo(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _exportData(BuildContext context, SettingsRepository repo) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xuất dữ liệu'),
        content: const Text('Bạn có chắc chắn muốn xuất tất cả dữ liệu?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('HỦY'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              // Implement export logic
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đang xuất dữ liệu...')),
              );
              // TODO: Call repository.exportData() and download file
            },
            child: const Text('XUẤT'),
          ),
        ],
      ),
    );
  }

  void _importData(BuildContext context, SettingsRepository repo) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nhập dữ liệu'),
        content: const Text('Chọn tệp JSON đã xuất từ thiết bị khác'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('HỦY'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              // TODO: Implement file picker and import logic
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đang nhập dữ liệu...')),
              );
            },
            child: const Text('NHẬP'),
          ),
        ],
      ),
    );
  }

  void _toggleAppLock(BuildContext context) {
    // TODO: Implement app lock toggle
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tính năng khóa ứng dụng sẽ được triển khai sớm')),
    );
  }

  void _toggleBiometricAuth(BuildContext context) {
    // TODO: Implement biometric auth toggle
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tính năng xác thực sinh trắc học sẽ được triển khai sớm')),
    );
  }

  void _viewCycleStats(BuildContext context, StatisticsRepository repo) {
    Navigator.pushNamed(context, '/statistics/cycles');
  }

  void _viewMoodStats(BuildContext context, StatisticsRepository repo) {
    Navigator.pushNamed(context, '/statistics/mood');
  }

  void _showVersionInfo(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Luna',
      applicationVersion: '1.0.0',
      applicationDescription: 'Ứng dụng theo dõi sức khỏe theo chu kỳ',
    );
  }
}

class _AppSection extends StatelessWidget {
  const _AppSection({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            children: [
              Icon(icon, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: AppSpacing.sm),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const Divider(),
        ...children,
      ],
    );
  }
}

class _SettingTile extends StatelessWidget {
  const _SettingTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.primaryContainer,
        child: Icon(icon, color: theme.colorScheme.primary),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}