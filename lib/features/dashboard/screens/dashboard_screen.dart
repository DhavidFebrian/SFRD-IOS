import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/sheets_service.dart';
import '../../weekly_meeting/screens/weekly_meeting_screen.dart';
import '../../attendance/screens/attendance_screen.dart';
import '../../marketing/screens/instagram_mockup_screen.dart';
import '../../marketing/screens/wa_blast_screen.dart';
import '../../tasks/screens/task_dashboard_screen.dart';
import '../../settings/screens/settings_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final SheetsService _sheetsService = SheetsService();
  bool _isLoading = false;
  int _totalCount = 142;
  int _activeCount = 89;
  int _doneCount = 48;
  int _fotoUlangCount = 5;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    try {
      final listings = await _sheetsService.fetchWeeklyMeetingListings();
      if (listings.isNotEmpty) {
        int total = listings.length;
        int done = 0;
        int fotoUlang = 0;
        int active = 0;

        for (var item in listings) {
          final cat = item.catatan.toLowerCase();
          final ket = item.keterangan.toLowerCase();
          if (cat.contains('foto ulang') || ket.contains('foto ulang')) {
            fotoUlang++;
          } else if (item.status.toLowerCase() == 'disetujui' || item.postingIg == 'true') {
            done++;
          } else {
            active++;
          }
        }

        setState(() {
          _totalCount = total;
          _activeCount = active;
          _doneCount = done;
          _fotoUlangCount = fotoUlang;
        });
      }
    } catch (_) {
      // Keep existing default stats
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.asset(
                'assets/icons/app_icon.png',
                width: 28,
                height: 28,
                errorBuilder: (_, __, ___) => const Icon(Icons.movie_creation_rounded, color: AppColors.primary, size: 26),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'RWC - Media Production',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: -0.3),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: _isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(CupertinoIcons.arrow_clockwise, size: 20),
            tooltip: 'Sync Data',
            onPressed: _loadDashboardData,
          ),
          IconButton(
            icon: const Icon(CupertinoIcons.gear_alt_fill),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Banner Welcome
              _buildWelcomeCard(context),
              const SizedBox(height: 24),

              // Quick Stats Grid
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Statistik Media & Listing',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'v8.8.11',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primaryLight),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildStatsGrid(),
              const SizedBox(height: 24),

              // Feature Menu
              const Text(
                'Modul Utama',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _buildFeatureGrid(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryDark, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Selamat Datang di RWC,',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Media Production Hub',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(CupertinoIcons.sparkles, color: Colors.white, size: 24),
              )
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const WeeklyMeetingScreen()),
                  );
                },
                icon: const Icon(CupertinoIcons.plus_circle_fill, size: 18),
                label: const Text('Input Listing Meeting'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.black87,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AttendanceScreen()),
                  );
                },
                icon: const Icon(CupertinoIcons.camera_viewfinder, size: 18, color: Colors.white),
                label: const Text('Presensi', style: TextStyle(color: Colors.white)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return Column(
      children: [
        Row(
          children: [
            _buildStatCard('Listing Aktif', '$_activeCount', CupertinoIcons.house_alt, AppColors.primaryLight),
            const SizedBox(width: 12),
            _buildStatCard('Selesai (Done)', '$_doneCount', CupertinoIcons.checkmark_seal_fill, AppColors.success),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildStatCard('Foto Ulang', '$_fotoUlangCount', CupertinoIcons.camera_rotate, AppColors.error),
            const SizedBox(width: 12),
            _buildStatCard('Total Listing', '$_totalCount', CupertinoIcons.square_grid_2x2, AppColors.warning),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    title,
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureGrid(BuildContext context) {
    final features = [
      {
        'title': 'Weekly Meeting',
        'subtitle': 'Manajemen listing & review',
        'icon': CupertinoIcons.doc_text_fill,
        'color': AppColors.primary,
        'screen': const WeeklyMeetingScreen(),
      },
      {
        'title': 'Presensi Wajah',
        'subtitle': 'Face Recognition & Absensi',
        'icon': CupertinoIcons.person_crop_circle_badge_checkmark,
        'color': AppColors.success,
        'screen': const AttendanceScreen(),
      },
      {
        'title': 'Instagram Mockup',
        'subtitle': 'Generator template & poster',
        'icon': CupertinoIcons.camera_fill,
        'color': const Color(0xFFE1306C),
        'screen': const InstagramMockupScreen(),
      },
      {
        'title': 'WhatsApp Blast',
        'subtitle': 'Broadcast promosi instan',
        'icon': CupertinoIcons.chat_bubble_2_fill,
        'color': const Color(0xFF25D366),
        'screen': const WaBlastScreen(),
      },
      {
        'title': 'Task Dashboard',
        'subtitle': 'Jadwal & tugas marketing',
        'icon': CupertinoIcons.check_mark_circled_solid,
        'color': AppColors.warning,
        'screen': const TaskDashboardScreen(),
      },
      {
        'title': 'Pengaturan',
        'subtitle': 'Profil & konfigurasi app',
        'icon': CupertinoIcons.settings_solid,
        'color': AppColors.textSecondaryLight,
        'screen': const SettingsScreen(),
      },
    ];

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: features.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.25,
      ),
      itemBuilder: (context, index) {
        final f = features[index];
        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => f['screen'] as Widget),
            ).then((_) => _loadDashboardData());
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: (f['color'] as Color).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(f['icon'] as IconData, color: f['color'] as Color, size: 24),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      f['title'] as String,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      f['subtitle'] as String,
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
