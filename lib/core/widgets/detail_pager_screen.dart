import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../models/agent_contact.dart';
import '../services/rwc_scraper_service.dart';
import '../state/app_state_provider.dart';
import '../utils/whatsapp_formatter.dart';
import '../../features/media/models/schedule.dart';
import '../../features/marketing/screens/instagram_mockup_screen.dart';

class DetailPagerScreen extends StatefulWidget {
  final Schedule schedule;
  final int initialPage;

  const DetailPagerScreen({
    super.key,
    required this.schedule,
    this.initialPage = 1,
  });

  @override
  State<DetailPagerScreen> createState() => _DetailPagerScreenState();
}

class _DetailPagerScreenState extends State<DetailPagerScreen> {
  late PageController _pageController;
  late int _currentPage;

  // Page 0: Edit Controllers
  late TextEditingController _idCtrl;
  late TextEditingController _meCtrl;
  late TextEditingController _lokasiCtrl;
  late TextEditingController _tanggalCtrl;
  late TextEditingController _jamCtrl;
  late TextEditingController _manualStatusCtrl;
  late Set<String> _selectedStaff;
  late String _selectedType;
  late bool _isSetDone;
  bool _isSaving = false;

  // Page 2: Follow Up Controllers
  late List<String> _coListingAgents;
  String? _selectedAgentName;
  late TextEditingController _phoneCtrl;
  late TextEditingController _messageCtrl;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage.clamp(0, 2);
    _pageController = PageController(initialPage: _currentPage);
    _initEditFields(widget.schedule);
    _initFollowUpFields(widget.schedule);
  }

  void _initEditFields(Schedule s) {
    _idCtrl = TextEditingController(text: s.idListing);
    _meCtrl = TextEditingController(text: s.namaMe);
    _lokasiCtrl = TextEditingController(text: s.lokasi);
    _tanggalCtrl = TextEditingController(text: s.tanggal);
    _jamCtrl = TextEditingController(text: s.jam);

    final staffParts = s.staff
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toSet();
    _selectedStaff = staffParts.isNotEmpty ? staffParts : {'David'};

    const knownTypes = [
      'Foto',
      'Video',
      'Drone',
      'Foto & Video',
      'Foto, Video & Drone',
      'Foto Ulang',
    ];
    _selectedType = knownTypes.contains(s.type) ? s.type : 'Foto';
    _isSetDone = s.isDone;
    _manualStatusCtrl = TextEditingController(
      text: s.isDone ? 'On Progress' : s.status,
    );
  }

  void _initFollowUpFields(Schedule s) {
    final state = context.read<AppStateProvider>();
    _coListingAgents = parseMultipleAgentNames(s.namaMe);
    _selectedAgentName =
        _coListingAgents.isNotEmpty ? _coListingAgents.first : s.namaMe;

    final contact = findAgentContact(
      _selectedAgentName ?? '',
      customAgents: state.customAgents,
    );
    _phoneCtrl = TextEditingController(text: contact?.phoneNumber ?? '');
    _messageCtrl = TextEditingController(
      text: WhatsAppFormatter.generateScheduleFollowUpMessage(
        s,
        targetMeOverride: _selectedAgentName,
        customTemplateDone: state.waTemplateDone,
        customTemplateNotDone: state.waTemplateNotDone,
      ),
    );
  }

  void _onSelectCoAgent(String name, AppStateProvider state) {
    final contact = findAgentContact(name, customAgents: state.customAgents);
    setState(() {
      _selectedAgentName = name;
      _phoneCtrl.text = contact?.phoneNumber ?? '';
      _messageCtrl.text = WhatsAppFormatter.generateScheduleFollowUpMessage(
        widget.schedule,
        targetMeOverride: name,
        customTemplateDone: state.waTemplateDone,
        customTemplateNotDone: state.waTemplateNotDone,
      );
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _idCtrl.dispose();
    _meCtrl.dispose();
    _lokasiCtrl.dispose();
    _tanggalCtrl.dispose();
    _jamCtrl.dispose();
    _manualStatusCtrl.dispose();
    _phoneCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateProvider>();
    final palette = AppColors.paletteFor(state.selectedThemeStyle);
    final s = widget.schedule;

    return Scaffold(
      backgroundColor: palette.backgroundColor,
      appBar: AppBar(
        backgroundColor: palette.surfaceColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => state.closeScheduleDetail(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Listing ${s.cleanId.isNotEmpty ? "#${s.cleanId}" : s.namaMe}',
              style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800),
            ),
            Text(
              '${s.tanggal} • ${s.formattedTime12Hour}',
              style: const TextStyle(
                fontSize: 11.5,
                color: AppColors.darkTextSecondary,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: AppColors.statusUrgent,
            ),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: palette.elevatedSurfaceColor,
                  title: const Text('Hapus Jadwal?'),
                  content: Text(
                    'Hapus jadwal #${s.cleanId} (${s.namaMe}) dari Google Sheets?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Batal'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.statusUrgent,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Hapus'),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                await state.deleteSchedule(s);
              }
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: palette.elevatedSurfaceColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: palette.borderColor),
            ),
            child: Row(
              children: [
                _buildTabPill(0, Icons.edit_note_rounded, 'Edit Jadwal', palette),
                _buildTabPill(
                    1, Icons.phone_iphone_rounded, 'Detail Home', palette),
                _buildTabPill(2, Icons.chat_rounded, 'Follow Up WA', palette),
              ],
            ),
          ),
        ),
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (idx) => setState(() => _currentPage = idx),
        children: [
          _buildEditPage(state, palette),
          InstagramPostMockupScreen(
            idListing: s.idListing,
            namaMe: s.namaMe,
            lokasi: s.lokasi,
            isEdited: true,
            embedded: true,
          ),
          _buildFollowUpPage(state, palette),
        ],
      ),
    );
  }

  Widget _buildTabPill(
    int index,
    IconData icon,
    String label,
    ThemePalette palette,
  ) {
    final selected = _currentPage == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected ? palette.accentColor : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 15,
                color: selected ? Colors.white : AppColors.darkTextSecondary,
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : AppColors.darkTextSecondary,
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEditPage(AppStateProvider state, ThemePalette palette) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
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
                  Icon(Icons.auto_awesome_rounded,
                      color: palette.secondaryAccentColor, size: 18),
                  const SizedBox(width: 8),
                  const Text(
                    'Edit Data Jadwal Foto',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _idCtrl,
                decoration: InputDecoration(
                  labelText: 'ID Listing',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.sync_rounded),
                    tooltip: 'Tarik Autofill Web',
                    onPressed: () async {
                      final detail = await state.fetchListingDetails(
                        _idCtrl.text,
                        force: true,
                      );
                      if (detail != null && mounted) {
                        final webMe = resolveWebAutofillValue(
                            _meCtrl.text, detail.agentName);
                        final webLoc = resolveWebAutofillValue(
                            _lokasiCtrl.text, detail.lokasi);
                        setState(() {
                          if (webMe != null) _meCtrl.text = webMe;
                          if (webLoc != null) _lokasiCtrl.text = webLoc;
                        });
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _meCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nama ME (Marketing Executive)',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _lokasiCtrl,
                decoration: const InputDecoration(
                  labelText: 'Lokasi Properti',
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _tanggalCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Tanggal (cth: 15 Juni 2026)',
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _jamCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Jam (cth: 10:00)',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Text(
                'Staff Bertugas:',
                style: TextStyle(
                  color: AppColors.darkTextSecondary,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                children: ['David', 'Alan'].map((staffName) {
                  final selected = _selectedStaff.contains(staffName);
                  return FilterChip(
                    label: Text(staffName),
                    selected: selected,
                    onSelected: (val) {
                      setState(() {
                        if (val) {
                          _selectedStaff.add(staffName);
                        } else if (_selectedStaff.length > 1) {
                          _selectedStaff.remove(staffName);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                value: _selectedType,
                dropdownColor: palette.elevatedSurfaceColor,
                decoration: const InputDecoration(labelText: 'Tipe Kegiatan'),
                items: const [
                  'Foto',
                  'Video',
                  'Drone',
                  'Foto & Video',
                  'Foto, Video & Drone',
                  'Foto Ulang',
                ]
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _selectedType = v);
                },
              ),
              const SizedBox(height: 14),
              const Text(
                'Status Kegiatan:',
                style: TextStyle(
                  color: AppColors.darkTextSecondary,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('SET DONE ✅'),
                      selected: _isSetDone,
                      selectedColor:
                          AppColors.statusDone.withValues(alpha: 0.25),
                      onSelected: (_) => setState(() => _isSetDone = true),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('Ketik Manual ✍️'),
                      selected: !_isSetDone,
                      selectedColor:
                          AppColors.statusPending.withValues(alpha: 0.25),
                      onSelected: (_) => setState(() => _isSetDone = false),
                    ),
                  ),
                ],
              ),
              if (!_isSetDone) ...[
                const SizedBox(height: 10),
                TextField(
                  controller: _manualStatusCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Status Manual (On Progress / Pending / Cancel)',
                  ),
                ),
              ],
              const SizedBox(height: 20),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: palette.accentColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: _isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save_rounded),
                label: Text(_isSaving ? 'Menyimpan...' : 'Simpan Perubahan'),
                onPressed: _isSaving
                    ? null
                    : () async {
                        setState(() => _isSaving = true);
                        final updated = widget.schedule.copyWith(
                          idListing: _idCtrl.text.trim(),
                          namaMe: _meCtrl.text.trim(),
                          lokasi: _lokasiCtrl.text.trim(),
                          tanggal: _tanggalCtrl.text.trim(),
                          jam: _jamCtrl.text.trim(),
                          staff: _selectedStaff.join(', '),
                          type: _selectedType,
                          status: _isSetDone
                              ? 'Done'
                              : (_manualStatusCtrl.text.trim().isNotEmpty
                                  ? _manualStatusCtrl.text.trim()
                                  : 'On Progress'),
                        );
                        final ok = await state.updateSchedule(updated);
                        if (mounted) {
                          setState(() => _isSaving = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                ok
                                    ? 'Jadwal berhasil diperbarui!'
                                    : 'Gagal memperbarui jadwal.',
                              ),
                            ),
                          );
                        }
                      },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFollowUpPage(AppStateProvider state, ThemePalette palette) {
    final s = widget.schedule;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
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
                    Icons.support_agent_rounded,
                    color: AppColors.statusDone,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      s.isDone
                          ? 'Follow Up Selesai (Done)'
                          : 'Follow Up Jadwal Foto Ulang / Belum Selesai',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 14.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (_coListingAgents.length > 1) ...[
                const Text(
                  'Pilih Agent Co-Listing Tujuan:',
                  style: TextStyle(
                    color: AppColors.darkTextSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                ..._coListingAgents.map((agentName) {
                  final contact = findAgentContact(
                    agentName,
                    customAgents: state.customAgents,
                  );
                  return RadioListTile<String>(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    value: agentName,
                    groupValue: _selectedAgentName,
                    activeColor: palette.accentColor,
                    title: Text(
                      contact?.displayName ?? agentName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    subtitle: Text(
                      contact?.formattedPhoneDisplay ?? 'Nomor belum terdaftar',
                      style: const TextStyle(
                        color: AppColors.darkTextSecondary,
                        fontSize: 11.5,
                      ),
                    ),
                    onChanged: (val) {
                      if (val != null) _onSelectCoAgent(val, state);
                    },
                  );
                }),
                const Divider(height: 18),
              ],
              TextField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Nomor WhatsApp Agent',
                  prefixIcon: Icon(Icons.phone_rounded, size: 18),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _messageCtrl,
                maxLines: 10,
                decoration: const InputDecoration(
                  labelText: 'Pesan Follow Up WhatsApp',
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                      icon: const Icon(Icons.send_rounded, size: 17),
                      label: const Text('Kirim WhatsApp'),
                      onPressed: () {
                        WhatsAppFormatter.openWhatsApp(
                          phoneNumber: _phoneCtrl.text,
                          message: _messageCtrl.text,
                          preferBusiness: false,
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF128C7E),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                      icon: const Icon(Icons.business_center_rounded, size: 17),
                      label: const Text('WA Business'),
                      onPressed: () {
                        WhatsAppFormatter.openWhatsApp(
                          phoneNumber: _phoneCtrl.text,
                          message: _messageCtrl.text,
                          preferBusiness: true,
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                icon: const Icon(Icons.copy_rounded, size: 16),
                label: const Text('Salin Teks Follow Up'),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: _messageCtrl.text));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Pesan disalin ke clipboard!'),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
