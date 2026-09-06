import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/whatsapp_formatter.dart';

class WaBlastScreen extends StatefulWidget {
  const WaBlastScreen({Key? key}) : super(key: key);

  @override
  State<WaBlastScreen> createState() => _WaBlastScreenState();
}

class _WaBlastScreenState extends State<WaBlastScreen> {
  final _phoneController = TextEditingController();
  final _clientNameController = TextEditingController();
  final _messageController = TextEditingController(
    text: "Halo Bapak/Ibu,\n\nBerikut rekomendasi listing properti terbaik dari RWC - Media Production minggu ini. Lokasi sangat strategis dan siap survei!",
  );

  @override
  void dispose() {
    _phoneController.dispose();
    _clientNameController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _sendBlast() {
    if (_messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pesan tidak boleh kosong')),
      );
      return;
    }

    WhatsAppFormatter.openWhatsApp(
      phoneNumber: _phoneController.text.trim(),
      message: _messageController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WhatsApp Blast', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF25D366).withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF25D366).withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(CupertinoIcons.chat_bubble_2_fill, color: Color(0xFF25D366), size: 28),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Kirim pesan broadcast promosi atau follow up klien langsung ke aplikasi WhatsApp.',
                      style: TextStyle(fontSize: 13, color: Colors.black87),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Nomor WhatsApp Klien',
                hintText: 'Contoh: 08123456789 (Opsional)',
                prefixIcon: Icon(CupertinoIcons.phone),
              ),
            ),
            const SizedBox(height: 14),

            TextField(
              controller: _clientNameController,
              decoration: const InputDecoration(
                labelText: 'Nama Klien',
                hintText: 'Contoh: Bpk. Hendra',
                prefixIcon: Icon(CupertinoIcons.person),
              ),
            ),
            const SizedBox(height: 14),

            TextField(
              controller: _messageController,
              maxLines: 6,
              decoration: const InputDecoration(
                labelText: 'Isi Pesan WhatsApp',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _sendBlast,
                icon: const Icon(CupertinoIcons.chat_bubble_2_fill, size: 20),
                label: const Text('Buka di WhatsApp', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
