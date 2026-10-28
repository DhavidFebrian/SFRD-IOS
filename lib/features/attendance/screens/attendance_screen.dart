import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/absensi_models.dart';
import '../../../core/models/agent_contact.dart';
import '../../../core/state/app_state_provider.dart';

class AttendanceScreen extends StatefulWidget {
  final bool embedded;

  const AttendanceScreen({
    super.key,
    this.embedded = false,
  });

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _statusFilter = 'Semua'; // 'Semua', 'Hadir', 'Belum Hadir'
  int _selectedDateIndex = 0;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _isAgentPresent(
    AbsensiMarketing agent,
    AbsensiDate? dateCol,
    int dateChipIndex,
  ) {
    if (dateCol == null) return false;
    final dynamic att = agent.attendance;
    final dynamic colObj = dateCol;
    int colIdx = 0;
    try {
      colIdx = (colObj.colIndex as int?) ?? 0;
    } catch (_) {
      try {
        colIdx = (colObj.col as int?) ?? 0;
      } catch (_) {}
    }

    if (att is Map) {
      if (att.containsKey(colIdx)) return att[colIdx] == true;
      if (att.containsKey(dateChipIndex)) return att[dateChipIndex] == true;
      return false;
    }
    if (att is List) {
      if (dateChipIndex >= 0 && dateChipIndex < att.length) {
        return att[dateChipIndex] == true;
      }
      if (colIdx >= 0 && colIdx < att.length) {
        return att[colIdx] == true;
      }
    }
    return false;
  }

  String _getInitials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'ME';
    if (parts.length == 1) {
      return parts.first.substring(0, parts.first.length.clamp(1, 2)).toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  Future<void> _promptPinAndOpenFaceScan(
    BuildContext context,
    AppStateProvider state,
    AbsensiDate? selectedDateCol,
    int selectedIdx,
  ) async {
    if (selectedDateCol == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih tanggal meeting terlebih dahulu.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    final pinController = TextEditingController();
    String? errorText;

    final authorized = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.cardDark,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: AppColors.borderDark),
              ),
              title: const Row(
                children: [
                  Icon(CupertinoIcons.lock_shield_fill, color: AppColors.accent, size: 22),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Otorisasi Face Scan',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Masukkan PIN Keamanan untuk membuka kamera Face Scan Absensi:',
                    style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 13),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: pinController,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    autofocus: true,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      letterSpacing: 8,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      counterText: '',
                      hintText: '••••',
                      hintStyle: const TextStyle(color: Colors.white24, letterSpacing: 8),
                      errorText: errorText,
                      filled: true,
                      fillColor: AppColors.surfaceDark,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.borderDark),
                      ),
                    ),
                    onSubmitted: (val) {
                      if (val.trim() == '2332') {
                        Navigator.of(ctx).pop(true);
                      } else {
                        setDialogState(() {
                          errorText = 'PIN salah! Gunakan PIN otorisasi.';
                        });
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('Batal', style: TextStyle(color: AppColors.textSecondaryDark)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    if (pinController.text.trim() == '2332') {
                      Navigator.of(ctx).pop(true);
                    } else {
                      setDialogState(() {
                        errorText = 'PIN salah! Gunakan PIN otorisasi.';
                      });
                    }
                  },
                  child: const Text('Buka Scanner', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );

    if (authorized == true && context.mounted) {
      await _showFaceScanModal(
        context,
        state: state,
        selectedDateCol: selectedDateCol,
        selectedIdx: selectedIdx,
      );
    }
  }

  Future<void> _showFaceScanModal(
    BuildContext context, {
    required AppStateProvider state,
    required AbsensiDate selectedDateCol,
    required int selectedIdx,
  }) async {
    File? capturedPhoto;
    final picker = ImagePicker();
    final selectedAgentRows = <int>{};
    String modalSearch = '';
    bool isSavingBatch = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final agents = state.absensiResponse.marketingList.where((a) {
              if (modalSearch.trim().isEmpty) return true;
              return a.name.toLowerCase().contains(modalSearch.toLowerCase());
            }).toList();

            return Container(
              height: MediaQuery.of(ctx).size.height * 0.86,
              decoration: const BoxDecoration(
                color: AppColors.surfaceDark,
                borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
                border: Border(top: BorderSide(color: AppColors.borderDark, width: 1.2)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 16, 10),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            CupertinoIcons.viewfinder,
                            color: AppColors.accent,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Face Scan Attendance',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Tanggal Meeting: ${selectedDateCol.label}',
                                style: const TextStyle(
                                  color: AppColors.textSecondaryDark,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          icon: const Icon(CupertinoIcons.xmark_circle_fill, color: Colors.white54),
                        ),
                      ],
                    ),
                  ),
                  const Divider(color: AppColors.borderDark, height: 1),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        // Camera Capture Box
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.cardDark,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: AppColors.borderDark),
                          ),
                          child: Column(
                            children: [
                              if (capturedPhoto != null)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: Image.file(
                                    capturedPhoto!,
                                    height: 180,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              else
                                Container(
                                  height: 130,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: AppColors.backgroundDark,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: AppColors.accent.withOpacity(0.35),
                                    ),
                                  ),
                                  child: const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        CupertinoIcons.camera_viewfinder,
                                        color: AppColors.accent,
                                        size: 42,
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        'Ambil Foto Wajah Marketing / Bukti Kehadiran',
                                        style: TextStyle(
                                          color: AppColors.textSecondaryDark,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppColors.accent,
                                        side: const BorderSide(color: AppColors.accent),
                                        padding: const EdgeInsets.symmetric(vertical: 11),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                      onPressed: () async {
                                        try {
                                          final xfile = await picker.pickImage(
                                            source: ImageSource.camera,
                                            preferredCameraDevice: CameraDevice.front,
                                            imageQuality: 80,
                                          );
                                          if (xfile != null) {
                                            setModalState(() {
                                              capturedPhoto = File(xfile.path);
                                            });
                                          }
                                        } catch (_) {}
                                      },
                                      icon: const Icon(CupertinoIcons.camera_fill, size: 17),
                                      label: const Text('Buka Kamera'),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.white70,
                                        side: const BorderSide(color: AppColors.borderDark),
                                        padding: const EdgeInsets.symmetric(vertical: 11),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                      onPressed: () async {
                                        try {
                                          final xfile = await picker.pickImage(
                                            source: ImageSource.gallery,
                                            imageQuality: 80,
                                          );
                                          if (xfile != null) {
                                            setModalState(() {
                                              capturedPhoto = File(xfile.path);
                                            });
                                          }
                                        } catch (_) {}
                                      },
                                      icon: const Icon(CupertinoIcons.photo, size: 17),
                                      label: const Text('Pilih Galeri'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Pilih Marketing untuk Check-In Cepat (Multi-Agent):',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          onChanged: (val) => setModalState(() => modalSearch = val),
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          decoration: InputDecoration(
                            hintText: 'Cari nama marketing...',
                            hintStyle: const TextStyle(color: AppColors.textSecondaryDark),
                            prefixIcon: const Icon(
                              CupertinoIcons.search,
                              color: AppColors.textSecondaryDark,
                              size: 18,
                            ),
                            filled: true,
                            fillColor: AppColors.cardDark,
                            contentPadding: const EdgeInsets.symmetric(vertical: 10),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppColors.borderDark),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...agents.map((agent) {
                          final alreadyPresent = _isAgentPresent(
                            agent,
                            selectedDateCol,
                            selectedIdx,
                          );
                          final isSelected = selectedAgentRows.contains(agent.row);
                          final avatarUrl = getAgentAvatarByName(agent.name);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.success.withOpacity(0.16)
                                  : AppColors.cardDark,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.success
                                    : (alreadyPresent
                                        ? AppColors.success.withOpacity(0.4)
                                        : AppColors.borderDark),
                              ),
                            ),
                            child: ListTile(
                              onTap: () {
                                setModalState(() {
                                  if (isSelected) {
                                    selectedAgentRows.remove(agent.row);
                                  } else {
                                    selectedAgentRows.add(agent.row);
                                  }
                                });
                              },
                              leading: CircleAvatar(
                                radius: 18,
                                backgroundColor: AppColors.primaryDark,
                                backgroundImage: avatarUrl.isNotEmpty
                                    ? CachedNetworkImageProvider(avatarUrl)
                                    : null,
                                child: avatarUrl.isEmpty
                                    ? Text(
                                        _getInitials(agent.name),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      )
                                    : null,
                              ),
                              title: Text(
                                agent.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13.5,
                                ),
                              ),
                              subtitle: Text(
                                alreadyPresent
                                    ? 'Sudah tercatat HADIR'
                                    : 'Belum hadir pada sesi ini',
                                style: TextStyle(
                                  color: alreadyPresent
                                      ? AppColors.success
                                      : AppColors.textSecondaryDark,
                                  fontSize: 11.5,
                                ),
                              ),
                              trailing: Checkbox(
                                value: isSelected || alreadyPresent,
                                activeColor: AppColors.success,
                                onChanged: (_) {
                                  setModalState(() {
                                    if (isSelected) {
                                      selectedAgentRows.remove(agent.row);
                                    } else {
                                      selectedAgentRows.add(agent.row);
                                    }
                                  });
                                },
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    decoration: const BoxDecoration(
                      color: AppColors.cardDark,
                      border: Border(top: BorderSide(color: AppColors.borderDark)),
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: isSavingBatch || selectedAgentRows.isEmpty
                            ? null
                            : () async {
                                setModalState(() => isSavingBatch = true);
                                for (final rowId in selectedAgentRows) {
                                  final target = state.absensiResponse.marketingList
                                      .where((m) => m.row == rowId)
                                      .firstOrNull;
                                  if (target != null) {
                                    final currentlyPresent = _isAgentPresent(
                                      target,
                                      selectedDateCol,
                                      selectedIdx,
                                    );
                                    if (!currentlyPresent) {
                                      await state.toggleAttendance(
                                        agent: target,
                                        dateCol: selectedDateCol,
                                      );
                                    }
                                  }
                                }
                                if (ctx.mounted) {
                                  Navigator.of(ctx).pop();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        '${selectedAgentRows.length} Marketing berhasil ditandai HADIR!',
                                      ),
                                      backgroundColor: AppColors.success,
                                    ),
                                  );
                                }
                              },
                        icon: isSavingBatch
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(CupertinoIcons.checkmark_seal_fill, size: 18),
                        label: Text(
                          isSavingBatch
                              ? 'Menyimpan Absensi...'
                              : 'Konfirmasi Hadir (${selectedAgentRows.length} Agent)',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateProvider>();
    final absensi = state.absensiResponse;
    final dates = absensi.dates;

    final effectiveDateIdx = dates.isEmpty
        ? 0
        : _selectedDateIndex.clamp(0, dates.length - 1);
    final selectedDateCol = dates.isNotEmpty ? dates[effectiveDateIdx] : null;

    final allAgents = absensi.marketingList;
    final totalAgents = allAgents.length;
    final hadirCount = allAgents
        .where((a) => _isAgentPresent(a, selectedDateCol, effectiveDateIdx))
        .length;
    final belumHadirCount = (totalAgents - hadirCount).clamp(0, totalAgents);

    final filteredAgents = allAgents.where((agent) {
      final isPresent = _isAgentPresent(agent, selectedDateCol, effectiveDateIdx);
      final matchesStatus = switch (_statusFilter) {
        'Hadir' => isPresent,
        'Belum Hadir' => !isPresent,
        _ => true,
      };
      final q = _searchQuery.trim().toLowerCase();
      final matchesSearch = q.isEmpty || agent.name.toLowerCase().contains(q);
      return matchesStatus && matchesSearch;
    }).toList();

    final content = Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary KPI Row
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: _KpiSummaryCard(
                      label: 'Total Agent',
                      count: totalAgents,
                      color: AppColors.primaryLight,
                      icon: CupertinoIcons.person_3_fill,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _KpiSummaryCard(
                      label: 'Hadir',
                      count: hadirCount,
                      color: AppColors.success,
                      icon: CupertinoIcons.checkmark_circle_fill,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _KpiSummaryCard(
                      label: 'Belum Hadir',
                      count: belumHadirCount,
                      color: AppColors.error,
                      icon: CupertinoIcons.xmark_circle_fill,
                    ),
                  ),
                ],
              ),
            ),

            // Horizontal Selector Chips for Available Meeting Date Columns
            if (dates.isNotEmpty)
              SizedBox(
                height: 44,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: dates.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final d = dates[index];
                    final isSelected = index == effectiveDateIdx;
                    return ChoiceChip(
                      label: Text(
                        d.label.isNotEmpty ? d.label : 'Sesi ${index + 1}',
                        style: TextStyle(
                          color: isSelected ? Colors.black : Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: AppColors.accent,
                      backgroundColor: AppColors.cardDark,
                      side: BorderSide(
                        color: isSelected ? AppColors.accent : AppColors.borderDark,
                      ),
                      onSelected: (_) {
                        setState(() => _selectedDateIndex = index);
                      },
                    );
                  },
                ),
              ),

            // Search Bar & Filter Chips ('Semua', 'Hadir', 'Belum Hadir')
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _searchQuery = v),
                    style: const TextStyle(color: Colors.white, fontSize: 13.5),
                    decoration: InputDecoration(
                      hintText: 'Cari nama marketing / agent...',
                      hintStyle: const TextStyle(
                        color: AppColors.textSecondaryDark,
                        fontSize: 13,
                      ),
                      prefixIcon: const Icon(
                        CupertinoIcons.search,
                        color: AppColors.textSecondaryDark,
                        size: 18,
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                              icon: const Icon(
                                CupertinoIcons.clear_circled_solid,
                                color: Colors.white54,
                                size: 18,
                              ),
                            )
                          : null,
                      filled: true,
                      fillColor: AppColors.cardDark,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.borderDark),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.borderDark),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: ['Semua', 'Hadir', 'Belum Hadir'].map((filter) {
                      final active = _statusFilter == filter;
                      final badgeColor = switch (filter) {
                        'Hadir' => AppColors.success,
                        'Belum Hadir' => AppColors.error,
                        _ => AppColors.primaryLight,
                      };
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          selected: active,
                          label: Text(
                            filter,
                            style: TextStyle(
                              color: active ? Colors.white : AppColors.textSecondaryDark,
                              fontWeight: active ? FontWeight.bold : FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                          selectedColor: badgeColor.withOpacity(0.28),
                          backgroundColor: AppColors.cardDark,
                          checkmarkColor: badgeColor,
                          side: BorderSide(
                            color: active ? badgeColor : AppColors.borderDark,
                          ),
                          onSelected: (_) => setState(() => _statusFilter = filter),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

            // 2-Column Grid of Agent Attendance Cards
            Expanded(
              child: filteredAgents.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            CupertinoIcons.person_crop_circle_badge_exclam,
                            color: Colors.white.withOpacity(0.25),
                            size: 52,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            allAgents.isEmpty
                                ? 'Data absensi belum tersedia untuk bulan ${state.selectedMonth}'
                                : 'Tidak ada agent yang sesuai filter',
                            style: const TextStyle(
                              color: AppColors.textSecondaryDark,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 110),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 1.48,
                      ),
                      itemCount: filteredAgents.length,
                      itemBuilder: (context, index) {
                        final agent = filteredAgents[index];
                        final isPresent = _isAgentPresent(
                          agent,
                          selectedDateCol,
                          effectiveDateIdx,
                        );
                        final contact = findAgentContact(
                          agent.name,
                          state.customAgents,
                        );
                        final avatarUrl = contact?.avatarUrl.isNotEmpty == true
                            ? contact!.avatarUrl
                            : getAgentAvatarByName(agent.name);

                        return InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: selectedDateCol == null
                              ? null
                              : () {
                                  state.toggleAttendance(
                                    agent: agent,
                                    dateCol: selectedDateCol,
                                  );
                                },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isPresent
                                  ? AppColors.success.withOpacity(0.12)
                                  : AppColors.cardDark,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isPresent
                                    ? AppColors.success.withOpacity(0.75)
                                    : AppColors.borderDark,
                                width: isPresent ? 1.4 : 1.0,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundColor: isPresent
                                          ? AppColors.success.withOpacity(0.25)
                                          : AppColors.surfaceDark,
                                      backgroundImage: avatarUrl.isNotEmpty
                                          ? CachedNetworkImageProvider(avatarUrl)
                                          : null,
                                      child: avatarUrl.isEmpty
                                          ? Text(
                                              _getInitials(agent.name),
                                              style: TextStyle(
                                                color: isPresent
                                                    ? AppColors.success
                                                    : Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            )
                                          : null,
                                    ),
                                    const Spacer(),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isPresent
                                            ? AppColors.success
                                            : AppColors.error.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: isPresent
                                              ? AppColors.success
                                              : AppColors.error.withOpacity(0.6),
                                        ),
                                      ),
                                      child: Text(
                                        isPresent ? 'HADIR' : 'ABSEN',
                                        style: TextStyle(
                                          color: isPresent
                                              ? Colors.white
                                              : AppColors.error,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 10,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      agent.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13.5,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Total Bulan Ini: ${agent.totalHadirBulan}x Hadir',
                                      style: const TextStyle(
                                        color: AppColors.textSecondaryDark,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),

        // Floating Bottom "Face Scan" Button gated by PIN "2332"
        Positioned(
          right: 16,
          bottom: 20,
          child: FloatingActionButton.extended(
            heroTag: 'absensi_face_scan_fab',
            backgroundColor: AppColors.accent,
            foregroundColor: Colors.black,
            onPressed: () => _promptPinAndOpenFaceScan(
              context,
              state,
              selectedDateCol,
              effectiveDateIdx,
            ),
            icon: const Icon(CupertinoIcons.viewfinder, size: 20),
            label: const Text(
              'Face Scan',
              style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.3),
            ),
          ),
        ),
      ],
    );

    if (widget.embedded) {
      return content;
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceDark,
        title: Text(
          'Absensi Meeting — ${state.selectedMonth}',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      body: content,
    );
  }
}

class _KpiSummaryCard extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final IconData icon;

  const _KpiSummaryCard({
    required this.label,
    required this.count,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color.withOpacity(0.16),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count',
                  style: TextStyle(
                    color: color,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondaryDark,
                    fontSize: 10.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
