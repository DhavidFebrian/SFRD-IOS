import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../core/constants/app_colors.dart';

class InstagramMockupScreen extends StatefulWidget {
  const InstagramMockupScreen({Key? key}) : super(key: key);

  @override
  State<InstagramMockupScreen> createState() => _InstagramMockupScreenState();
}

class _InstagramMockupScreenState extends State<InstagramMockupScreen> {
  String _aspectRatio = '1:1';
  String _selectedTemplate = 'Modern Luxury';
  final _headlineController = TextEditingController(text: 'RUMAH MEWAH ARAYA');
  final _priceController = TextEditingController(text: 'Rp 2,85 M');
  final _specController = TextEditingController(text: 'LT 180m² | LB 220m² | 4 KT | 3 KM');

  @override
  void dispose() {
    _headlineController.dispose();
    _priceController.dispose();
    _specController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Instagram Mockup', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.arrow_down_to_line_alt),
            tooltip: 'Download Desain',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Gambar poster mockup disimpan ke Galeri Foto!'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Preview Poster Instagram Frame
            _buildPosterPreview(),
            const SizedBox(height: 20),

            // Kontrol Aspek Rasio
            const Text('Format Rasio:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 8),
            Row(
              children: ['1:1 (Square)', '4:5 (Portrait)', '9:16 (Story)'].map((ratio) {
                final isSelected = _aspectRatio == ratio.split(' ')[0];
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(ratio),
                    selected: isSelected,
                    selectedColor: AppColors.primaryLight.withOpacity(0.2),
                    onSelected: (_) {
                      setState(() => _aspectRatio = ratio.split(' ')[0]);
                    },
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Kontrol Teks
            TextField(
              controller: _headlineController,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Judul Utama Poster',
                prefixIcon: Icon(CupertinoIcons.text_badge_checkmark),
              ),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _priceController,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Highlight Harga',
                prefixIcon: Icon(CupertinoIcons.money_dollar),
              ),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _specController,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Spesifikasi Singkat',
                prefixIcon: Icon(CupertinoIcons.info_circle),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPosterPreview() {
    double height = 320;
    if (_aspectRatio == '4:5') height = 380;
    if (_aspectRatio == '9:16') height = 440;

    return Center(
      child: Container(
        width: double.infinity,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Dummy image illustration
            Center(
              child: Icon(
                Icons.image_outlined,
                size: 80,
                color: Colors.white.withOpacity(0.15),
              ),
            ),
            // Header Tag
            Positioned(
              top: 16,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'HOT LISTING',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black),
                ),
              ),
            ),
            // Bottom Info Overlay
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                  gradient: LinearGradient(
                    colors: [Colors.transparent, Colors.black.withOpacity(0.85)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _headlineController.text,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _priceController.text,
                      style: const TextStyle(
                        color: AppColors.accent,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _specController.text,
                      style: const TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
