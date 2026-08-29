import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../../core/constants/app_colors.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profil ME
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.primaryLight.withOpacity(0.2),
                  child: const Text('DF', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
                ),
                const SizedBox(width: 16),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('David Febrian', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    SizedBox(height: 2),
                    Text('Marketing Executive (ME-01)', style: TextStyle(fontSize: 13, color: AppColors.textSecondaryLight)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Menu items
          _buildSettingsGroup([
            _buildTile(CupertinoIcons.bell_fill, 'Notifikasi & Pengingat', true),
            _buildTile(CupertinoIcons.camera_fill, 'Izin Kamera & Galeri', false, subtitle: 'Diizinkan'),
            _buildTile(CupertinoIcons.cloud_upload_fill, 'Sinkronisasi Cloud Data', true),
          ]),
          const SizedBox(height: 16),

          _buildSettingsGroup([
            _buildTile(CupertinoIcons.info_circle_fill, 'Tentang Aplikasi', false, subtitle: 'v1.0.0 (Build iOS)'),
            _buildTile(CupertinoIcons.question_circle_fill, 'Panduan Penggunaan', false),
          ]),
        ],
      ),
    );
  }

  Widget _buildSettingsGroup(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildTile(IconData icon, String title, bool isSwitch, {String? subtitle}) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary, size: 22),
      title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(fontSize: 12)) : null,
      trailing: isSwitch
          ? CupertinoSwitch(value: true, onChanged: (_) {})
          : const Icon(CupertinoIcons.chevron_right, size: 16, color: Colors.grey),
    );
  }
}
