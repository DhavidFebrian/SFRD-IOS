import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/sheets_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SheetsService _sheetsService = SheetsService();
  String _currentApiUrl = SheetsService.defaultAppsScriptUrl;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final url = await _sheetsService.getBaseUrl();
    setState(() {
      _currentApiUrl = url;
    });
  }

  void _showEditUrlDialog() {
    final controller = TextEditingController(text: _currentApiUrl);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Google Apps Script URL', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Masukkan URL endpoint Google Apps Script untuk sinkronisasi data jadwal dan listing:',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 3,
              style: const TextStyle(fontSize: 12),
              decoration: const InputDecoration(
                hintText: 'https://script.google.com/macros/s/.../exec',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              controller.text = SheetsService.defaultAppsScriptUrl;
            },
            child: const Text('Reset Default'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newUrl = controller.text.trim();
              if (newUrl.isNotEmpty) {
                await _sheetsService.setBaseUrl(newUrl);
                setState(() => _currentApiUrl = newUrl);
                if (mounted) Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('URL Backend Google Apps Script diperbarui!')),
                );
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

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
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('David Febrian', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      SizedBox(height: 2),
                      Text('Marketing Executive (ME-01) - RWC Media Production', style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Integrasi Backend
          const Text('Konektivitas & Cloud', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textSecondaryLight)),
          const SizedBox(height: 8),
          _buildSettingsGroup([
            ListTile(
              leading: const Icon(CupertinoIcons.cloud_upload_fill, color: AppColors.primary, size: 22),
              title: const Text('Google Apps Script Backend', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              subtitle: Text(_currentApiUrl, style: const TextStyle(fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
              trailing: const Icon(CupertinoIcons.pencil_circle_fill, size: 22, color: AppColors.primaryLight),
              onTap: _showEditUrlDialog,
            ),
            _buildTile(CupertinoIcons.bell_fill, 'Notifikasi & Pengingat', true),
            _buildTile(CupertinoIcons.camera_fill, 'Izin Kamera & Galeri', false, subtitle: 'Diizinkan'),
          ]),
          const SizedBox(height: 20),

          // Info Aplikasi
          const Text('Tentang Sistem', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textSecondaryLight)),
          const SizedBox(height: 8),
          _buildSettingsGroup([
            _buildTile(CupertinoIcons.info_circle_fill, 'Versi Aplikasi', false, subtitle: 'v8.8.11 (Build 891) - RWC Media Production'),
            _buildTile(CupertinoIcons.device_phone_portrait, 'Target Platform', false, subtitle: 'iOS (iPhone / iPad Multiplatform)'),
            ListTile(
              leading: const Icon(CupertinoIcons.question_circle_fill, color: AppColors.primary, size: 22),
              title: const Text('Panduan Instalasi IPA (3uTools)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              subtitle: const Text('Cara sign & pasang ke iPhone di Windows', style: TextStyle(fontSize: 12)),
              trailing: const Icon(CupertinoIcons.chevron_right, size: 16, color: Colors.grey),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Cara Install ke iPhone'),
                    content: const Text(
                      '1. Buka aplikasi 3uTools di laptop Windows.\n'
                      '2. Hubungkan iPhone via kabel USB dan klik "Trust this computer".\n'
                      '3. Di 3uTools, buka tab Toolbox > IPA Signature (masukkan Apple ID Anda) atau buka tab Apps > Import & Install ipa.\n'
                      '4. Di iPhone: Masuk ke Settings > General > VPN & Device Management, klik Trust pada sertifikat Apple ID.\n'
                      '5. Aplikasi RWC - Media Production siap digunakan!',
                      style: TextStyle(fontSize: 13, height: 1.4),
                    ),
                    actions: [
                      ElevatedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Mengerti')),
                    ],
                  ),
                );
              },
            ),
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
