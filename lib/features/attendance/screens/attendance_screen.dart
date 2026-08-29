import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../../core/constants/app_colors.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({Key? key}) : super(key: key);

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  bool _isScanning = false;
  bool _isVerified = false;
  String _statusMessage = "Posisikan wajah Anda di dalam lingkaran panduan";

  void _startScan() {
    setState(() {
      _isScanning = true;
      _isVerified = false;
      _statusMessage = "Mendeteksi kontur wajah & landmark...";
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isScanning = false;
          _isVerified = true;
          _statusMessage = "Wajah terverifikasi: David Febrian (ME-01)\nPresensi Berhasil Direkam!";
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Presensi Wajah', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Text(
              'Weekly Meeting Attendance',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 30),

            // Face Camera Frame Simulator / Camera Preview Viewport
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 260,
                    height: 260,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withOpacity(0.05),
                      border: Border.all(
                        color: _isVerified
                            ? AppColors.success
                            : (_isScanning ? AppColors.primaryLight : AppColors.borderDark),
                        width: 4,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        _isVerified
                            ? CupertinoIcons.checkmark_circle_fill
                            : CupertinoIcons.person_crop_circle_fill,
                        size: 140,
                        color: _isVerified
                            ? AppColors.success
                            : (_isScanning ? AppColors.primaryLight : Colors.grey.shade400),
                      ),
                    ),
                  ),
                  if (_isScanning)
                    const SizedBox(
                      width: 280,
                      height: 280,
                      child: CircularProgressIndicator(
                        strokeWidth: 4,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Status message
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: _isVerified ? AppColors.success.withOpacity(0.1) : AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isVerified ? AppColors.success : AppColors.borderLight,
                ),
              ),
              child: Text(
                _statusMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _isVerified ? AppColors.success : AppColors.textPrimaryLight,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
            const Spacer(),

            // Actions
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isScanning ? null : _startScan,
                icon: const Icon(CupertinoIcons.camera_viewfinder),
                label: Text(
                  _isVerified ? 'Scan Ulang' : 'Mulai Pindai Wajah',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
