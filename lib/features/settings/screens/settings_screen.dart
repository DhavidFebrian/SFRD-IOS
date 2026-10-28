import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/agent_contact.dart';
import '../../../core/services/sheets_service.dart';
import '../../../core/state/app_state_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

enum _SettingsViewMode { general, auth, developer }

class _SettingsScreenState extends State<SettingsScreen> {
  _SettingsViewMode _mode = _SettingsViewMode.general;

  late TextEditingController _waDoneCtrl;
  late TextEditingController _waNotDoneCtrl;
  final TextEditingController _pinCtrl = TextEditingController();

  final TextEditingController _mainApiCtrl = TextEditingController();
  final TextEditingController _chatApiCtrl = TextEditingController();
  final TextEditingController _captionApiCtrl = TextEditingController();
  final TextEditingController _spreadsheetIdCtrl = TextEditingController();

  String? _authError;

  static const Set<String> _validPins = {
    '137946',
    'dhavid',
    'sfrd',
    'valentino',
  };

  @override
  void initState() {
    super.initState();
    final state = context.read<AppStateProvider>();
    _waDoneCtrl = TextEditingController(text: state.waTemplateDone);
    _waNotDoneCtrl = TextEditingController(text: state.waTemplateNotDone);
    _loadDeveloperUrls();
  }

  Future<void> _loadDeveloperUrls() async {
    final sheets = SheetsService();
    _mainApiCtrl.text = await sheets.getBaseUrl();
    _chatApiCtrl.text = await sheets.getChatUrl();
    _captionApiCtrl.text = await sheets.getCaptionUrl();
    _spreadsheetIdCtrl.text = await sheets.getSpreadsheetId();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _waDoneCtrl.dispose();
    _waNotDoneCtrl.dispose();
    _pinCtrl.dispose();
    _mainApiCtrl.dispose();
    _chatApiCtrl.dispose();
    _captionApiCtrl.dispose();
    _spreadsheetIdCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateProvider>();
    final palette = AppColors.paletteFor(state.selectedThemeStyle);

    return Scaffold(
      backgroundColor: palette.backgroundColor,
      appBar: AppBar(
        backgroundColor: palette.surfaceColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () {
            if (_mode != _SettingsViewMode.general) {
              setState(() => _mode = _SettingsViewMode.general);
            } else {
              state.openDrawerPage(null);
            }
          },
        ),
        title: Text(
          switch (_mode) {
            _SettingsViewMode.general => 'Pengaturan Aplikasi & Tema',
            _SettingsViewMode.auth => 'Otentikasi Developer',
            _SettingsViewMode.developer => 'Developer & API Settings',
          },
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
      ),
      body: switch (_mode) {
        _SettingsViewMode.general => _buildGeneralView(state, palette),
        _SettingsViewMode.auth => _buildAuthView(palette),
        _SettingsViewMode.developer => _buildDeveloperView(state, palette),
      },
    );
  }

  Widget _buildGeneralView(AppStateProvider state, ThemePalette palette) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 1. UI Layout & Dark Mode Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: palette.surfaceColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: palette.borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tampilan & Tema Aplikasi',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('Modern Pro ✨'),
                      selected: state.uiLayoutMode == 'MODERN_PRO',
                      selectedColor: palette.accentColor.withValues(alpha: 0.25),
                      onSelected: (_) => state.setUiLayoutMode('MODERN_PRO'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('Desain Klasik'),
                      selected: state.uiLayoutMode == 'CLASSIC',
                      selectedColor: palette.accentColor.withValues(alpha: 0.25),
                      onSelected: (_) => state.setUiLayoutMode('CLASSIC'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Dark Mode (Mode Gelap Premium)',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: const Text(
                  'Gunakan palet glassmorphic gelap seperti versi Android v8.9.15',
                  style: TextStyle(
                    color: AppColors.darkTextSecondary,
                    fontSize: 11.5,
                  ),
                ),
                value: state.isDarkTheme,
                activeColor: palette.accentColor,
                onChanged: (v) => state.setDarkTheme(v),
              ),
              const Divider(height: 20),
              const Text(
                'Pilih Gaya Tema (5 Preset):',
                style: TextStyle(
                  color: AppColors.darkTextSecondary,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              ...AppThemeStyle.values.map((style) {
                final p = AppColors.paletteFor(style);
                final isSelected = state.selectedThemeStyle == style;
                return GestureDetector(
                  onTap: () => state.setThemeStyle(style),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 11,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? p.accentColor.withValues(alpha: 0.16)
                          : p.elevatedSurfaceColor.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected ? p.accentColor : p.borderColor,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [p.accentColor, p.secondaryAccentColor],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                style.displayName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13.5,
                                ),
                              ),
                              Text(
                                style.subtitle,
                                style: const TextStyle(
                                  color: AppColors.darkTextSecondary,
                                  fontSize: 11.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          Icon(
                            Icons.check_circle_rounded,
                            color: p.accentColor,
                            size: 20,
                          ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // 2. Custom WhatsApp Templates Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: palette.surfaceColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: palette.borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Template Pesan Follow Up WhatsApp',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Placeholder: {greeting}, {honorific_name}, {me_name}, {id_listing}, {lokasi}, {tanggal}, {jam}, {staff}, {type}, {status}, {link}',
                style: TextStyle(
                  color: AppColors.darkTextSecondary,
                  fontSize: 11.5,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _waDoneCtrl,
                maxLines: 6,
                decoration: const InputDecoration(
                  labelText: 'Template Status DONE (Selesai)',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _waNotDoneCtrl,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Template Status BELUM DONE (Foto Ulang)',
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.restore_rounded, size: 16),
                      label: const Text('Reset Default'),
                      onPressed: () async {
                        await state.resetWaTemplates();
                        setState(() {
                          _waDoneCtrl.text = state.waTemplateDone;
                          _waNotDoneCtrl.text = state.waTemplateNotDone;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: palette.accentColor,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.save_rounded, size: 16),
                      label: const Text('Simpan Template'),
                      onPressed: () async {
                        await state.saveWaTemplates(
                          formatDone: _waDoneCtrl.text,
                          formatNotDone: _waNotDoneCtrl.text,
                        );
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content:
                                  Text('Template WhatsApp berhasil disimpan!'),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // 3. Developer Access Button
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: palette.surfaceColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: palette.borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.developer_mode_rounded,
                    color: AppColors.brandYellow,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Konfigurasi API Sheets & Kontak Agent',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          'Kelola URL Google Apps Script, Spreadsheet ID, dan 41 Nomor WA Agent',
                          style: TextStyle(
                            color: AppColors.darkTextSecondary,
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandYellow,
                  foregroundColor: Colors.black,
                ),
                icon: const Icon(Icons.lock_open_rounded, size: 17),
                label: const Text('Buka Developer & API Settings'),
                onPressed: () {
                  setState(() {
                    _authError = null;
                    _pinCtrl.clear();
                    _mode = _SettingsViewMode.auth;
                  });
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAuthView(ThemePalette palette) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: palette.surfaceColor,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: palette.borderColor),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.security_rounded,
                color: AppColors.brandYellow,
                size: 46,
              ),
              const SizedBox(height: 12),
              const Text(
                'Akses Developer Terkunci',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Masukkan PIN atau kata sandi developer untuk mengubah konfigurasi API Google Sheets & Database Kontak Agent.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.darkTextSecondary,
                  fontSize: 12.5,
                ),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: _pinCtrl,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'PIN / Password Developer',
                  errorText: _authError,
                  prefixIcon: const Icon(Icons.key_rounded),
                ),
                onSubmitted: (_) => _verifyPin(),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: palette.accentColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _verifyPin,
                child: const Text('Buka Pengaturan Developer'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _verifyPin() {
    final input = _pinCtrl.text.trim().toLowerCase();
    if (_validPins.contains(input)) {
      setState(() {
        _authError = null;
        _mode = _SettingsViewMode.developer;
      });
    } else {
      setState(() {
        _authError = 'PIN / Password tidak sesuai!';
      });
    }
  }

  Widget _buildDeveloperView(AppStateProvider state, ThemePalette palette) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 1. Manage 41 Agents Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: palette.surfaceColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: palette.borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.contacts_rounded,
                    color: AppColors.brandYellow,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Database Kontak Agent (${state.customAgents.length} Terdaftar)',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 14.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: palette.accentColor,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.manage_accounts_rounded, size: 18),
                label: const Text('Kelola Daftar Agent Marketing'),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => const _ManageAgentsDialog(),
                  );
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // 2. API Endpoints Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: palette.surfaceColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: palette.borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Konfigurasi Endpoint Google Apps Script',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _mainApiCtrl,
                decoration: const InputDecoration(
                  labelText: 'Main Apps Script URL (Jadwal, Meeting, Absensi)',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _chatApiCtrl,
                decoration: const InputDecoration(
                  labelText: 'Chat Apps Script URL',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _captionApiCtrl,
                decoration: const InputDecoration(
                  labelText: 'Caption Cloud Apps Script URL',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _spreadsheetIdCtrl,
                decoration: const InputDecoration(
                  labelText: 'Google Spreadsheet ID Utama',
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.restore_rounded, size: 16),
                      label: const Text('Reset Default v8.9.15'),
                      onPressed: () async {
                        final sheets = SheetsService();
                        await sheets.setBaseUrl(
                            SheetsService.defaultAppsScriptUrl);
                        await sheets
                            .setChatUrl(SheetsService.defaultAppsScriptUrl);
                        await sheets
                            .setCaptionUrl(SheetsService.defaultAppsScriptUrl);
                        await sheets.setSpreadsheetId(
                            SheetsService.defaultSpreadsheetId);
                        await _loadDeveloperUrls();
                        await state.refreshData();
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.statusDone,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.save_rounded, size: 16),
                      label: const Text('Simpan & Sinkronkan'),
                      onPressed: () async {
                        final sheets = SheetsService();
                        await sheets.setBaseUrl(_mainApiCtrl.text);
                        await sheets.setChatUrl(_chatApiCtrl.text);
                        await sheets.setCaptionUrl(_captionApiCtrl.text);
                        await sheets.setSpreadsheetId(_spreadsheetIdCtrl.text);
                        await state.refreshData();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content:
                                  Text('Konfigurasi API berhasil disimpan!'),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ManageAgentsDialog extends StatefulWidget {
  const _ManageAgentsDialog();

  @override
  State<_ManageAgentsDialog> createState() => _ManageAgentsDialogState();
}

class _ManageAgentsDialogState extends State<_ManageAgentsDialog> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateProvider>();
    final agents = state.customAgents.where((a) {
      if (_search.isEmpty) return true;
      final q = _search.toLowerCase();
      return a.displayName.toLowerCase().contains(q) ||
          a.key.toLowerCase().contains(q) ||
          a.phoneNumber.contains(q);
    }).toList();

    return Dialog(
      backgroundColor: AppColors.darkCardSurface,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 620),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Daftar Kontak Agent Marketing',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandYellow,
                    foregroundColor: Colors.black,
                    minimumSize: Size.zero,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                  ),
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text('Tambah'),
                  onPressed: () => _showEditAgentDialog(context, state, null),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              decoration: const InputDecoration(
                hintText: 'Cari nama atau nomor WA agent...',
                prefixIcon: Icon(Icons.search_rounded, size: 18),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _search = v),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.separated(
                itemCount: agents.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, idx) {
                  final a = agents[idx];
                  return ListTile(
                    dense: true,
                    title: Text(
                      a.displayName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: Text(
                      'Key: ${a.key} • WA: ${a.formattedPhoneDisplay}',
                      style: const TextStyle(
                        color: AppColors.darkTextSecondary,
                        fontSize: 11.5,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_rounded, size: 18),
                          onPressed: () =>
                              _showEditAgentDialog(context, state, a),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            color: AppColors.statusUrgent,
                            size: 18,
                          ),
                          onPressed: () => state.deleteAgentContact(a.key),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Tutup'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditAgentDialog(
    BuildContext context,
    AppStateProvider state,
    AgentContact? existing,
  ) async {
    final keyCtrl = TextEditingController(text: existing?.key ?? '');
    final nameCtrl = TextEditingController(text: existing?.displayName ?? '');
    final phoneCtrl = TextEditingController(text: existing?.phoneNumber ?? '');
    String honorific = existing?.honorific ?? 'Pak';

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setInner) => AlertDialog(
          backgroundColor: AppColors.darkCardSurface,
          title: Text(existing == null ? 'Tambah Agent Baru' : 'Edit Agent'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: keyCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Key Pencarian (huruf kecil, cth: utomo)',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nama Tampilan (cth: Pak Utomo)',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Nomor WhatsApp (cth: 081219759295)',
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: honorific,
                  dropdownColor: AppColors.darkElevatedSurface,
                  decoration: const InputDecoration(labelText: 'Sapaan'),
                  items: const [
                    DropdownMenuItem(value: 'Pak', child: Text('Pak')),
                    DropdownMenuItem(value: 'Bu', child: Text('Bu')),
                  ],
                  onChanged: (v) {
                    if (v != null) setInner(() => honorific = v);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                final k = keyCtrl.text.trim().toLowerCase();
                if (k.isEmpty) return;
                await state.upsertAgentContact(
                  AgentContact(
                    key: k,
                    displayName: nameCtrl.text.trim().isNotEmpty
                        ? nameCtrl.text.trim()
                        : '$honorific ${k[0].toUpperCase()}${k.substring(1)}',
                    phoneNumber: phoneCtrl.text.trim(),
                    honorific: honorific,
                  ),
                );
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }
}
